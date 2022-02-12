const basePool = artifacts.require("BasePool");
const constants = require("../app/src/utils/constants");

const {
    BN,           // Big Number support
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

// 1 TICKET to 1 DAI, minimum is 1 DAI

const TICKET_PRICE_1 = new BN(web3.utils.toWei("1", "ether"));
const TICKET_PRICE_3 = new BN(web3.utils.toWei("3", "ether"));
const TICKET_PRICE_5 = new BN(web3.utils.toWei("5", "ether"));
const TICKET_PRICE_7 = new BN(web3.utils.toWei("7", "ether"));
const TICKET_PRICE_10 = new BN(web3.utils.toWei("10", "ether"));
const TICKET_PRICE_20 = new BN(web3.utils.toWei("20", "ether"));

let totalDeposit = new BN(0);

contract("BasePool-SumTree", ([_, _user1, _user2, _user3, _user4, _user5]) => {
    // given
    before(async () => { 
        this.instance = await basePool.deployed();
    });

    it("should open the first draw of ID 1", async() => {
        const receipt = await this.instance.openDraw(constants.SECRET_HASH, {
            from: _
        });
        expectEvent(receipt, "Opened", {
            drawId: new BN(1),
            secretHash: constants.SECRET_HASH
        })
    })
})