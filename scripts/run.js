const main = async() => {
    const [deployer] = await hre.ethers.getSigners();
    const accountBalance = await deployer.getBalance();

    console.log("Deploying contract with account: ", deployer.address);
    console.log("Deployer account balance: ", hre.ethers.utils.formatEther(accountBalance));

    const Token = await hre.ethers.getContractFactory('SGTStaking');
    const portal = await Token.deploy('0x16Df340Bce5920309b6b4A90B8D4d792056F2A40', '0x99ba82E610C7Ed000F2477F7F548dcadEe97a9a3');
    await portal.deployed();

    console.log('Schroyar address: ', portal.address);

};

const runMain = async () => {
    try {
        await main();
    } catch(error) {
        console.error(error);
        process.exit(1);
    }
};

runMain();