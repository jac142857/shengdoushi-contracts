// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/ERC20Basics.sol";
import "./libraries/Ownable.sol";

contract USDT is ERC20Basics, Ownable {
    constructor()
    ERC20Basics("USDT6", "USDT6", 6)
    {
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
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
        address _spender = _msgSender();
        _transfer(_spender, to, amount);
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
        _transfer(from, to, amount);
        return true;
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint256 amount) public onlyOwner {
        require(totalSupply() + amount > totalSupply());
        require(balanceOf(owner()) + amount > balanceOf(owner()));

        _mint(owner(), amount);
    }

}