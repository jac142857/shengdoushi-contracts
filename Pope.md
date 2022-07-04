# 代币持仓合约说明

> 标准的NFT合约，通用的质押合约的方法

## 构造函数
|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _USDTToken  | address | USDT合约地址 |
| _uniswapV2Router  | address | swap路由合约地址 |

## 额外变量

|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _tokenIds  | uint256 | 自增的tokenID |
| max  | uint256 | 最大mint数量 |
| constellationAddress  | address | 星座合约 |
| GSSToken  | address | GSS合约 |
| PopeFeeDividendToken  | address | 手续费分红合约 |
| USDTToken  | address | USDT合约 |


## 额外方法

- mintPrice 获取mint价格

参数

 无


- setBaseURI 设置基础URI（管理员调用）

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _uri  | string | 链接 |

- setGSSToken 设置GSS合约地址（管理员调用）

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _token  | address | 地址 |

- setConstellationAddress 设置星座卡合约地址（管理员调用）

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _token  | address | 地址 |

- setPopeFeeDividendToken 设置手续费分红合约地址（管理员调用）

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _token  | address | 地址 |

- swapUSDT 把GSS兑换成USDT，每天调用（管理员调用）

参数

 无

- mineETH 挖矿ETH（管理员调用）

参数

 无