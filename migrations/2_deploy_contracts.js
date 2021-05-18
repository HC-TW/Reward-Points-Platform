const RPToken = artifacts.require("RPToken");
const BankLiability = artifacts.require("BankLiability");

module.exports = function(deployer) {
  deployer.deploy(RPToken, "Rewarding Points", "RP");
  deployer.deploy(BankLiability);
};
