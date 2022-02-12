const Web3 = require('web3');

const ROY = "0x39D95dB2824c069018865824ee6FC0D7639d9359";
const TONY = "0x01725BE700413D34bCC5e961de1d0C777d3A52F4";
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

const SALT   = "0x9994123412341234123412341234123412341234123412341234123412341236";
const SECRET = "0xe661badaee5f9d10f7040797264804abca436db390e775929dc5edfc3e77f661";
const SECRET_HASH = new Web3().utils.soliditySha3(SECRET, SALT);

// MCD contracts info https://changelog.makerdao.com/
// MCD v1.0.4
const DAI_CONTRACT_KOVAN = "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa";

// Compound contracts info at each networks https://compound.finance/docs#guides
// https://github.com/compound-finance/compound-protocol/blob/master/networks/rinkeby.json
const DAI_CONTRACT_RINKEBY = "0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa";

// https://github.com/compound-finance/compound-protocol/blob/master/networks/kovan.json
const cDAI_CONTRACT_KOVAN = "0xe7bc397DBd069fC7d0109C0636d06888bb50668c";

// https://github.com/compound-finance/compound-protocol/blob/master/networks/rinkeby.json
const cDAI_CONTRACT_RINKEBY = "0x6D7F0754FFeb405d23C51CE938289d4835bE3b14";

const DAI_CONTRACT_ROPSTEN = "0x31F42841c2db5173425b5223809CF3A38FEde360";

const cDAI_CONTRACT_ROPSTEN = "0xbc689667C13FB2a04f09272753760E38a95B998C"

// default target network
const DAI_CONTRACT = DAI_CONTRACT_ROPSTEN;
const cDAI_CONTRACT = cDAI_CONTRACT_ROPSTEN;

module.exports = {
    ROY,
    TONY,
    ZERO_ADDRESS,
    SALT,
    SECRET,
    SECRET_HASH,
    DAI_CONTRACT_KOVAN,
    DAI_CONTRACT_RINKEBY,
    cDAI_CONTRACT_KOVAN,
    cDAI_CONTRACT_RINKEBY,
    DAI_CONTRACT,
    cDAI_CONTRACT
}