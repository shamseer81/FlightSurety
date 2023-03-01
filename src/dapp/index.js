
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    
     
        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

              // User-submitted transaction
        DOM.elid('register-airline').addEventListener('click', async () => {
          
            let address = DOM.elid('register-airline-address').value;
                // Write transaction
                contract.registerAirline(address, (error, result) => {
                display('Airline', 'Register Airline', [ { label: 'Airline Status', error: error, value: address } ]);
            });
        })
               // User-submitted transaction
        DOM.elid('fund-airline').addEventListener('click', async () => {
          
                    let amount = DOM.elid('fund-airline-amount').value;
                    let address = DOM.elid('fund-airline-address').value;
                    // Write transaction
                    contract.fundAirline(amount,address, (error, result) => {
                    display('Airline', 'Fund Airline', [ { label: 'Funding amount', error: error, value: amount } ]);
                });
            })

            DOM.elid('register-flight').addEventListener('click', async () => {
          
                let address = DOM.elid('register-flight-airline-address').value;
                let flightNumber = DOM.elid('register-flight-number').value;
                    // Write transaction
                    contract.registerFlight(address,flightNumber, (error, result) => {
                    display('Flight', 'Register Flight', [ { label: 'Status', error: error, value: address } ]);
                });
            })
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







