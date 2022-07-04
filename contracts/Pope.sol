// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./interfaces/IERC20Metadata.sol";
import "./libraries/Counters.sol";
import "./Constellation.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./libraries/Ownable.sol";
import "./PopeFeeDividend.sol";
import "./security/ReentrancyGuard.sol";

contract Pope is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string public baseURI;

    uint256 public max = 120;

    address private constellationAddress;

    IUniswapV2Router02 public immutable uniswapV2Router;

    address public GSSToken;
    address public PopeFeeDividendToken;
    address public USDTToken;

    uint256 public totalReward = 0;

    uint256 public constant ACC_TOKEN_PRECISION = 1e18;
    // Accumulated Tokens per share.
    uint256 public tokenPerShare = 0;
    // Last reward that token update action is executed.
    uint256 public lastReward = 0;
    // The total amount of user shares in each pool. After considering the share boosts.
    uint256 public totalBoostedShare = 0;

    /// @notice Info of each Pledge user.
    /// `amount` token amount the user has provided.
    /// `rewardDebt` Used to calculate the correct amount of rewards. See explanation below.
    /// `pending` Pending Rewards.
    /// `depositTime` Last pledge time
    ///
    /// We do some fancy math here. Basically, any point in time, the amount of Tokens
    /// entitled to a user but is pending to be distributed is:
    ///
    ///   pending reward = (user share * tokenPerShare) - user.rewardDebt
    ///
    ///   Whenever a user deposits or withdraws LP tokens. Here's what happens:
    ///   1. The `tokenPerShare` (and `lastRewardBlock`) gets updated.
    ///   2. User receives the pending reward sent to his/her address.
    ///   3. User's `amount` gets updated. `totalBoostedShare` gets updated.
    ///   4. User's `rewardDebt` gets updated.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pending;
        uint256 total;
        uint256 depositTime;
    }

    /// @notice Info of user.
    mapping(address => UserInfo) public userInfo;

    event Update(uint256 lastReward, uint256 tokenSupply, uint256 tokenPerShare);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event WithdrawPending(address indexed user, uint256 pending, uint256 time);

    constructor(address _USDTToken, address _uniswapV2Router, string memory newBaseURI) ERC721("Pope", "POPE") {
        USDTToken = _USDTToken;
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        baseURI = newBaseURI;
    }

    function mintPrice() public view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = USDTToken;
        path[1] = GSSToken;
        uint[] memory amounts = uniswapV2Router.getAmountsOut(500 * (10 ** IERC20Metadata(USDTToken).decimals()), path);
        return amounts[1];
    }

    function mint(address recipient, uint256[12] memory _ids) external returns (uint256){

        require(GSSToken != address(0), "GSSToken address cannot be empty");

        require(_tokenIds.current() < max, "Exceeded the maximum number of mint");

        uint256 _price = mintPrice();

        IERC20Metadata(GSSToken).transferFrom(msg.sender, address(0), _price);

        bool verify = true;
        uint256[] memory idMods = new uint256[](12);
        for(uint256 i = 0; i < 12; i++) {
            uint256 id = _ids[i];
            uint256 idMod = id % 12;
            if(Constellation(constellationAddress).ownerOf(id) != msg.sender || idMods[idMod] > 0) {
                verify = false;
                break;
            }
            idMods[idMod] = 1;
        }
        require(verify, "Check if tokenId is valid");

        Constellation(constellationAddress).burnAll(_ids);

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);

        return newItemId;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 /*tokenId*/
    ) internal override {
        if(to != address(0)) {
            _deposit(to, 1);
        }
        if(from != address(0)) {
            _withdraw(from, 1);
            PopeFeeDividend(PopeFeeDividendToken).withdraw(from);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function userInfoAmount(address _user) public view returns (uint256) {
        return userInfo[_user].amount;
    }

    function setGSSToken(address _token) external onlyOwner {

        require(GSSToken == address(0), "Parameters can only be set once");

        GSSToken = _token;
    }

    function setConstellationAddress(address _token) external onlyOwner {

        require(constellationAddress == address(0), "Parameters can only be set once");

        constellationAddress = _token;
    }

    function setPopeFeeDividendToken(address _token) external onlyOwner {

        require(PopeFeeDividendToken == address(0), "Parameters can only be set once");

        PopeFeeDividendToken = _token;
    }

    function swapUSDT() external onlyOwner {

        uint256 amount = 555 * (10 ** IERC20Metadata(GSSToken).decimals());

        uint256 balanceG = IERC20Metadata(GSSToken).balanceOf(address(this));

        amount = balanceG >= amount ? amount : balanceG;

        require(amount > 0, "amount not");

        address[] memory path = new address[](2);
        path[0] = GSSToken;
        path[1] = USDTToken;

        uniswapV2Router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);

    }

    function mineETH() external onlyOwner nonReentrant {

        uint256 amount = IERC20Metadata(USDTToken).balanceOf(address(this));

        require(amount > 0, "amount not");

        address[] memory path = new address[](2);
        path[0] = USDTToken;
        path[1] = uniswapV2Router.WETH();

        uint256 balance = IERC20Metadata(uniswapV2Router.WETH()).balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
        totalReward += IERC20Metadata(uniswapV2Router.WETH()).balanceOf(address(this)) - balance;
    }

    /// @notice View function for checking pending Token rewards.
    /// @param _user Address of the user.
    function pendingToken(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 _tokenPerShare = tokenPerShare;
        uint256 tokenSupply = totalBoostedShare;

        uint256 multiplier = totalReward - lastReward;
        if (multiplier > 0 && tokenSupply != 0) {

            _tokenPerShare = _tokenPerShare + multiplier * ACC_TOKEN_PRECISION / tokenSupply;
        }

        uint256 boostedAmount = user.amount * _tokenPerShare;
        return boostedAmount / ACC_TOKEN_PRECISION - user.rewardDebt;
    }

    /// @notice Update reward variables for the given.
    function update() public {
        uint256 multiplier = totalReward - lastReward;
        if (multiplier > 0) {
            uint256 tokenSupply = totalBoostedShare;
            if (tokenSupply > 0) {
                tokenPerShare = tokenPerShare + multiplier * ACC_TOKEN_PRECISION / tokenSupply;
            }
            lastReward += multiplier;
            emit Update(multiplier, tokenSupply, tokenPerShare);
        }
    }

    /// @notice Deposit tokens.
    /// @param _amount Amount of LP tokens to deposit.
    function _deposit(address _user, uint256 _amount) internal nonReentrant {
        update();
        UserInfo storage user = userInfo[_user];

        if (user.amount > 0) {
            user.pending = user.pending + (user.amount * tokenPerShare / ACC_TOKEN_PRECISION) - user.rewardDebt;
        }

        if (_amount > 0) {
            user.amount = user.amount + _amount;

            // Update total boosted share.
            totalBoostedShare = totalBoostedShare + _amount;
        }

        user.rewardDebt = user.amount * tokenPerShare / ACC_TOKEN_PRECISION;
        user.depositTime = block.timestamp;

        emit Deposit(_user, _amount);
    }

    /// @notice Withdraw LP tokens.
    /// @param _amount Amount of LP tokens to withdraw.
    function _withdraw(address _user, uint256 _amount) internal nonReentrant {

        update();

        UserInfo storage user = userInfo[_user];

        require(user.amount >= _amount, "withdraw: Insufficient");

        user.pending = user.pending + (user.amount * tokenPerShare / ACC_TOKEN_PRECISION) - user.rewardDebt;

        if (_amount > 0) {
            user.amount = user.amount - _amount;
        }
        user.rewardDebt = user.amount * tokenPerShare / ACC_TOKEN_PRECISION;
        totalBoostedShare = totalBoostedShare - _amount;

        emit Withdraw(_user, _amount);
    }

    /// @notice WithdrawPending LP tokens.
    function withdrawPending() external nonReentrant {

        require(GSSToken != address(0), "GSSToken address cannot be empty");

        update();

        UserInfo storage user = userInfo[msg.sender];

        uint256 pending = user.pending + (user.amount * tokenPerShare / ACC_TOKEN_PRECISION) - user.rewardDebt;
        user.pending = 0;
        if (pending > 0) {
            IERC20Metadata(GSSToken).transfer(msg.sender, pending);
        }

        user.rewardDebt = user.amount * tokenPerShare / ACC_TOKEN_PRECISION;
        user.total += pending;

        emit WithdrawPending(msg.sender, pending, block.timestamp);
    }

}
