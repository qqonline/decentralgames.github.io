pragma solidity ^0.5.1;

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

contract AccessControl {
    address payable public ceoAddress; // contract's owner and manager address

    // AccessControl constructor - sets default executive roles of contract to the sender account
    constructor() public {
        ceoAddress = msg.sender;
    }

    // access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress, "Only CEO can call this function.");
        _;
    }

    // assigns new CEO address - only available to the current CEO
    function setCEO(address payable _newCEO) public onlyCEO {
        require(_newCEO != address(0), "CEO address is not correct.");
        ceoAddress = _newCEO;
    }
}

contract Pausable is AccessControl {
    bool public paused = false; // keeps track of whether or not contract is paused

    // modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused, "Contract is not paused.");
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

contract Decentralotto is Pausable {
    using SafeMath for uint256;
    
    event PlayerAdded(uint256 _newNumber, address _player, uint256 _jackpot, address _affiliate);
    event WinnerSelected(address _winningPlayer, address payable[] _players, uint256 _jackpot, address _winningAffiliate);
    
    address payable[] public players; // list of players in this game
    address payable[] public affiliates; // list of affiliates
    uint256 public total_tickets_sold; // number of total tickets sold 
    mapping(address => address payable) public playerToAffiliate; // mapping of player to affiliate
    mapping(address => uint256) public ticketsSoldByAffiliate; // mapping of affliates to number of tickets sold
    
    uint256 public ticketPrice = 0.1 ether; // contract's default ticket price
    bool public ticketSale = false; // status of ticket sale
    
    uint256 public jackpotGross = 0; // entire contract amount
    uint256 public jackpotAdjusted = 0; // 95% of gross jackpot


    
    function play(address payable affiliate) public payable whenNotPaused {
        require(ticketSale == true, "Tickets are currently not on sale");
        require(msg.value >= ticketPrice, "Amount sent is less than ticket price");
        require(affiliate != address(0), "Provide affiliate's address");
        
        uint256 playerNumber = players.push(msg.sender) - 1; // add new player to players array
        affiliates.push(affiliate);
        playerToAffiliate[msg.sender] = affiliate;
        ticketsSoldByAffiliate[affiliate] = ticketsSoldByAffiliate[affiliate].add(1);
        total_tickets_sold = total_tickets_sold.add(1);

        jackpotGross = address(this).balance;
        jackpotAdjusted = jackpotGross.mul(5000).div(10000); // winner receives 50% of jackpot
        
        emit PlayerAdded(playerNumber, msg.sender, jackpotAdjusted, affiliate); // notify client of new player and jackpot
    }
    
    function pickWinner(uint256 _timestamp) public onlyCEO {
        require(ticketSale == false, "Tickets are currently on sale");
        uint256 index = randomNumber(_timestamp) % players.length; // randomly determine winner
        
        jackpotGross = address(this).balance;
        uint256 contractCut = jackpotGross.mul(2000).div(10000); // owner receives 20% of jackpot
        uint256 affiliatesCut = jackpotGross.mul(1800).div(10000); // affiliates get 18% of the jackpot
        uint256 winningAffiliateCut = jackpotGross.mul(700).div(10000); // winning affiliate get 7% of the jackpot
        uint256 playersCut = jackpotGross.mul(5000).div(10000); // player receives 50% of jackpot
    
        transferCEOCut(contractCut);

        address payable winningPlayer = players[index];
        winningPlayer.transfer(playersCut);

        address payable winningAffiliate = playerToAffiliate[winningPlayer];

        if (winningAffiliate != address(0)) {
            winningAffiliate.transfer(winningAffiliateCut);
        }

        uint256 i;
        for( i = 0; i < affiliates.length; i++ ) {
            uint256 currentAffiliateCut = (ticketsSoldByAffiliate[affiliates[i]]).mul(affiliatesCut).div(total_tickets_sold);
            affiliates[i].transfer(currentAffiliateCut);
            ticketsSoldByAffiliate[affiliates[i]] = 0;
        }
        
        // notify client of winner and confirm players array and jackpot are empty
        emit WinnerSelected(winningPlayer, players, jackpotGross, winningAffiliate);

        players = new address payable[](0); // players array is now empty
        affiliates = new address payable[](0); // affiliates array is now empty
        jackpotGross = address(this).balance; // the contract balance is now 0 
        jackpotAdjusted = address(this).balance; // the adjusted jackpot is now 0
        total_tickets_sold = 0;
    }
    
    function transferCEOCut(uint256 _contractCut) private {
        ceoAddress.transfer(_contractCut);
    }
    
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getAffiliates() public view returns (address payable[] memory) {
        return affiliates;
    }
    
    function getOwner(uint256 _number) public view returns (address) {
        return players[_number];
    }
    
    function getJackpot() public view returns (uint256) {
        return jackpotAdjusted;
    }
    
    function setTicketPrice(uint _ticketPrice) public whenNotPaused onlyCEO {
        require(ticketSale == false, "Tickets are currently on sale");
        
        ticketPrice = _ticketPrice;
    }
    
    function getTicketPrice() public view returns (uint256) {
        return ticketPrice;
    }
    
    function ticketsOnSale(bool _newState) public whenNotPaused onlyCEO {
        ticketSale = _newState;
    }
    
    function randomNumber(uint256 _timestamp) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, _timestamp, players)));
    }
}
