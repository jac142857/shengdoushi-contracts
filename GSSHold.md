# 代币持仓合约说明

> 通用的质押合约的方法，`deposit` 和 `withdraw` 方法需要 GSS代币合约才能调用

## 额外变量

|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| GSSToken  | address | GSS代币合约 |
| _isExcluded  | mapping(address => bool) | 不参与持仓分红的地址 |


## 额外方法

- setGSSToken 设置GSS代币合约

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _token  | address | token地址 |


- addIsExcluded 添加不参与分红的地址

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _address  | address | 地址 |