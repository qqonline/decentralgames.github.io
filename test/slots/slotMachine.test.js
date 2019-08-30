const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

// grab the abi and bytecode from the compiled smart contract
const { interface, bytecode } = require('../build/SlotMachine.json');

let slotMachine;
let accounts;

beforeEach(async () => {
  accounts = await web3.eth.getAccounts();

  slotMachine = await new web3.eth.Contract(JSON.parse(interface))
    .deploy({ data: bytecode })
    .send({ from: accounts[0], gas: '1000000' });
});

describe('Slot Machine Contract', async () => {
  it('deploys a contract', () => {
    assert.ok(slotMachine.options.address);
  });

  it('adds funds to contract', async () => {
    await slotMachine.methods.addFunds().send({
      from: accounts[0],
      value: web3.utils.toWei('10', 'ether')
    });

    const funds = await slotMachine.methods.funds().call({});

    assert.equal(funds, web3.utils.toWei('10', 'ether'));
  });

  it('sets bet amount and retrieves jackpot amounts', async () => {
    await slotMachine.methods
      .setAmounts(web3.utils.toWei('.01', 'ether'))
      .send({
        from: accounts[0],
        gas: '1000000'
      });

    const amountBet = await slotMachine.methods.amountBet().call({});
    assert.equal(amountBet, web3.utils.toWei('.01', 'ether'));

    const jackpot1 = await slotMachine.methods.jackpot1().call({});
    const amountBet1000 = (amountBet * 1000).toString();
    assert.equal(jackpot1, amountBet1000);
    console.log('jackpot 1: ' + jackpot1);

    const jackpot2 = await slotMachine.methods.jackpot2().call({});
    const amountBet125 = (amountBet * 125).toString();
    assert.equal(jackpot2, amountBet125);
    console.log('jackpot 2: ' + jackpot2);

    const jackpot3 = await slotMachine.methods.jackpot3().call({});
    const amountBet37 = (amountBet * 37.04).toString();
    assert.equal(jackpot3, amountBet37);
    console.log('jackpot 3: ' + jackpot3);

    const jackpot4 = await slotMachine.methods.jackpot4().call({});
    const amountBet15 = (amountBet * 15.63).toString();
    assert.equal(jackpot4, amountBet15);
    console.log('jackpot 4: ' + jackpot4);
  });

  it('allows one account to play', async () => {
    await slotMachine.methods.play('123').send({
      from: accounts[0],
      gas: '1000000',
      value: web3.utils.toWei('0.1', 'ether')
    });

    const numbers = await slotMachine.methods.numbers().call({});
    const winner = await slotMachine.methods.winner().call({});
    const amountWin = await slotMachine.methods.amountWin().call({});

    const amountBet = await slotMachine.methods.amountBet().call({});
    console.log('amount bet: ' + amountBet);

    const jackpot4 = await slotMachine.methods.jackpot4().call({});
    console.log('jackpot 4: ' + jackpot4);

    console.log('numbers: ' + numbers);
    console.log('winner: ' + winner);
    console.log('amount win: ' + amountWin);
  });
});
