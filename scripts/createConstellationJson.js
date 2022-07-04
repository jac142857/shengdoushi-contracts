
const ipfsUrl = "https://gateway.pinata.cloud/ipfs/QmUzDmVUaMquNANCckAgaCoYhvCfUVehFwCnxJXZo6vi77"

async function main(){
    const fs = require('fs')
    try {
        const len = 2880;
        const attrType = {
            1: "Aries",
            2: "Taurus",
            3: "Gemini",
            4: "Cancer",
            5: "Leo",
            6: "Virgo",
            7: "Libra",
            8: "Scorpio",
            9: "Sagittarius",
            10: "Capricornus",
            11: "Aquarius",
            12: "Pisces",
        };
        for (let i = 1; i <= len; i++) {
            let content = {
                "name": "Pope #" + i,
                "image": `${ipfsUrl}/${i}.jpg`,
                "attributes": [
                    {
                        "trait_type": "Type",
                        "value": attrType[i % 12]
                    }
                ]
            }
            fs.writeFileSync("./resources/constellation/" + i, JSON.stringify(content,null,'\t'))
        }
    } catch (e) {
        console.log(e)
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });