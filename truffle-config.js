const HDWalletProvider = require("@truffle/hdwallet-provider");
const path = require("path");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "app/src/contracts"),
  networks: {
    fork: { // default with truffle unbox is 7545, but we can use develop to test changes, ex. truffle migrate --network develop
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      // gasLimit: "0x8000000",
      // gas: 0xfffffffff
    },
    ropsten:{
      provider: () => new HDWalletProvider({
        mnemonic: {
          phrase: process.env.MNENOMIC
        },
        providerOrUrl: "https://ethereum-ropsten-rpc.allthatnode.com/" + process.env.DSRV_API_KEY
      }),
      network_id: 3,
      gas: 3000000,
      gasPrice: 10000000000
    }
  },
  compilers: {
    solc: {
      version: "0.5.16"
    }
  }
};
