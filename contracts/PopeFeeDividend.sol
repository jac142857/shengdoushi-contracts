// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20Metadata.sol";
import "./libraries/Ownable.sol";
import "./security/ReentrancyGuard.sol";
import "./Pope.sol";

contract PopeFeeDividend is Ownable, ReentrancyGuard {

    address public GSSToken;
    address public PopeToken;
    address public PledgeToken;

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
    event UpdateReward(uint256 amout);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event WithdrawPending(address indexed user, uint256 pending, uint256 time);

    constructor() {
    }

    function setGSSToken(address _token) external onlyOwner {

        require(GSSToken == address(0), "Parameters can only be set once");

        GSSToken = _token;
    }

    function setPopeToken(address _token) external onlyOwner {

        require(PopeToken == address(0), "Parameters can only be set once");

        PopeToken = _token;
    }

    function setPledgeToken(address _token) external onlyOwner {

        require(PledgeToken == address(0), "Parameters can only be set once");

        PledgeToken = _token;
    }

    /// @notice Update reward variables for the given.
    function updateReward(uint256 _amount) public nonReentrant {

        require(msg.sender == GSSToken, "Permission denied");

        totalReward += _amount;

        emit UpdateReward(_amount);
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
    function deposit(address _user) external nonReentrant {

        if (Pope(PopeToken).userInfoAmount(_user) == 0 && Pope(PopeToken).balanceOf(_user) > 0) {
            require(msg.sender == PledgeToken, "Permission denied");

            _deposit(_user, 1);
        }

    }

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
    function withdraw(address _user) external nonReentrant {
        if (Pope(PopeToken).userInfoAmount(_user) > 0) {
            require(msg.sender == PledgeToken || msg.sender == PopeToken, "Permission denied");
            _withdraw(_user, 1);
        }
    }
    
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
