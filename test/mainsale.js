const {proceedTime, snapshot, revert} = require('./util');
const moment = require('moment');
const chai = require('chai');
const should = chai.should();
chai.use(require('chai-as-promised'));

const MVLMainsale = artifacts.require('MVLMainsale');


contract('MVLMainsale', (accounts) => {
  let mainsale, snapshotId;
  before(async () => {
    // await proceedTime(moment.parseZone('2018-05-15T21:00:01+09:00'));
    mainsale = await MVLMainsale.deployed();

    // make snapshot for reverting time
    snapshotId = await snapshot();
    console.log('snapshotId', snapshotId);
  });

  it("should accept valid amount of ether", async () => {

    const participant1 = accounts[3];
    await web3.eth.sendTransaction({gas: 250000, to: mainsale.address, value: web3.toWei(0.1, 'ether'), from: participant1});
  });

  it("should reject invalid amount of ether (too small)", async () => {
    const participant1 = accounts[4];
    try {
      await web3.eth.sendTransaction({to: mainsale.address, value: web3.toWei(0.05, 'ether'), from: participant1});
    } catch (err) {
      err.message.should.equal('VM Exception while processing transaction: revert');
      // console.log('hello');
    }

    // check contribution, and it should be 0
    const a = await mainsale.getUserContribution(participant1);
    // console.log(a);
    a.toString().should.equal('0');
  });

  it("should reject invalid amount of ether (too large)", async () => {
    const participant1 = accounts[5];
    try {
      await web3.eth.sendTransaction({to: mainsale.address, value: web3.toWei(60, 'ether'), from: participant1});
    } catch (err) {
      err.message.should.equal('VM Exception while processing transaction: revert');
    }
    // check contribution, and it should be 0
    const a = await mainsale.getUserContribution(participant1);
    a.toNumber().should.equal(0);
  });

  it('should accept additional fund from existing participant', async () => {
    const participant = accounts[3];
    await web3.eth.sendTransaction({to: mainsale.address, value: web3.toWei(0.1, 'ether'), from: participant});

    // get user contribution
    const a = await mainsale.getUserContribution(participant);
    a.toNumber().should.equal(+web3.toWei(0.2, 'ether'));

  });

  it("should accept fund, but not exceed", async () => {
    const participant = accounts[5];
    await web3.eth.sendTransaction({gas: 250000, to: mainsale.address, value: web3.toWei(40, 'ether'), from: participant});

    // get user contribution
    const a = await mainsale.getUserContribution(participant);
    a.toNumber().should.equal(+web3.toWei(40, 'ether'));

    try {
      await web3.eth.sendTransaction({to: mainsale.address, value: web3.toWei(20, 'ether'), from: participant});
    } catch (err) {
      err.message.should.equal('VM Exception while processing transaction: revert');
    }

    // get user contribution again
    const b = await mainsale.getUserContribution(participant);
    b.toNumber().should.equal(+web3.toWei(40, 'ether'));
  });

  it("should accept another fund", async () => {
    const participant = accounts[6];
    console.log(web3.fromWei(await web3.eth.getBalance(participant), 'ether').toNumber());
    console.log(moment.unix((await web3.eth.getBlock(web3.eth.blockNumber)).timestamp).format());

    await web3.eth.sendTransaction({gas: 250000, to: mainsale.address, value: web3.toWei(10, 'ether'), from: participant});

    // get user contribution
    const a = await mainsale.getUserContribution(participant);
    a.toNumber().should.equal(+web3.toWei(10, 'ether'));
  });

  it("should apply different bonus rate when 48hours pass", async () => {
    await proceedTime(moment.parseZone('2018-05-17T21:10:10+09:00'));
    const participant = accounts[6];
    console.log(web3.fromWei(await web3.eth.getBalance(participant), 'ether').toNumber());
    console.log(moment.unix((await web3.eth.getBlock(web3.eth.blockNumber)).timestamp).format());

    await web3.eth.sendTransaction({gas: 250000, to: mainsale.address, value: web3.toWei(1, 'ether'), from: participant});

    // get user contribution
    const a = await mainsale.getUserContribution(participant);
    a.toNumber().should.equal(+web3.toWei(11, 'ether'));
  });

  it("should move fund to wallet if ico success", async () => {
    const acc0balance_before = await web3.eth.getBalance(web3.eth.accounts[1]);
    const acc1balance_before = await web3.eth.getBalance(web3.eth.accounts[2]);

    await mainsale.setState(true, {from: web3.eth.accounts[0]});
    await mainsale.close({from: web3.eth.accounts[0]});

    // need to check wallet balance
    const acc0balance_after = await web3.eth.getBalance(web3.eth.accounts[1]);
    const acc1balance_after = await web3.eth.getBalance(web3.eth.accounts[2]);

    const diff0 = acc0balance_after.minus(acc0balance_before);
    const diff1 = acc1balance_after.minus(acc1balance_before);

    (diff0.toNumber() + diff1.toNumber()).should.equal(+web3.toWei(51.2, 'ether'));
  });

  it("should reject fund when it is finished", async () => {
    const participant = accounts[4];

    try {
      await web3.eth.sendTransaction({to: mainsale.address, value: web3.toWei(0.2, 'ether'), from: participant});
    } catch (err) {
      if (err.message !== 'VM Exception while processing transaction: revert') {
        throw err;
      }
      err.message.should.equal('VM Exception while processing transaction: revert');
    }
  });

  it('should calculate participant beneficial', async () => {
    const participant = accounts[3];

    const a = await mainsale.balances(participant);
    const r1 = web3.toBigNumber(240000*1.05);
    const r2 = web3.toBigNumber(240000);

    console.log((await mainsale.getUserContribution(participant)));

    a.toNumber().should.equal(r1.mul(web3.toWei(0.2, 'ether')).toNumber());

    const participant2 = accounts[5];
    const b = await mainsale.balances(participant2);
    b.toNumber().should.equal(r1.mul(web3.toWei(40, 'ether')).toNumber());

    const participant3 = accounts[6];
    console.log((await mainsale.getUserContribution(participant3)));
    const c = await mainsale.balances(participant3);
    console.log(c);
    c.equals(r1.mul(web3.toWei(10, 'ether')).add(web3.toBigNumber(web3.toWei(1, 'ether')).mul(r2))).should.equal(true);
  });

  after(async () => {
    revert(snapshotId);
    const block = await web3.eth.getBlock(web3.eth.blockNumber);
    const cur = moment.unix(block.timestamp);
    console.log('reverted time to', cur.format());
  });
});
