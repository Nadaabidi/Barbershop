const BarberShop = artifacts.require("./BarberShop.sol");

module.exports = function (deployer) {
  deployer.deploy(BarberShop);
};