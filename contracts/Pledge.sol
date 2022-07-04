// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/Ownable.sol";
import "./interfaces/IERC20Metadata.sol";
import "./libraries/SafeERC20.sol";
import "./security/ReentrancyGuard.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./GSS.sol";
import "./PopeFeeDividend.sol";

contract Pledge is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    IUniswapV2Router02 public immutable uniswapV2Router;

    address public lpToken;

    address public GSSToken;

    address public USDTToken;

    address public PopeFeeDividendToken;

    uint256 public totalReward;
    uint256 public maxReward = 100000 * 1e18;

    uint256 public constant ACC_TOKEN_PRECISION = 1e18;

    // The amount of allocation points assigned to the token.
    uint256 public allocReward = 83870101986000000;

    // Accumulated Tokens per share.
    uint256 public tokenPerShare = 0;
    // Last block number that token update action is executed.
    uint256 public lastRewardBlock = 0;
    // The total amount of user shares in each pool. After considering the share boosts.
    uint256 public totalBoostedShare = 0;

    /// @notice Info of each Pledge user.
    /// `amount` amount the user has provided.
    /// `lpAmount` lpToken amount the user has provided.
    /// `uAmount` usdt amount the user has provided.
    /// `rewardDebt` Used to calculate the correct amount of rewards. See explanation below.
    /// `pending` Pending Rewards.
    /// `grade` Last pledge grade
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
        uint256 lpAmount;
        uint256 uAmount;
        uint256 rewardDebt;
        uint256 pending;
        uint256 total;
        uint256 grade;
        uint256 depositTime;
    }

    /// @notice Info of user.
    mapping(address => UserInfo) public userInfo;

    event Update(uint256 lastRewardBlock, uint256 tokenSupply, uint256 tokenPerShare);
    event Deposit(address indexed user, uint256 amount, uint256 grade);
    event Withdraw(address indexed user, uint256 amount, uint256 grade, uint256 lpAmount, uint256 uAmount, uint256 pending);
    event SetAllocReward(uint256 amount);
    event SuperiorReward(address indexed user, address indexed superior, uint256 level, uint256 amount);

    constructor(address _uniswapV2Router) {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        lastRewardBlock = block.number;
    }

    /// @notice View function for checking pending Token rewards.
    /// @param _user Address of the user.
    function pendingToken(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 _tokenPerShare = tokenPerShare;
        uint256 tokenSupply = totalBoostedShare;

        if (block.number > lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = block.number - lastRewardBlock;

            uint256 tokenReward = multiplier * allocReward;
            tokenReward = totalReward + tokenReward > maxReward ? maxReward - totalReward : tokenReward;

            _tokenPerShare = _tokenPerShare + tokenReward * ACC_TOKEN_PRECISION / tokenSupply;
        }

        uint256 boostedAmount = user.amount * user.grade * _tokenPerShare;
        return boostedAmount / ACC_TOKEN_PRECISION - user.rewardDebt;
    }

    /// @notice Update reward variables for the given.
    function update() public {
        if (block.number > lastRewardBlock) {
            uint256 tokenSupply = totalBoostedShare;
            if (tokenSupply > 0) {
                uint256 multiplier = block.number - lastRewardBlock;
                uint256 tokenReward = multiplier * allocReward;
                tokenReward = totalReward + tokenReward > maxReward ? maxReward - totalReward : tokenReward * 115 / 100;
                totalReward += tokenReward;
                tokenPerShare = tokenPerShare + tokenReward * ACC_TOKEN_PRECISION / tokenSupply;
            }
            lastRewardBlock = block.number;
            emit Update(lastRewardBlock, tokenSupply, tokenPerShare);
        }
    }

    /// @notice Deposit tokens.
    function deposit(uint256 _amount, uint256 _grade) external nonReentrant {

        require(_amount > 0, "Quantity cannot be 0");
        require(_grade > 0, "grade cannot be 0");

        UserInfo storage user = userInfo[msg.sender];

        require(user.amount == 0, "Can not be re-staking");

        update();

        uint256 _lpAmount = _amount / 2;

        uint256 _balance = IERC20Metadata(USDTToken).balanceOf(lpToken);

        uint256 _totalSupply = IERC20Metadata(lpToken).totalSupply();

        uint256 _lp = _lpAmount * _totalSupply / _balance / 2;

        IERC20Metadata(lpToken).safeTransferFrom(msg.sender, address(this), _lp);

        IERC20Metadata(USDTToken).safeTransferFrom(msg.sender, address(this), _amount - _lpAmount);

        user.amount = _amount;
        user.lpAmount = _lp;
        user.uAmount = _amount - _lpAmount;

        // Update total boosted share.
        totalBoostedShare = totalBoostedShare + _amount * _grade;

        user.grade = _grade;
        user.rewardDebt = user.amount * _grade * tokenPerShare / ACC_TOKEN_PRECISION;
        user.depositTime = block.timestamp;

        if (_amount >= 2000 * (10 ** IERC20Metadata(USDTToken).decimals())) {
            PopeFeeDividend(PopeFeeDividendToken).deposit(msg.sender);
        }

        emit Deposit(msg.sender, _amount, _grade);
    }

    /// @notice Withdraw LP tokens.
    function withdraw() external nonReentrant {

        UserInfo storage user = userInfo[msg.sender];

        uint256 grade = user.grade;

        // TODO       require(grade * 7 * 86400 + user.depositTime <= block.timestamp, "The pledge time has not expired");

        update();

        uint256 _amount = user.amount;

        require(_amount > 0, "withdraw: Insufficient");

        uint256 accToken = _amount * tokenPerShare / ACC_TOKEN_PRECISION;

        uint256 pending = accToken - user.rewardDebt;
        if (pending > 0) {
            address superior = GSS(GSSToken).inviter(msg.sender);
            uint256 fee1 = 0;
            uint256 fee2 = 0;

            if (superior != address(0) && superior != address(1)) {
                fee1 = pending * 10 / 100;
                if (fee1 > 0) {
                    if (userInfo[superior].amount > 0) {
                        IERC20Metadata(USDTToken).transfer(superior, fee1);
                        emit SuperiorReward(msg.sender, superior, 1, fee1);
                    }

                    address twoSuperior = GSS(GSSToken).inviter(superior);
                    if (twoSuperior != address(0) && twoSuperior != address(1) && userInfo[twoSuperior].amount > 0) {
                        fee2 = pending * 5 / 100;
                        if (fee2 > 0) {
                            IERC20Metadata(USDTToken).transfer(twoSuperior, fee2);
                            emit SuperiorReward(msg.sender, twoSuperior, 2, fee2);
                        }
                    }
                }
            }
            IERC20Metadata(GSSToken).transfer(msg.sender, pending - fee1 - fee2);
            user.total += pending;
        }

        uint256 _lpAmount = user.lpAmount;
        uint256 _uAmount = user.uAmount;

        user.amount = 0;
        user.lpAmount = 0;
        user.uAmount = 0;
        user.pending = 0;

        totalBoostedShare = totalBoostedShare - _amount * grade;

        IERC20Metadata(lpToken).safeTransfer(msg.sender, _lpAmount);
        IERC20Metadata(USDTToken).safeTransfer(msg.sender, _uAmount);

        if (_amount >= 2000 * (10 ** IERC20Metadata(USDTToken).decimals())) {
            PopeFeeDividend(PopeFeeDividendToken).withdraw(msg.sender);
        }

        emit Withdraw(msg.sender, _amount, grade, _lpAmount, _uAmount, pending);
    }

    function setAllocReward(uint256 _allocReward) external onlyOwner {

        allocReward = _allocReward;

        emit SetAllocReward(_allocReward);
    }


    function setGSSToken(address _token) external onlyOwner {

        require(GSSToken == address(0), "Parameters can only be set once");

        GSSToken = _token;
    }


    function setLpToken(address _token) external onlyOwner {

        require(lpToken == address(0), "Parameters can only be set once");

        lpToken = _token;
    }


    function setUSDTToken(address _token) external onlyOwner {

        require(USDTToken == address(0), "Parameters can only be set once");

        USDTToken = _token;
    }

    function setPopeFeeDividendToken(address _token) external onlyOwner {

        require(PopeFeeDividendToken == address(0), "Parameters can only be set once");

        PopeFeeDividendToken = _token;
    }

}
