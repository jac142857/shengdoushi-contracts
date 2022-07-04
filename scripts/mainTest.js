const hre = require("hardhat");


let LPContract, USDTContract, GSSContract, IDOContract, GSSHoldContract, PledgeContract, ConstellationContract,
    PopeContract, PopeFeeDividendContract, uniswapRouter2Contract

let testAddress = "0xCDfF64722B726d0dEF23D36F7D754BEFb8B62861"
testAddress = "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199"

/**
 * 换算工具
 * @param:number 待换算数字
 * @param:decimal 小数位数
 * @return: String 十六进制字符串,有0x
 * */
function magnifyAndToHex(number, decimal) {
    return "0x" + (number * 10 ** decimal).toString(16)
}

async function testPledge() {

    //添加流动性授权
    const USDTApproveTx = await USDTContract.approve(uniswapRouter2Contract.address, magnifyAndToHex(1000, 6))
    await USDTApproveTx.wait();

    const GSSApprove = await GSSContract.approve(uniswapRouter2Contract.address, magnifyAndToHex(2000, 18))
    await GSSApprove.wait();

    // 添加流动性
    const addLiquidityTx = await uniswapRouter2Contract.addLiquidity(
        USDTContract.address,
        GSSContract.address,
        magnifyAndToHex(1000, 6),
        magnifyAndToHex(2000, 18),
        "0x0",
        "0x0",
        testAddress,
        "1659092352"
    )
    await addLiquidityTx.wait()

    //usdt授权到质押合约
    const USDTApproveToPledgeContractTx = await USDTContract.approve(PledgeContract.address, magnifyAndToHex(1000, 6))
    await USDTApproveToPledgeContractTx.wait();

    //LP授权到质押合约
    const LPContractTx = await LPContract.approve(PledgeContract.address, magnifyAndToHex(2000, 18))
    await LPContractTx.wait();

    let usdtApprove = await USDTContract.allowance(testAddress, PledgeContract.address)
    let LPApprove = await LPContract.allowance(testAddress, PledgeContract.address)
    console.log("usdtApprove => " + usdtApprove / 1e6)
    console.log("LPApprove => " + LPApprove / 1e18)

    let depositTx = await PledgeContract.deposit(magnifyAndToHex(2000, 6), 1)
    await depositTx.wait()

}

async function testIDO() {
    //授权USDT到IPO
    const USDTApproveTx = await USDTContract.approve(IDOContract.address, magnifyAndToHex(100000, 6))
    await USDTApproveTx.wait()

    let IDOBuyTx = await IDOContract.buy(magnifyAndToHex(10, 6), "0x".padEnd(42, "0"))
    await IDOBuyTx.wait()

    IDOBuyTx = await IDOContract.buy(magnifyAndToHex(230, 6), "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
    await IDOBuyTx.wait()

    IDOBuyTx = await IDOContract.buy(magnifyAndToHex(100, 6), "0x".padEnd(42, "0"))
    await IDOBuyTx.wait()

    IDOBuyTx = await IDOContract.buy(magnifyAndToHex(110, 6), "0x".padEnd(42, "0"))
    await IDOBuyTx.wait()

    IDOBuyTx = await IDOContract.buy(magnifyAndToHex(310, 6), "0x".padEnd(42, "0"))
    await IDOBuyTx.wait()

    IDOBuyTx = await IDOContract.buy(magnifyAndToHex(923, 6), "0x".padEnd(42, "0"))
    await IDOBuyTx.wait()
}

async function testConstellation() {
    let tokenId = 118
    // let hash = hre.ethers.utils.keccak256("0x01")
    // let hash = await ConstellationContract.getTokenIdHash("0x" + tokenId.toString(16).padStart(64, "0"))
    let hash = await ConstellationContract.getTokenIdHash(`0x${tokenId.toString(16).padStart(64, "0")}`)
    let binaryData = hre.ethers.utils.arrayify(hash);

    let wallet = new hre.ethers.Wallet("ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
    let signature = await wallet.signMessage(binaryData)

    console.log("hash: " + hash)
    console.log("signature: " + signature)

    // function mint(address recipient, uint256 _tokenId, bytes32 hash, bytes memory signature)

    let mintTx = await ConstellationContract.mint(testAddress, tokenId, hash, signature)
    await mintTx.wait()
}

async function main() {
    const fs = require('fs')

    try {
        const data = fs.readFileSync('./data/ContractList.json', 'utf8')
        const contracts = JSON.parse(data)

        LPContract = await hre.ethers.getContractAt("IERC20Metadata", contracts.LP)
        USDTContract = await hre.ethers.getContractAt("USDT", contracts.USDT)
        GSSContract = await hre.ethers.getContractAt("GSS", contracts.GSS)

        IDOContract = await hre.ethers.getContractAt("IDO", contracts.IDOContract)
        GSSHoldContract = await hre.ethers.getContractAt("GSSHold", contracts.GSSHoldContract)

        PledgeContract = await hre.ethers.getContractAt("Pledge", contracts.PledgeContract)

        ConstellationContract = await hre.ethers.getContractAt("Constellation", contracts.ConstellationContract)
        PopeContract = await hre.ethers.getContractAt("Pope", contracts.PopeContract);
        PopeFeeDividendContract = await hre.ethers.getContractAt("PopeFeeDividend", contracts.PopeFeeDividendContract)

        uniswapRouter2Contract = await hre.ethers.getContractAt("IUniswapV2Router02", contracts.uniswapRouter2)

        // await testIDO()
        // await testPledge()
        await testConstellation()

    } catch (err) {
        console.error(err)
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
