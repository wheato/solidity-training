// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./interface.sol";

contract GoToken is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  string public _name;
  string public _symbol;
  uint8 public _decimals;
  uint256 private _totalSupply;

  constructor() {
      _name = "Go Token";
      _symbol = "GOT";
      _decimals = 18;
      _totalSupply = 2000000 * 10 ** 18;

      uint256 initialToken = 2000000 * 10 ** 18;
      _balances[msg.sender] = initialToken;

      emit Transfer(address(0), msg.sender, initialToken);
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  function name() external view override returns (string memory) {
    return _name;
  }

  function getOwner() external view override returns (address) {
    return owner();
  }

  function balanceOf(
    address account
  ) external view override returns (uint256) {
    return _balances[account];
  }

  function transfer(
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(
    address _owner,
    address spender
  ) external view override returns (uint256) {
    return _allowances[_owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender, 
      _msgSender(), 
      _allowances[sender][_msgSender()].sub(
        amount, 
        "BEP20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(
      amount,
      "BEP20: transfer amount exceeds balance"
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(
      amount, 
      "BEP20: burn amount exceeds balance"
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }
}