require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

// load config
require("dotenv").config({path: `.env.${process.env.NODE_ENV}`});

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const TEST_PRIVATE_KEY = process.env.TEST_PRIVATE_KEY;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    networks: {
        hardhat: {
            allowUnlimitedContractSize: false,
            forking: {
                url: `https://speedy-nodes-nyc.moralis.io/3968298ca8aea7e4eeb4a90f/bsc/mainnet/archive`,
                enabled: true
            }
        },
        localhost: {
            url: "http://8.219.179.92:8010",
            accounts: [PRIVATE_KEY]
        },
        localhostTest: {
            url: "http://8.219.179.92:8010",
            accounts: [TEST_PRIVATE_KEY]
        },
        bscmainnet: {
            url: `https://speedy-nodes-nyc.moralis.io/3968298ca8aea7e4eeb4a90f/bsc/mainnet`,
            accounts: [PRIVATE_KEY]
        },
        bsctestnet: {
            url: `https://speedy-nodes-nyc.moralis.io/3968298ca8aea7e4eeb4a90f/bsc/testnet`,
            accounts: [PRIVATE_KEY]
        },
        mainnet: {
            url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        ropsten: {
            url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        rinkeby: {
            url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        goerli: {
            url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        kovan: {
            url: `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        arbitrumRinkeby: {
            url: `https://arbitrum-rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        arbitrum: {
            url: `https://arbitrum-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        optimismKovan: {
            url: `https://optimism-kovan.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        optimism: {
            url: `https://optimism-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        mumbai: {
            url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
        polygon: {
            url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [PRIVATE_KEY]
        },
    },
    etherscan: {
        // Your API key for Etherscan
        // Obtain one at https://etherscan.io/
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
    solidity: {
        version: "0.8.15",
        settings: {
            optimizer: {
                enabled: true,
                runs: 1000
            }
        }
    },
};
