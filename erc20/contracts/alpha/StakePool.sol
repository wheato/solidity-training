// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interface.sol";
import "./GoToken.sol";

contract StakePool {
  using SafeMath for uint256;

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  struct PoolInfo {
    IBEP20 lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 rewardPerBlock;
    uint256 accGotPerShare;
  }

  GoToken public got;

  PoolInfo[] public poolInfo;

  mapping (uint256 => mapping(address => UserInfo)) public userInfo;

  uint256 public totalAllocPoint = 0;

  uint256 public startBlock = 0;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

  event Reward(address indexed user, uint256 indexed pid, uint256 amount);

  constructor (GoToken _got) {
    got = _got;
  }

  function add(IBEP20 _lpToken) public {
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(100);
    poolInfo.push(PoolInfo({
      lpToken: _lpToken,
      allocPoint: 100,
      rewardPerBlock: 20 * 10 ** 18,
      lastRewardBlock: lastRewardBlock,
      accGotPerShare: 0
    }));
  }

  function deposit(uint256 _pid, uint256 _amount) public {
    require(_amount > 0, "Deposit amount must be greater than 0");
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    
    updatePool(_pid);

    // 追加质押前先结算之前的奖励
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accGotPerShare)
      .div(1e12)
      .sub(user.rewardDebt);
      require(got.transfer(msg.sender, pending), "Failed to transfer reward");
    }

    require(pool.lpToken.transferFrom(msg.sender, address(this), _amount), "Failed to transfer tokens");
    user.amount = user.amount.add(_amount);
    // 更新不可领取的部分
    user.rewardDebt = user.amount.mul(pool.accGotPerShare).div(1e12);

    emit Deposit(msg.sender, _pid, _amount);
  }

  function withdraw(uint256 _pid, uint256 _amount) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    require(user.amount >= _amount, "Insufficient balance");
    updatePool(_pid);

    uint256 pending = user.amount.mul(pool.accGotPerShare)
    .div(1e12)
    .sub(user.rewardDebt);

    require(got.transfer(msg.sender, pending), "Failed to transfer reward");

    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(pool.accGotPerShare).div(1e12);

    require(pool.lpToken.transfer(msg.sender, _amount), "Failed to transfer tokens");

    emit Withdraw(msg.sender, _pid, _amount);
  }

  function claim(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    if (user.amount == 0) {
        return;
    }

    updatePool(_pid);

    uint256 pending = user.amount.mul(pool.accGotPerShare)
      .div(1e12)
      .sub(user.rewardDebt);

    if (pending > 0) {
        got.transfer(msg.sender, pending);
        emit Reward(msg.sender, _pid, pending);
    }

    user.rewardDebt = user.amount.mul(pool.accGotPerShare).div(1e12);
  }

  function updatePool(uint256 _pid) internal {
    PoolInfo storage pool = poolInfo[_pid];
    uint256 multiplier = block.number.sub(pool.lastRewardBlock);
    uint256 gotReward = multiplier.mul(pool.rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
    pool.accGotPerShare = pool.accGotPerShare.add(gotReward.mul(1e12).div(pool.lpToken.balanceOf(address(this))));
    pool.lastRewardBlock = block.number;
  }
}