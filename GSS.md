# 代币合约说明

## 构造函数
|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _USDTToken  | address | USDT代币地址 |
| _PopeFeeDividendToken  | address | 教皇分红合约地址 |
| _IDOToken  | address | 私募合约地址 |
| _GSSHoldToken  | address | GSS持仓合约地址 |
| _PledgeToken  | address | 锁仓LP合约地址 |
| _ConstellationToken  | address | 星座卡合约地址 |
| _PopeToken  | address | 教皇卡合约地址 |
| _MarketingToken  | address | 营销地址 |
| _uniswapV2RouterAddress  | address | swap路由合约地址 |

## 变量

|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| PopeFeeDividendToken  | address | 教皇卡分红合约地址 |
| uniswapV2Router  | IUniswapV2Router02 | swap的路由合约 |
| _feeRate  | uint256 | 手续费率（千分比） |
| _destroyFeeRate  | uint256 | 销毁的手续费率（百分比） |
| _inviterFeeRate  | uint256 | 邀请的手续费率（百分比） |
| _dividendFeeRate  | uint256 | 分红的手续费率（百分比） |
| inviter  | mapping(address => address) | 邀请关系 |


## 额外方法

- airdrop 空投方法

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| to  | address | 地址 |
| amount  | uint256 | 数量 |
