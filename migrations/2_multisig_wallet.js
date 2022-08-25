const MultisigWallet = artifacts.require("MultisigWallet");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(MultisigWallet, {from: accounts[0]});
};
