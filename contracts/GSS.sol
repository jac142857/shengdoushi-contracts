// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/ERC20Basics.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./PopeFeeDividend.sol";
import "./GSSHold.sol";
import "./IDO.sol";

contract GSS is ERC20Basics {

    address public PopeFeeDividendToken;
    address public GSSHoldToken;
    address public IDOToken;

    IUniswapV2Router02 public immutable uniswapV2Router;

    address public uniswapV2Pair;

    uint256 private _feeRate = 75;

    uint256 private _destroyFeeRate = 20;
    address private _destroyAddress = address(0x0000000000000000000000000000000000000000);

    uint256 private _inviterFeeRate = 30;
    mapping(address => address) public inviter;

    uint256 private _dividendFeeRate = 50;

    event Invite(address indexed from, address indexed superior, uint256 timestamp);

    constructor(address _USDTToken, address _PopeFeeDividendToken, address _IDOToken, address _GSSHoldToken, address _PledgeToken, address _ConstellationToken, address _PopeToken, address _MarketingToken, address _uniswapV2RouterAddress)
    ERC20Basics("Gold Saints", "GSS", 18)
    {

        PopeFeeDividendToken = _PopeFeeDividendToken;
        GSSHoldToken = _GSSHoldToken;
        IDOToken = _IDOToken;

        uint256 _decimals = uint256(decimals());

        _mint(_IDOToken, 4000000 * (10 ** _decimals));

        _mint(_GSSHoldToken, 200000 * (10 ** _decimals));

        _mint(_PledgeToken, 1000000 * (10 ** _decimals));

        _mint(_ConstellationToken, 100000 * (10 ** _decimals));

        _mint(_PopeToken, 200000 * (10 ** _decimals));

        _mint(_MarketingToken, 500000 * (10 ** _decimals));

        _mint(msg.sender, 4000000 * (10 ** _decimals));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _USDTToken);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _invite(msg.sender, address(1));
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) + IDO(IDOToken).balanceOf(account);
    }

    function airdrop(address to, uint256 amount) public returns (bool) {

        address from = _msgSender();
        require(inviter[from] == address(0), "The current user has a superior");
        require(inviter[to] != address(0), " Invalid superior");

        _invite(from, to);

        _tokenTransfer(from, to, amount);

        return true;
    }

    function inviteByIDO(address from, address superior) public {
        require(msg.sender == IDOToken, "Permission denied");

        if (inviter[from] == address(0) && inviter[superior] != address(0)) {
            _invite(from, superior);
        }
    }

    function invite(address superior) public returns (bool) {
        address from = _msgSender();

        if (inviter[from] == address(0) && inviter[superior] != address(0)) {
            _invite(from, superior);
        }

        return true;
    }

    function _invite(address from, address superior) private {
        inviter[from] = superior;
        emit Invite(from, superior, block.timestamp);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address from = _msgSender();

        _tokenTransfer(from, to, amount);

        return true;
    }


    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address _spender = _msgSender();
        _spendAllowance(from, _spender, amount);
        _tokenTransfer(from, to, amount);
        return true;
    }


    function _tokenTransfer(address from, address to, uint256 amount) private {

        address _uniswapV2Pair = uniswapV2Pair;

        if (from == _uniswapV2Pair || to == _uniswapV2Pair) {
            address _user = from == _uniswapV2Pair ? to : from;
            uint256 fee = amount * _feeRate / 10000;
            if (fee > 0) {
                uint256 _destroyFee = fee * _destroyFeeRate / 100;
                if (_destroyFee > 0) {
                    _transfer(_user, _destroyAddress, _destroyFee);
                }
                uint256 _inviterFee = fee * _inviterFeeRate / 100;
                if (_inviterFee > 0 && inviter[_user] != address(0)) {
                    _transfer(_user, inviter[_user], _inviterFee);
                }
                uint256 _dividendFee = fee * _dividendFeeRate / 100;
                if (_dividendFee > 0) {
                    _transfer(_user, PopeFeeDividendToken, _dividendFee);
                    PopeFeeDividend(PopeFeeDividendToken).updateReward(_dividendFee);
                }
                amount = amount - fee;
            }
        }

        if (from != IDOToken) {
            IDO(IDOToken).release(from);
        }

        _transfer(from, to, amount);

        if (from != GSSHoldToken) {
            GSSHold(GSSHoldToken).withdraw(from, amount);
        }
        if (to != GSSHoldToken) {
            GSSHold(GSSHoldToken).deposit(to, amount);
        }

    }

}