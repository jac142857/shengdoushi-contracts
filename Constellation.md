# 星座卡合约

> 标准的NFT合约，通用的质押合约的方法

## 额外变量

|  变量名   | 类型  | 备注  |
|  ----  | ----  | ----  |
| max  | uint256 | 最大mint数量 |
| GSSToken  | address | GSS合约 |


## 额外方法

- setBaseURI 设置基础URI（管理员调用）

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _uri  | string | 链接 |

- mint 获取mint价格

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| recipient  | address | mint地址 |
| _tokenId  | uint256 | 指定的铸造ID |
| hash  | bytes32 | 使用_tokenId生成的哈希 |
| signature  | bytes | 管理员签名的hash |

- getTokenIdHash 获取tokenID的哈希

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _tokenId  | uint256 | 需要的铸造ID |

- approveAll 批量授权

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| to  | address | 授权地址 |
| _tokenIds  | uint256[12] | 授权的tokenID列表 |

- burnAll 批量销毁

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _tokenIds  | uint256[12] | 销毁的tokenID列表 |


- setGSSToken 设置GSS合约地址（管理员调用）

参数

|  参数   | 类型  | 备注  |
|  ----  | ----  | ----  |
| _token  | address | 地址 |
