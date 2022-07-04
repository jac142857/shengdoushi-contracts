const hre = require("hardhat");

const nodeEnv = process.env.NODE_ENV;
let usdtAddress = "0x55d398326f99059fF775485246999027B3197955"
const uniswapRouter2 = process.env.UNISWAP_ROUTER2
const marketing = "0x10ED43C718714eb63d5aA57B78B54704E256024E"

const constellationBaseURI = "https://storageapi.fleek.co/f3acc300-9474-41c6-bed5-09265112c190-bucket/constellation/"
const popeBaseURI = "https://storageapi.fleek.co/f3acc300-9474-41c6-bed5-09265112c190-bucket/pope/"

let verifyArr = []
let ContractList = {}

async function main() {
    let uSDT
    if (nodeEnv !== 'production') {
        const USDT = await hre.ethers.getContractFactory("USDT");
        uSDT = await USDT.deploy();
        uSDT.deployed();
        usdtAddress = uSDT.address;
        verifyArr.push({
            address: usdtAddress,
            // constructorArguments: []
        })
    }
    console.log("USDT Contract Address: ", usdtAddress);

    const PopeFeeDividend = await hre.ethers.getContractFactory("PopeFeeDividend");
    const PopeFeeDividendContract = await PopeFeeDividend.deploy();
    PopeFeeDividendContract.deployed();
    console.log("PopeFeeDividend Contract Address: ", PopeFeeDividendContract.address);
    verifyArr.push({
        address: PopeFeeDividendContract.address,
        // constructorArguments: []
    })

    const Pope = await hre.ethers.getContractFactory("Pope");
    const PopeContract = await Pope.deploy(usdtAddress, uniswapRouter2, popeBaseURI);
    PopeContract.deployed();
    console.log("Pope Contract Address: ", PopeContract.address);
    verifyArr.push({
        address: PopeContract.address,
        constructorArguments: [
            usdtAddress,
            uniswapRouter2,
            popeBaseURI
        ]
    })

    const Pledge = await hre.ethers.getContractFactory("Pledge");
    const PledgeContract = await Pledge.deploy(uniswapRouter2);
    PledgeContract.deployed();
    console.log("Pledge Contract Address: ", PledgeContract.address);
    verifyArr.push({
        address: PledgeContract.address,
        constructorArguments: [
            uniswapRouter2
        ]
    })

    const IDO = await hre.ethers.getContractFactory("IDO");
    const IDOContract = await IDO.deploy(usdtAddress, marketing);
    IDOContract.deployed();
    console.log("IDO Contract Address: ", IDOContract.address);
    verifyArr.push({
        address: IDOContract.address,
        constructorArguments: [
            usdtAddress,
            marketing
        ]
    })

    const GSSHold = await hre.ethers.getContractFactory("GSSHold");
    const GSSHoldContract = await GSSHold.deploy();
    GSSHoldContract.deployed();
    console.log("GSSHold Contract Address: ", GSSHoldContract.address);
    verifyArr.push({
        address: GSSHoldContract.address,
        // constructorArguments: []
    })

    const Constellation = await hre.ethers.getContractFactory("Constellation");
    const ConstellationContract = await Constellation.deploy(constellationBaseURI);
    ConstellationContract.deployed();
    console.log("Constellation Contract Address: ", ConstellationContract.address);
    verifyArr.push({
        address: ConstellationContract.address,
        constructorArguments: [
            constellationBaseURI
        ]
    })

    const GSS = await hre.ethers.getContractFactory("GSS");
    const GSSContract = await GSS.deploy(
        usdtAddress,
        PopeFeeDividendContract.address,
        IDOContract.address,
        GSSHoldContract.address,
        PledgeContract.address,
        ConstellationContract.address,
        PopeContract.address,
        marketing,
        uniswapRouter2
    );
    GSSContract.deployed();
    console.log("GSS Contract Address: ", GSSContract.address);
    verifyArr.push({
        address: GSSContract.address,
        constructorArguments: [
            usdtAddress,
            PopeFeeDividendContract.address,
            IDOContract.address,
            GSSHoldContract.address,
            PledgeContract.address,
            ConstellationContract.address,
            PopeContract.address,
            marketing,
            uniswapRouter2,
        ]
    })

    // PopeFeeDividend
    const PopeFeeDividendContractsetGSSTokenTx = await PopeFeeDividendContract.setGSSToken(GSSContract.address);
    // wait until the transaction is mined
    await PopeFeeDividendContractsetGSSTokenTx.wait();

    const PopeFeeDividendContractsetPopeTokenTx = await PopeFeeDividendContract.setPopeToken(PopeContract.address);
    // wait until the transaction is mined
    await PopeFeeDividendContractsetPopeTokenTx.wait();

    const PopeFeeDividendContractsetPledgeTokenTx = await PopeFeeDividendContract.setPledgeToken(PledgeContract.address);
    // wait until the transaction is mined
    await PopeFeeDividendContractsetPledgeTokenTx.wait();

    // Pope
    const PopesetGSSTokenTx = await PopeContract.setGSSToken(GSSContract.address);
    // wait until the transaction is mined
    await PopesetGSSTokenTx.wait();

    const PopesetConstellationAddressTx = await PopeContract.setConstellationAddress(ConstellationContract.address);
    // wait until the transaction is mined
    await PopesetConstellationAddressTx.wait();

    const PopesetPopeFeeDividendTokenTx = await PopeContract.setPopeFeeDividendToken(PopeFeeDividendContract.address);
    // wait until the transaction is mined
    await PopesetPopeFeeDividendTokenTx.wait();

    // Pledge
    const PledgesetGSSTokenTx = await PledgeContract.setGSSToken(GSSContract.address);
    // wait until the transaction is mined
    await PledgesetGSSTokenTx.wait();

    const PledgesetUSDTTokenTx = await PledgeContract.setUSDTToken(usdtAddress);
    // wait until the transaction is mined
    await PledgesetUSDTTokenTx.wait();

    const uniswapPair = await GSSContract.uniswapV2Pair();
    console.log("uniswapPair Contract Address：", uniswapPair)

    const PledgesetLpTokenTx = await PledgeContract.setLpToken(uniswapPair);
    // wait until the transaction is mined
    await PledgesetLpTokenTx.wait();

    const PledgesetPopeFeeDividendTokenTx = await PledgeContract.setPopeFeeDividendToken(PopeFeeDividendContract.address);
    // wait until the transaction is mined
    await PledgesetPopeFeeDividendTokenTx.wait();

    // IDO
    const IDOsetGSSTokenTx = await IDOContract.setGSSToken(GSSContract.address);
    // wait until the transaction is mined
    await IDOsetGSSTokenTx.wait();

    // GSSHold
    const GSSHoldsetGSSTokenTx = await GSSHoldContract.setGSSToken(GSSContract.address);
    // wait until the transaction is mined
    await GSSHoldsetGSSTokenTx.wait();

    // Constellation
    const ConstellationsetGSSTokenTx = await ConstellationContract.setGSSToken(GSSContract.address);
    // wait until the transaction is mined
    await ConstellationsetGSSTokenTx.wait();

    ContractList = {
        LP: uniswapPair,
        IDOContract: IDOContract.address,
        GSSHoldContract: GSSHoldContract.address,
        PledgeContract: PledgeContract.address,
        ConstellationContract: ConstellationContract.address,
        PopeContract: PopeContract.address,
        PopeFeeDividendContract: PopeFeeDividendContract.address,
        USDT: usdtAddress,
        uniswapRouter2: uniswapRouter2,
        GSS: GSSContract.address
    }

    /*
    * addIsExcluded for GSSHoldContract
    * */
    let ExcludedList = [
        PopeFeeDividendContract.address,
        IDOContract.address,
        GSSHoldContract.address,
        PledgeContract.address,
        ConstellationContract.address,
        PopeContract.address,
        marketing,
        uniswapPair,
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    ]

    for (const address of ExcludedList) {
        // console.log("ExcludedAddress: "+address)
        let GSSHoldTx = await GSSHoldContract.addIsExcluded(address)
        await GSSHoldTx.wait()
    }

    function magnifyAndToHex(number, decimal) {
        return "0x" + (number * 10 ** decimal).toString(16)
    }

    /*测试代码*/
    if (nodeEnv !== 'production') {
        let testAddress = "0xCDfF64722B726d0dEF23D36F7D754BEFb8B62861"
        testAddress = "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199"

        // 转USDT到测试地址
        const uSDTTx = await uSDT.transfer(testAddress, magnifyAndToHex(100000,6))
        await uSDTTx.wait();

        // 转gss到测试地址
        const GssTx = await GSSContract.transfer(testAddress, magnifyAndToHex(1000000, 18))
        await GssTx.wait();

    }


}

main()
    .then(() => {

        const fs = require('fs')
        try {
            fs.writeFileSync("./config.json", JSON.stringify(verifyArr))
            fs.writeFileSync("./data/ContractList.json", JSON.stringify(ContractList))
        } catch (e) {
            console.log(e, verifyArr, ContractList)
        }
        process.exit(0)
    })
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });