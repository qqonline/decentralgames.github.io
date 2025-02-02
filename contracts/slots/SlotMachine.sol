pragma solidity ^0.4.25;

// Slot Machine Smart Contract ///////////////////////////////////////////////////////////
// Author: Steven Becerra (steve@decentral.games) ////////////////////////////////////////
contract AccessControl {
    address public ceoAddress; // contract's owner and manager address
    address public devAddress; // contract's developer address

    bool public paused = false; // keeps track of whether or not contract is paused

    // AccessControl constructor - sets default executive roles of contract to the sender account
    constructor() public {
        ceoAddress = msg.sender;
        devAddress = msg.sender;
    }

    // access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    // assigns new CEO address - only available to the current CEO
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    // assigns new developer address - only available to the current developer
    function setDev(address _newDev) public {
        require(msg.sender == devAddress);
        require(_newDev != address(0));
        
        devAddress = _newDev;
    }    

    // modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    // modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    // pauses the smart contract - can only be called by the CEO
    function pause() public onlyCEO whenNotPaused {
        paused = true;
    }

    // unpauses the smart contract - can only be called by the CEO
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

contract ERC20Token {
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  function balanceOf(address to) public returns(uint256 balance);
  function transfer(address to, uint tokens) public returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SlotMachine is AccessControl {
    using SafeMath for uint256;
    
    // emit events to server node.js events handler
    event SpinResult(uint256 indexed _number, uint256 indexed _machineID, uint256 indexed _amountWin);
    event NewBalance(uint256 indexed _balance);
    
    uint256 public amountBet = 0; // contract's bet price
    uint256 public jackpot1 = 0; // top jackpot amount
    uint256 public jackpot2 = 0; // second jackpot amount
    uint256 public jackpot3 = 0; // third jackpot amount
    uint256 public jackpot4 = 0; // fourth jackpot amount
    
    uint256[] symbols; // array to hold symbol integer groups
    uint256 public funds = 0; // funds in contract
    uint256 public amountWin = 0; // last winning amount
    uint256 public numbers = 0; // last reels numbers
    uint256 public winner = 0; // winning group symbol
    
    ERC20Token manaToken = ERC20Token(0xDd1B834a483fD754c8021FF0938f69C1d10dA81F);
    
    function play(uint256 _amountBet, uint256 _machineID, uint256 _localhash) public whenNotPaused {
        uint256 amountMANA = manaToken.balanceOf(address(this));
        require(amountMANA >= jackpot1, "Insuficient funds in contract");
        require(_amountBet >= amountBet, "Amount sent is less than bet price");
        
        manaToken.transferFrom(msg.sender, address(this), _amountBet);
        
        // randomly determine number from 0 - 999
        numbers = randomNumber(_localhash) % 1000;
        uint256 number = numbers;
        
        // look-up table defining groups of winning number (symbol) combinations
        symbols = [4, 4, 4, 4, 3, 3, 3, 2, 2, 1];
        winner = symbols[number % 10]; // get symbol for rightmost number

        for (uint256 i = 0; i < 2; i++) {
            number = uint256(number) / 10; // shift numbers to get next symbol

            if (symbols[number % 10] != winner) {
                winner = 0;

                break; // if number not part of the winner group (same symbol) break
            }
        }
        if (winner == 1) {
            amountWin = jackpot1;
        } else if (winner == 2) {
            amountWin = jackpot2;
        } else if (winner == 3) {
            amountWin = jackpot3;
        } else if (winner == 4) {
            amountWin = jackpot4;
        } else {
            amountWin = 0;
        }

        if (amountWin > 0) {
            uint256 contractCut = amountWin.mul(1000).div(10000); // contract owner receives 10% of jackpot
            uint256 playersCut = amountWin.sub(contractCut); // player receives 90% of jackpot
            
            manaToken.transfer(ceoAddress, contractCut); // transfer contract cut to contract owner
            manaToken.transfer(msg.sender, playersCut); // transfer winning amount to player minus contract cut
        }
        
        emit SpinResult(numbers, _machineID, amountWin); // notify server of reels numbers and winning amount if any
    }
    
    function addFunds(uint256 _amountMANA) public onlyCEO {
        require(_amountMANA > 0, "No funds sent");
        
        manaToken.transferFrom(msg.sender, address(this), _amountMANA);
        funds = manaToken.balanceOf(address(this));
        
        emit NewBalance(funds); // notify server of new contract balance
    }
    
    function setAmounts(uint _amountBet) public onlyCEO {
        require(_amountBet > 0, "Amount must be greater than 0");
        
        amountBet = _amountBet;
        jackpot1 = _amountBet.mul(70000).div(100);
        jackpot2 = _amountBet.mul(300).div(100); 
        jackpot3 = _amountBet.mul(200).div(100);
        jackpot4 = _amountBet.mul(150).div(100);
    }
    
    function withdrawFunds(uint256 _amount) public onlyCEO {
        require(_amount <= funds, "Amount more than contract balance");

        if (_amount == 0) {
            _amount = funds;
        } 
        manaToken.transfer(ceoAddress, _amount); // transfer contract funds to contract owner
        funds = manaToken.balanceOf(address(this));
        
        emit NewBalance(funds); // notify server of new contract balance
    }
    
    function randomNumber(uint256 _localhash) private view returns (uint256) {
        uint256 blockNumber = block.number - 1;
        return uint256(keccak256(abi.encodePacked(blockhash(blockNumber), _localhash)));
    }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
