// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./libraries/Counters.sol";
import "./cryptography/SignatureChecker.sol";
import "./security/ReentrancyGuard.sol";
import "./libraries/Ownable.sol";
import "./interfaces/IERC20Metadata.sol";

contract Constellation is ERC721Enumerable, Ownable, ReentrancyGuard {
    string public baseURI;

    uint256 public max = 2880;
    address public GSSToken;

    uint256 public totalReward;
    uint256 public maxReward = 100000 * 1e18;
    uint256 public constant ACC_TOKEN_PRECISION = 1e18;
    // The amount of allocation points assigned to the token.
    uint256 public constant ALLOC_REWARD = 9645061728400000;
    // Accumulated Tokens per share.
    uint256 public tokenPerShare = 0;
    // Last block number that token update action is executed.
    uint256 public lastRewardBlock = 0;
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

    event Update(uint256 lastRewardBlock, uint256 tokenSupply, uint256 tokenPerShare);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event WithdrawPending(address indexed user, uint256 pending, uint256 time);

    constructor(string memory newBaseURI) ERC721("Constellation", "CTN") {

        lastRewardBlock = block.number;
        baseURI = newBaseURI;
    }

    function mint(address recipient, uint256 _tokenId, bytes32 hash, bytes memory signature) external returns (uint256){

        require(_tokenId > 0, "Exceeded the minimum number of mint");

        require(_tokenId < max + 1, "Exceeded the maximum number of mint");

        require(getTokenIdHash(_tokenId) == hash, "TokenId is invalid");

        //  Verify signature
        require(SignatureChecker.isValidSignatureNow(owner(), getEthSignedMessageHash(hash), signature), "Failed to verify signature");

        _mint(recipient, _tokenId);

        return _tokenId;
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
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approveAll(address to, uint256[12] memory _tokenIds) external {

        for(uint256 i = 0; i < 12; i++) {
            uint256 _tokenId = _tokenIds[i];
            address owner = ownerOf(_tokenId);
            require(to != owner, "ERC721: approval to current owner");

            require(
                _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
                "ERC721: approve caller is not token owner nor approved for all"
            );
            _approve(to, _tokenId);
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function burnAll(uint256[12] memory _tokenIds) external {
        address _sender = _msgSender();
        for(uint256 i = 0; i < 12; i++) {
            uint256 _tokenId = _tokenIds[i];
            address owner = ownerOf(_tokenId);

            require(
                _sender == owner || isApprovedForAll(owner, _sender),
                "ERC721: approve caller is not token owner nor approved for all"
            );
            _burn(_tokenId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function getTokenIdHash(uint256 _id) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_id));
    }

    function getEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function setGSSToken(address _token) external onlyOwner {

        require(GSSToken == address(0), "Parameters can only be set once");

        GSSToken = _token;
    }

    /// @notice View function for checking pending Token rewards.
    /// @param _user Address of the user.
    function pendingToken(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 _tokenPerShare = tokenPerShare;
        uint256 tokenSupply = totalBoostedShare;

        if (block.number > lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = block.number - lastRewardBlock;

            uint256 tokenReward = multiplier * ALLOC_REWARD;
            tokenReward = totalReward + tokenReward > maxReward ? maxReward - totalReward : tokenReward;

            _tokenPerShare = _tokenPerShare + tokenReward * ACC_TOKEN_PRECISION / tokenSupply;
        }

        uint256 boostedAmount = user.amount * _tokenPerShare;
        return boostedAmount / ACC_TOKEN_PRECISION - user.rewardDebt;
    }


    /// @notice Update reward variables for the given.
    function update() public {
        if (block.number > lastRewardBlock) {
            uint256 tokenSupply = totalBoostedShare;
            if (tokenSupply > 0) {
                uint256 multiplier = block.number - lastRewardBlock;
                uint256 tokenReward = multiplier * ALLOC_REWARD;
                tokenReward = totalReward + tokenReward > maxReward ? maxReward - totalReward : tokenReward;
                totalReward += tokenReward;
                tokenPerShare = tokenPerShare + tokenReward * ACC_TOKEN_PRECISION / tokenSupply;
            }
            lastRewardBlock = block.number;
            emit Update(lastRewardBlock, tokenSupply, tokenPerShare);
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
