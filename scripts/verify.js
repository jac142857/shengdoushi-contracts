const hre = require("hardhat");

async function main(){
    const fs = require('fs')

    try {
        const data = fs.readFileSync('./config.json', 'utf8')
        const verifyArr = JSON.parse(data)
        for (let verifyArrElement of verifyArr) {
            try {
                await hre.run("verify:verify", verifyArrElement)
            }catch (e) {
            }
        }
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