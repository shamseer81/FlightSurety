import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.appAddress = config.appAddress;

    }

     initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }            
            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    setOperatingStatus(mode,callback) {
        let self = this;
        self.flightSuretyApp.methods
             .setOperatingStatus()
             .call(mode,{ from: self.owner}, callback);
     }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
    async registerAirline(airline, callback) {
        let self = this;

        self.flightSuretyData.methods.authorizeCaller(this.appAddress).send({ from: self.owner}) ;

        let result =  await self.flightSuretyApp.methods
            .registerAirline(airline)
            .send({ from: self.owner}, (error, result) => {
                callback(error);
            });
   
    }

    fundAirline( amount,address, callback) {
        let self = this;
       console.log('config.amount : ' , amount);
       console.log('config.address : ' , address);
       self.flightSuretyData.methods.authorizeCaller(this.appAddress).send({ from: self.owner}, callback) ;
        self.flightSuretyApp.methods
            .fundAirline()
            .send({ from: address, value:amount}, callback)            
    }
   
    async registerFlight(airline, number, callback) {
        let self = this;
        let timestamp = Math.floor(Date.now() / 1000);
        self.flightSuretyData.methods.authorizeCaller(this.appAddress).send({ from: self.owner}) ;

        let result =  await self.flightSuretyData.methods
            .registerFlight(number, airline,timestamp )
            .send({ from: self.owner, gas: '1000000'}, (error, result) => {
                callback(error);
            });
   
    }

}