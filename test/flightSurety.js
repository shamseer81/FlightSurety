
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  beforeEach('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/
/*
  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {
       
      
      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  }); */

  it(' Airline registering and funding ', async () => {
    
    // ARRANGE
    let airline1 = accounts[1];
    let airline2 = accounts[2];
    let airline3 = accounts[3];
    let airline4 = accounts[4];
  

    // ACT
    try {
    
        //await config.flightSuretyApp.fundAirline({ from: accounts[0], value: 10 })
       await config.flightSuretyApp.registerAirline(airline1, {from: accounts[0]});
       result = await config.flightSuretyData.isAirlineRegistered.call(airline1); 
       assert.equal(result, true, " airline1 successfully registered ");
       let airlineRegsitered = await config.flightSuretyData.getAirline({ from: airline1 });
       assert.equal(false, airlineRegsitered[1], " Airline1 not funded ");
        //fund airline
        let amount = web3.utils.toWei("12", "ether");
       await config.flightSuretyData.fund({ from: airline1 , value:10 })
        let airline1Funded  = await config.flightSuretyData.getAirline({ from: airline1 });
       assert.equal(true, airline1Funded[1], " Airline1 funded ");
       assert.equal(10, airline1Funded[2].toNumber(), " Airline1 funded with value 10 "); 
       // Airline 1 should be able to register airline 2
       await config.flightSuretyApp.registerAirline(airline2, {from: airline1});
       result = await config.flightSuretyData.isAirlineRegistered.call(airline2); 
       assert.equal(result, true, " airline2 successfully registered ");
       await config.flightSuretyApp.registerAirline(airline3, {from: airline2});
       
       ;
      // await config.flightSuretyApp.registerAirline(airline4, {from: airline2});
      // assert.equal(result, false, " Since total count 4  ");




      //  await config.flightSuretyApp.registerAirline(airline3, {airline2});
    }
    catch(e) {
      //console.log ('inside exception', e );
      result = await config.flightSuretyData.isAirlineRegistered.call(airline3); 
      assert.equal(result, false, " airline2 is not funded and hence unable to register airline3 ");

    }
       await config.flightSuretyData.fund({ from: airline2 , value:10 })
       await config.flightSuretyApp.registerAirline(airline3, {from: airline2});
       airline3Result = await config.flightSuretyData.getAirline({ from: airline3 });
       //assert.equal(true, airline3[1], " airline3 funded ");
       //assert.equal(10, airline3[2].toNumber(), " airline3 funded with value 10 "); 
       result = await config.flightSuretyData.isAirlineRegistered.call(airline3); 
       assert.equal(result, true, " airline2 is funded and able to register airline3 ") ; 

  });
 
  it(' Multiparty consensus testing ', async () => {
    
    // ARRANGE
    let airline5 = accounts[5];
    let airline6 = accounts[6];
    let airline7 = accounts[7];
    let airline8 = accounts[8];
    let airline9 = accounts[9];

    await config.flightSuretyApp.registerAirline(airline5, {from: accounts[0]});
    result = await config.flightSuretyData.isAirlineRegistered.call(airline5); 
    let count = await config.flightSuretyData.counfOAfAirlinesRegistered();


    await config.flightSuretyApp.registerAirline(airline6, {from: accounts[0]});
    result = await config.flightSuretyData.isAirlineRegistered.call(airline6); 
    count = await config.flightSuretyData.counfOAfAirlinesRegistered();


    await config.flightSuretyApp.registerAirline(airline7, {from: accounts[0]});
    result = await config.flightSuretyData.isAirlineRegistered.call(airline7); 
    count = await config.flightSuretyData.counfOAfAirlinesRegistered();
   
    
    await config.flightSuretyApp.registerAirline(airline8, {from: accounts[0]});
    result = await config.flightSuretyData.isAirlineRegistered.call(airline8); 
    count = await config.flightSuretyData.counfOAfAirlinesRegistered();
      
    assert.equal(result, false, "Multiparty consensus is needed since 4 airlines are registered  ") ; 
    assert.equal(count, 4, " Count of airline 4 "); 

    await config.flightSuretyApp.registerAirline(airline8, {from: accounts[0]});
    result = await config.flightSuretyData.isAirlineRegistered.call(airline8); 
    count = await config.flightSuretyData.counfOAfAirlinesRegistered();
    assert.equal(result, false, "Multiparty consensus is needed since 4 airlines are registered  ") ; 
    assert.equal(count, 4, " Count of airline 4 "); 
   
    await config.flightSuretyData.fund({ from: airline6 , value:10 })
    await config.flightSuretyApp.registerAirline(airline8, {from: accounts[6]});
    result = await config.flightSuretyData.isAirlineRegistered.call(airline8); 
    count = await config.flightSuretyData.counfOAfAirlinesRegistered();

    assert.equal(result, true, "Multiparty consensus reached  ") ; 
    assert.equal(count, 5, " Count of airline incremented by one "); 


  });


});
