// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { verify } = require("../utils/verify");

async function main() {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const argumentsAIRx = []; 
  const AirxHero = await deploy("AirxHero", {
      from: deployer,
      args: argumentsAIRx,
      log: true,
      waitConfirmations: 1,
  });

  await AirxHero.waitForDeployment();

  await verify(AirxHero.address, argumentsAIRx);

  const arguments = [5, AirxHero.address]; 
  const BattleGame = await deploy("BattleGame", {
      from: deployer,
      args: arguments,
      log: true,
      waitConfirmations: 1,
  });

  await BattleGame.waitForDeployment();

  await verify(BattleGame.address, arguments);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
