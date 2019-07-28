# Kafur



##  Introduction
Kafur is a decentralized automobile insurance that runs on top of the Hedera graphchain. Users can register to request insurance coverage based on an investment fund associated with a token that provides necessary liquidity

## Participants
The automobile insurance consists of:
 
Owner: user who sets the conditions under which a complaint can be lodged.

Subscribers: users who purchase protection to receive a service for free if a series of conditions verifiable by the conditions of the holder is met.

Examiners: who verifies the complaints reported by the subscribers and their validity in order to request the requested service.

Investors: individuals or companies that bet on the performance of the funds and receive dividends when they make profits.

Service providers: entities that can provide a service when a complaint is approved. (In some types of insurance this may not be necessary and claims can be paid directly to the damaged subscriber)

###  Services

Services are stateless contracts that encapsulate all the business logic of the system.

###  Insurance service

This service manages all the logic for the sale of insurance plans, the control of insured profiles, the mechanism for presenting complaints and assigning examiners to complaints.

###  Investment service

The investment service implements the logic necessary for issuing a token.

Furthermore, the service deals with the division of the fund's profits and the calculation of the amount corresponding to each token holder as a dividend, as follows:

dividend [holder] = balance [holder] * totalDividend / totalTokenSupply

###  persistence

Persistence implements an update function to transfer its information to another instance when it needs to be updated.
Apri in Google Traduttore	
Feedback
Risultati web
Google Traduttore
https://translate.google.it/?hl=it
Il servizio gratuito di Google traduce all'istante parole, frasi e pagine web tra l'italiano e più di 100 altre lingue.
Google Traduttore - App su Google Play
