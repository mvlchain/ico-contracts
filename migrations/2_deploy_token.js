const MVLPresale = artifacts.require('MVLPresale');
const MVLMainsale = artifacts.require('MVLMainsale');

module.exports = function(deployer) {
  return deployer.deploy(MVLPresale, [
    web3.eth.accounts[1], web3.eth.accounts[2]
  ], 1525348800, 1526040000 /* close time */, 1525521600 /* bonus end time */, 20, 15, 100000000000000000, 50000000000000000000 /*50 eth*/, 1000*1e18,
  240000, web3.eth.accounts[1], 0).then(function() {
    return deployer.deploy(MVLMainsale, [
      web3.eth.accounts[1], web3.eth.accounts[2]
    ], 1526385600, 1527163200 /* close time */, 1526558400 /* bonus end time */, 5, 0, 100000000000000000, 50000000000000000000 /*50 eth*/, 1000*1e18,
    240000, web3.eth.accounts[1], 0);
  });
};
