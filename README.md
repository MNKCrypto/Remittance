# Remittance
Remittance is an ethereum  based smart contract which allows people to transfer value between any two parties through exchange.

There are three parties involved in the transactions:
* Exchange
* Receiver (or) Payee
* Sender (or) Payer

**Sender**  can create a new payment request by providing the ether available for transfer and a puzzle that both **Receiver** and **Exchange** should solve together to receive the ether.

Puzzle is created for a payment by getting a couple of strings from the **Sender**/**Payer** and we generate **KeccaK256 hash** of those strings to derive this puzzle.  Then these strings are sent to both **Receiver** and **Exchange** as One Time Password.

**Exchange** should then pass on the **OTP** of both **Sender** and **Receiver** along with the **Sender** and **Receiver** address.

The **Contract-Owner** has also option to pause / un-pause this contract any time using **pauseRemittanceContract** / **resumeRemittanceContract** function.





