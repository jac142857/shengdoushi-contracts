// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./interfaces/IERC20Metadata.sol";
import "./libraries/Ownable.sol";
import "./GSS.sol";

contract IDO is Ownable {

    mapping(address => uint256) private _balances;

    uint256 public totalSupply;

    address public USDTToken;

    address public GSSToken;

    address public fundAddress;

    uint256 public price;

    uint256 public endTime = 1657965722; // 2022-07-16 18:02:02

    uint256 public buyStartTime;
    uint256 public buyEndTime;

    event Buy(address indexed user, uint256 amount, uint256 money, uint256 timestamp);
    event Release(address indexed user, uint256 amount);
    event SuperiorReward(address indexed user, address indexed superior, uint256 level, uint256 amount, uint256 timestamp);
    event Destroy(uint256 amount);
    event SetTimeAndPrice(uint256 price, uint256 buyStartTime, uint256 buyEndTime);

    constructor(address _USDTToken, address _fundAddress) {
        USDTToken = _USDTToken;
        price = 5 * (10 ** IERC20Metadata(USDTToken).decimals()) / 10;
        fundAddress = _fundAddress;
    }

    function setTimeAndPrice(uint256 _price, uint256 _buyStartTime, uint256 _buyEndTime) external onlyOwner {
        price = _price;
        buyStartTime = _buyStartTime;
        buyEndTime = _buyEndTime;
        emit SetTimeAndPrice(_price, _buyStartTime, _buyEndTime);
    }


    function buy(uint256 money, address _superior) external {

        require(block.timestamp >= buyStartTime && block.timestamp < buyEndTime, "Private placement has ended");

        uint256 _amount = money * (10 ** GSS(GSSToken).decimals()) / price;

        require(GSS(GSSToken).balanceOf(address(this)) >= _amount, "Insufficient balance");

        IERC20Metadata(USDTToken).transferFrom(msg.sender, address(this), money);

        _balances[msg.sender] += _amount;

        totalSupply += _amount;

        address superior = GSS(GSSToken).inviter(msg.sender);
        if (superior == address(0) && GSS(GSSToken).inviter(_superior) != address(0)) {
            superior = _superior;
            GSS(GSSToken).inviteByIDO(msg.sender, superior);
        }
        uint256 fee1 = 0;
        uint256 fee2 = 0;
        if (superior != address(0)) {
            fee1 = money * 10 / 100;
            if (fee1 > 0) {
                IERC20Metadata(USDTToken).transfer(superior, fee1);
                emit SuperiorReward(msg.sender, superior, 1, fee1, block.timestamp);
                address twoSuperior = GSS(GSSToken).inviter(superior);
                if (twoSuperior != address(0) && twoSuperior != address(1)) {
                    fee2 = money * 5 / 100;
                    if (fee2 > 0) {
                        IERC20Metadata(USDTToken).transfer(twoSuperior, fee2);
                        emit SuperiorReward(msg.sender, twoSuperior, 2, fee2, block.timestamp);
                    }
                }
            }
        }
        IERC20Metadata(USDTToken).transfer(fundAddress, money - fee1 - fee2);

        emit Buy(msg.sender, _amount, money, block.timestamp);
    }

    function release(address _user) external {
        uint256 balance = _balances[_user];
        if (balance > 0 && block.timestamp >= endTime) {

            _balances[_user] = 0;
            GSS(GSSToken).transfer(_user, balance);

            emit Release(msg.sender, balance);
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function destroy() external {

        require(block.timestamp >= endTime, "Private placement is not over yet");

        uint256 _amount = IERC20Metadata(GSSToken).balanceOf(address(this)) - totalSupply;

        require(_amount > 0, "Balance cannot be 0");

        IERC20Metadata(GSSToken).transfer(address(0), _amount);

        emit Destroy(_amount);
    }


    function setGSSToken(address _token) external onlyOwner {

        require(GSSToken == address(0), "Parameters can only be set once");

        GSSToken = _token;
    }
}
