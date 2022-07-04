# 锁仓LP合约说明

> 通用的质押合约的方法

## 构造函数
|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| __uniswapV2Router  | address | swap路由合约地址 |

## 额外变量

|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| lpToken  | address | GSS/USDT交易对 |
| GSSToken  | address | GSS代币合约 |
| USDTToken  | address | USDT代币合约 |
| PopeFeeDividendToken  | address | 教皇分红合约 |
| totalReward  | uint256 | 当前已奖励数量 |
| maxReward  | uint256 | 最大奖励数量 |


## 额外方法


- setAllocReward 设置每个块的收益

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _allocReward  | address | 收益数量 |


- setGSSToken 设置GSS代币合约

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _token  | address | token地址 |


- setLpToken 设置LP交易对合约

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _token  | address | token地址 |


- setPopeFeeDividendToken 设置教皇分红合约

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _token  | address | token地址 |