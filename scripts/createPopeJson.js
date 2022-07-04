
const ipfsUrl = "https://gateway.pinata.cloud/ipfs/QmW6aadXq6v62yz9ZEmK95Gn2WSPb5uhpQaRQuuqUZKVGe"

async function main(){
    const fs = require('fs')
    try {
        const len = 120;
        const attrType = "pope";
        for (let i = 1; i <= len; i++) {
            let content = {
                "name": "Pope #" + i,
                "image": `${ipfsUrl}/1.png`,
                "attributes": [
                    {
                        "trait_type": "Type",
                        "value": attrType
                    }
                ]
            }
            fs.writeFileSync("./resources/pope/" + i, JSON.stringify(content,null,'\t'))
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