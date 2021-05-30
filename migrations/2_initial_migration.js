const Migrations = artifacts.require("Mafia");
const MC = artifacts.require("MafiaCookies");

module.exports = async function (deployer) {
  await deployer.deploy(MC);
  const token = await MC.deployed();
  await deployer.deploy(Migrations, token.address);
};