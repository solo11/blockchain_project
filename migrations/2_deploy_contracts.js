const MyContract = artifacts.require('PhotoSharingNFT')
module.exports = function (deployer) {
  deployer.deploy(MyContract)
}