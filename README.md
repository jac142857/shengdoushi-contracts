# 简介

圣斗士智能合约

# Local Development
The following assumes the use of node@>=10.

# 多环境
`.env.development` `.env.production` `.env.stage`

> .env.* 后缀文件配置

```shell
# infura API的key
INFURA_API_KEY=
# 区块链浏览器的key
ETHERSCAN_API_KEY=
# 部署合约的私钥
PRIVATE_KEY=
# uniswap 的路由合约地址
UNISWAP_ROUTER2=
```

# Install Dependencies
yarn

# Compile Contracts
yarn compile

# Run Tests
yarn test

# 本地环境运行
yarn dev

# 线上打包
yarn build

# remixd

remixd ./

# ganache，bsc 网络要使用 moralis 提供的rpc节点 

ganache --wallet.accounts "0x3b81b214a327acd39d1d36f96a254d0810f402e4eaaf65960cbbc68f044c2e64, 1000000000000000000000000" --fork.url https://speedy-nodes-nyc.moralis.io/3968298ca8aea7e4eeb4a90f/bsc/mainnet/archive

# 钱包签名，remix 浏览器里面打开控制台依次输入

```shell
ethereum.enable()
account = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
hash = "xxxxx"
ethereum.request({method: "personal_sign", params: [account, hash]})
```

# 代币合约说明

- `constants/GSS.sol`

[跳转说明](./GSS.md)

# 代币持仓合约说明

- `constants/GSSHold.sol`

[跳转说明](./GSSHold.md)

# IDO私募合约说明

- `constants/IDO.sol`

[跳转说明](./IDO.md)

# 锁仓LP合约说明

- `constants/Pledge.sol`

[跳转说明](./Pledge.md)

# 星座卡合约说明

- `constants/Constellation.sol`

[跳转说明](./Constellation.md)

# 教皇卡合约说明

- `constants/Pope.sol`

[跳转说明](./Pope.md)

# 教皇卡手续费分红合约说明

- `constants/PopeFeeDividend.sol`

[跳转说明](./PopeFeeDividend.md)

# 获取NFT列表

```solidity
function getList(address _addr, uint256 startIndex, uint256 endIndex) public view returns (uint256[]memory idArr){
    uint256 ba = balanceOf(_addr);
    require(startIndex <= endIndex, "err1");
    require(endIndex < ba, "err2");
    uint len = endIndex.sub(startIndex).add(1);
    idArr = new uint256[](len);
    uint index;
    for (; startIndex <= endIndex; startIndex++) {
        uint256 nftId = tokenOfOwnerByIndex(_addr, startIndex);
        idArr[index] = nftId;
        index++;
    }
}
```
