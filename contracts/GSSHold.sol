// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./libraries/Ownable.sol";
import "./security/ReentrancyGuard.sol";

contract GSSHold is Ownable, ReentrancyGuard {

    address GSSToken;

    mapping(address => bool) public isExcluded;

    uint256 public totalReward;
    uint256 public maxReward = 200000 * 1e18;
    uint256 public constant ACC_TOKEN_PRECISION = 1e18;
    // The amount of allocation points assigned to the token.
    uint256 public constant ALLOC_REWARD = 19290123456800000;
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

    constructor() {
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
    function deposit(address _user, uint256 _amount) external nonReentrant {

        require(msg.sender == GSSToken, "Can only be called by GSS");

        if (!isExcluded[_user]) {
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
    }

    /// @notice Withdraw LP tokens.
    /// @param _amount Amount of LP tokens to withdraw.
    function withdraw(address _user, uint256 _amount) external nonReentrant {
        require(msg.sender == GSSToken, "Can only be called by GSS");

        if (!isExcluded[_user]) {
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
    }

    /// @notice WithdrawPending LP tokens.
    function withdrawPending() external {

        require(GSSToken != address(0), "GSSToken address cannot be empty");

        update();

        UserInfo storage user = userInfo[msg.sender];

        uint256 pending = user.pending + (user.amount * tokenPerShare / ACC_TOKEN_PRECISION) - user.rewardDebt;
        user.pending = 0;
        user.rewardDebt = user.amount * tokenPerShare / ACC_TOKEN_PRECISION;
        user.total += pending;
        if (pending > 0) {
            IERC20(GSSToken).transfer(msg.sender, pending);
        }


        emit WithdrawPending(msg.sender, pending, block.timestamp);
    }

    function setGSSToken(address _token) external onlyOwner {

        require(GSSToken == address(0), "Parameters can only be set once");

        GSSToken = _token;
    }

    function addIsExcluded(address _address) external onlyOwner {
        isExcluded[_address] = true;
    }

}
