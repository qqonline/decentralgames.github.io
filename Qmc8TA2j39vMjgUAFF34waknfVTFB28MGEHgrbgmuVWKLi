const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

// create the abi and bytecode at run-time
const { interface, bytecode } = require('../compile');

let decentralotto;
let accounts;

beforeEach(async () => {
  accounts = await web3.eth.getAccounts();

  decentralotto = await new web3.eth.Contract(JSON.parse(interface))
    .deploy({ data: bytecode })
    .send({ from: accounts[0], gas: '1000000' });
});

describe('Lotto Machine Contract', async () => {
  it('deploys a contract', () => {
    assert.ok(decentralotto.options.address);
  });

  it('allows one account to play', async () => {
    await decentralotto.methods.play().send({
      from: accounts[0],
      value: web3.utils.toWei('0.1', 'ether')
    });

    const players = await decentralotto.methods.getPlayers().call({
      from: accounts[0]
    });

    assert.equal(accounts[0], players[0]);
    assert.equal(1, players.length);
  });

  it('allows multiple accounts to play', async () => {
    await decentralotto.methods.play().send({
      from: accounts[0],
      value: web3.utils.toWei('0.1', 'ether')
    });

    await decentralotto.methods.play().send({
      from: accounts[1],
      value: web3.utils.toWei('0.1', 'ether')
    });

    await decentralotto.methods.play().send({
      from: accounts[2],
      value: web3.utils.toWei('0.1', 'ether')
    });

    const players = await decentralotto.methods.getPlayers().call({
      from: accounts[0]
    });

    assert.equal(accounts[0], players[0]);
    assert.equal(accounts[1], players[1]);
    assert.equal(accounts[2], players[2]);
    assert.equal(3, players.length);
  });

  it('requires a minimum amount of ether to play', async () => {
    try {
      await decentralotto.methods.play().send({
        from: accounts[0],
        value: 200
      });
      assert(false);
    } catch (err) {
      assert(err);
    }
  });

  it('only CEO/manager can call pickWinner()', async () => {
    try {
      await decentralotto.methods.pickWinner().send({
        from: accounts[1]
      });
      assert(false);
    } catch (err) {
      assert(err);
    }
  });

  it('sends money to winner and resets the players array', async () => {
    await decentralotto.methods.play().send({
      from: accounts[0],
      value: web3.utils.toWei('2', 'ether')
    });

    const initialBalance = await web3.eth.getBalance(accounts[0]);
    await decentralotto.methods.pickWinner().send({
      from: accounts[0]
    });
    const finalBalance = await web3.eth.getBalance(accounts[0]);
    const difference = finalBalance - initialBalance;

    assert(difference > web3.utils.toWei('1.8', 'ether'));
  });
});
