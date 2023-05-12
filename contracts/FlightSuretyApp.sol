pragma solidity ^0.8.00;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    

    // Blocks all state changes throughout the contract if false
    bool private operational = true;                                    


    FlightSuretyData  flightSuretyData ;
 
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
         // Modify to call data contract's status
        require(true, "Contract is currently not operational");  
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

    modifier requireIsAirlineFunded()
    {        
        require(flightSuretyData.isAirlineFunded(msg.sender), "Caller is not a Funded Airline");  
        _; 
    }
    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address dataContract)  public 
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

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
    *
    */   
    function registerAirline
                            ( address airlineAddress  
                            )
                            external   
                            requireIsOperational                          
                            requireIsAirlineFunded 
                            returns(bool success)
    {
        
        //Check airline is already registered 
        require(!flightSuretyData.isAirlineRegistered(airlineAddress), "Airline is already registered.");
        int256 voteCount = flightSuretyData.counfOAfAirlinesRegistered();
        // Get the count of airlines already registered
        // If the number is above 4 , add the airline to the queue
        // Else check if the caller is already registered.  If caller/owner is not registered, then fail the registration.


        if (voteCount >= 4){
            //Put Airline in Pending Register to wait for votes to be registered
            success = flightSuretyData.addToVoting(airlineAddress , msg.sender);
            return success;
        }else {
            //Only existing airline may register a new airline until there are at least FOUR airlines registered
            if(voteCount <= 2){
                require(flightSuretyData.isAirlineRegistered(msg.sender), "Caller is not eligible to register ");
                flightSuretyData.registerAirline(airlineAddress);
                return true;
            } else {
                flightSuretyData.registerAirline(airlineAddress);
                return true;
            }
        }
    }

    
    function fundAirline() external payable
     requireIsOperational   returns(bool success) {
       require(flightSuretyData.isAirlineRegistered(msg.sender), "Airline is not registered");
       return  flightSuretyData.fund(msg.value, msg.sender);

    }

   /**
    * @dev Register a future flight for insuring.
    *
    */  
   function registerFlight(uint256 updatedTimeStamp, string memory number , address airline)
        external
        requireIsOperational
        requireIsAirlineFunded
        returns (bool)
    {
        //bytes32 key = getFlightKey(airline, number, updatedTimeStamp);
        flightSuretyData.registerFlight(
            number,
            airline,
            updatedTimeStamp);
        //require(result, "Failed to register flight");
        return true;
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                pure
    {
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        ResponseInfo storage responseInfo = oracleResponses[key];                                         
        responseInfo.requester = msg.sender;
        responseInfo.isOpen = true;                                            

        emit OracleRequest(index, airline, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;


    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string memory flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || 
        (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function getAirline()                        
                        view
                        external
                        returns(bool,bool,uint256 )  {
        
        return (flightSuretyData.getAirline());
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

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

     function buy(string memory flight,uint256 updatedTimestamp )
        public
        payable
        requireIsOperational        
    {
         payable (address(flightSuretyData)).transfer(msg.value); 
         flightSuretyData.buy(flight, msg.sender, msg.value,updatedTimestamp);
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

 

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 departureTime,
        uint8 status
    );

    event OracleReport(
        address airline,
        string flight,
        uint256 departureTime,
        uint8 status
    );

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(
        uint8 index,
        address airline,
        string flight,
        uint256 departureTime
    );

       function registerOracle() external payable requireIsOperational {
        // Require registration fee        

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

   // endregion

}   

 abstract contract FlightSuretyData {
            function registerAirline(address airlineAddress) virtual  external;
            function isAirlineRegistered(address airlineAddress) virtual external returns(bool);
            function isAirlineFunded(address airlineAddress) virtual external returns(bool);
            function counfOAfAirlinesRegistered() virtual external returns(int256);
            function addToVoting(address airlineAddress ,address sender  )  virtual external returns(bool);
            function fund(uint256 amount, address airline)  virtual external returns(bool);
            function getAirline() virtual view external returns(bool,bool,uint256 );
            function registerFlight(string memory flightNumber, address airline, uint256 updatedTimestamp) virtual  external ;
            function buy(string memory flightNumber, address passenger, uint256 amount,uint256  updatedTimestamp)  virtual  external ;
}