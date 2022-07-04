# IDO私募合约说明

## 构造函数
|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _USDTToken  | address | USDT代币地址 |

## 变量

|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| USDTToken  | address | USDT代币合约 |
| GSSToken  | address | GSS代币合约 |
| price  | uint256 | 单价 |
| endTime  | uint256 | 私募结束时间 |
| _inviterFeeRate  | uint256 | 邀请的手续费率（百分比） |
| _dividendFeeRate  | uint256 | 分红的手续费率（百分比） |
| inviter  | mapping(address => address) | 邀请关系 |


## 方法

- buy 购买代币

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _amount  | uint256 | 购买数量 |

- release 释放冻结的余额，需要endTime 到期后

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _user  | address | 释放的用户 |


- destroy 销毁剩余的没有私募完的数量，需要endTime 到期后

参数

 无


- setGSSToken 设置GSS代币合约

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _address  | address | 地址 |

# 事件

* * *

- Buy 购买私募事件

`event Buy(address indexed user, uint256 amount, uint256 money);`

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| user  | address | 购买的用户 |
| amount  | uint256 | 购买得到的GSS数量 |
| money  | uint256 | 支付的USDT数量 |

* * *

- Release 释放事件

`event Release(address indexed user, uint256 amount);`

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| user  | address | 释放的用户 |
| amount  | uint256 | 释放得到的GSS数量 |

* * *

- Destroy 销毁事件

`event Destroy(uint256 amount);`

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| amount  | uint256 | 销毁的GSS数量 |

* * *

- SuperiorReward 上级奖励的事件

`event SuperiorReward(address indexed user, address indexed superior, uint256 level, uint256 amount);`

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| user  | address | 用户地址 |
| superior  | address | 上级 |
| level  | uint256 | 上级层级（1：直推，2：间推） |
| amount  | uint256 | 奖励的USDT数量 |