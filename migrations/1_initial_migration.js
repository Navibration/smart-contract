var NaviCrowdSale = artifacts.require("NaviCrowdSale");
var NaviCoin = artifacts.require("NaviCoin");

module.exports = function(deployer, network, accounts) {  
	deployer.deploy(NaviCoin).then(function() {
		deployer.deploy(NaviCrowdSale, NaviCoin.address)
	});
};