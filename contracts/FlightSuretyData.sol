pragma solidity ^0.8.00;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    uint8 private constant STATUS_ON_TIME = 10;
    uint8 private constant STATUS_UNKNOWN = 0;
    uint8 private constant STATUS_LATE_AIRLINE = 20;
    uint8 private constant STATUS_LATE_WEATHER = 30;
    uint8 private constant STATUS_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_LATE_OTHER = 50;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    uint256 registeredAirlineCount = 0;

     struct Airline {
        bool isRegistered;
        bool isFunded;    
        uint256 funds;         
    }

   struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;  
    mapping(address => Airline) airlines;
    mapping(address => address[]) private votes;

    mapping(address => uint256) private authorizedCallers;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor (address owner) {
         //Register First Airline
       airlines[msg.sender] = Airline({
            isRegistered: true,
            isFunded: true,
            funds: 0
        });    
        votes[owner].push(msg.sender); 
        contractOwner = msg.sender;
        registeredAirlineCount = registeredAirlineCount + 1;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAirlineRegistered(address addr) {
        require(airlines[addr].isRegistered, "Airline is not registered");
        _;
    }

    modifier requireAirlineFunded(address airline) {
        require(airlines[airline].isFunded, "Calling airline not funded ");
        _;
    }

      modifier requireAuthorizedCaller() {
        require(
            authorizedCallers[msg.sender] == 1,
            "Not from an authorized caller"
        );
        _;
    }

     function authorizeCaller(address addr) external requireContractOwner {
        authorizedCallers[addr] = 1;
    }

    function deauthorizeCaller(address addr) external requireContractOwner {
        delete authorizedCallers[addr];
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        require(mode != operational, "New status must be different from existing status");
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (  address airlineAddr 
                            )
                            public
                            requireIsOperational
                            requireAuthorizedCaller
                            
    {
        airlines[airlineAddr] = Airline({
            isRegistered: true,
            isFunded: false,
            funds: 0
        });
        registeredAirlineCount = registeredAirlineCount + 1;

    }

     function isAirlineRegistered
                    (
                        address airlineAddress
                    )
                    external
                    view                    
                    returns(bool)
    {       
        return (airlines[airlineAddress].isRegistered);
    }

    function counfOAfAirlinesRegistered()  
    external view returns(uint256){
        return registeredAirlineCount;
    }

    function addToVoting(address airlineAddress , address sender)  virtual external returns(bool) {
        bool isAllreadyVoted = false;
        //Check if the airline already done the voting for this new airline
        for (uint256 i = 0; i < votes[airlineAddress].length; i++) {
            if (votes[airlineAddress][i] == sender) {
                isAllreadyVoted = true;
                break;
            }
        }
        require(!isAllreadyVoted, "This airline has already voted");
        votes[airlineAddress].push(sender);
        if (votes[airlineAddress].length >= registeredAirlineCount.div(2)) {
            registerAirline(airlineAddress);
            return true;
        } else {
            return false;
        }


    }

   function addressesVoted(address airline)  
        external view returns(address [] memory ){
        return votes[airline];
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund (  )
                            public
                            payable
                            requireIsOperational
                            requireAirlineRegistered(msg.sender)
    {
        require(msg.value >= 10); 

        airlines[msg.sender].funds += msg.value;

        airlines[msg.sender].isFunded = true;
    }

      function isAirlineFunded
                    (
                        address airlineAddress
                    )
                    external
                    view
                    returns(bool)
    {       
        return (airlines[airlineAddress].isFunded);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

     function getAirline()
                        view
                        external
                        returns(bool,bool,uint256 )  {
        Airline memory temp =  airlines[msg.sender];
        return (temp.isRegistered,temp.isFunded,temp.funds);
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() 
                            external 
                            payable 
    {
        fund();
    }


}

