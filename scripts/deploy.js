// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { verify } = require("../utils/verify");
const hre = require("hardhat");

async function main() {
  const deploy = hre.ethers.deployContract;

  const argumentsAIRx = [];
  const AirxHero = await deploy("AirxHero", argumentsAIRx);

  const tx = await AirxHero.waitForDeployment();
  await verify(tx.address, argumentsAIRx);


  const arguments = [5, tx.address]; 
  const BattleGame = await deploy("BattleGame", arguments);
  const tx2 = await BattleGame.waitForDeployment();

  await verify(tx2.target, arguments);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
