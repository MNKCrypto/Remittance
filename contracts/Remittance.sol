pragma solidity ^0.4.21;

contract Remittance {
    
    /* Data Structure to store individual payment requests */
    struct Payment {
    uint etherValue;
    bytes32 puzzle;
    uint  creationBlock;
    uint paymentValidity;
   }
   
   uint maxValidity = 100;
   address contractOwner;
   mapping(bytes32=>Payment) public payments;
   
   /* Events */ 
   event LogRemittance(address indexed owner,address indexed exchange, address indexed receiver, bytes32 puzzle,uint value,uint validity);
   event LogPayment(address indexed owner,address indexed exchange,address indexed receiver, uint value);
   event LogKill(address indexed owner);
   
   /* Modifiers */
   modifier onlyOwner {
       require(msg.sender == contractOwner);
       _;
   }
  
  /* Constructor - Storing the Contract Owner details. Only Contract Owner can kill this contract */
  constructor(address _contractOwner) public {
      contractOwner = _contractOwner;
  } 
   
  /* createRemittance - Anyone can create new Remittance request. msg.sender will be the payer. 
      @params : receiver - Payee who will receive the payment. 
                exchange - Exchange through which payee is getting paid.
                puzzle   - A puzzle which exchange and payee should resolve to open this payment
                validity - defines for how many blocks (from current block) will the payment be available
  */ 
  function createRemittance(address receiver, address exchange, bytes32 puzzle, uint validity) public payable{
        bytes32 paymentHash  = keccak256(receiver,exchange,msg.sender);
        require((payments[paymentHash].etherValue) == 0);
        payments[paymentHash].creationBlock = block.number;
        require(validity <= maxValidity);
        payments[paymentHash].paymentValidity= validity;
        payments[paymentHash].etherValue = msg.value;
        payments[paymentHash].puzzle = puzzle;
        emit LogRemittance(msg.sender,exchange,receiver,puzzle, msg.value,validity);
    }
    
  /* payRemittance - Exchange will pass on their OTP along with the payee's OTP to reeive a payment. 
     @params : paymentSource - Payer for this payment. 
               beneficiary   -  Payee for this payment.
               exchangeOTP   - OTP received by the exchange.
               receiverOTP   - OTP received by the payee.
  */ 
  function payRemittance (address paymentSource,address beneficiary, bytes32 exchangeOTP, bytes32 receiverOTP) public{
        bytes32 paymentHash = keccak256(beneficiary,msg.sender,paymentSource);
        bytes32 passCode = keccak256(exchangeOTP,receiverOTP);
        require(payments[paymentHash].puzzle == passCode);
        uint etherAvailable = payments[paymentHash].etherValue;
        require(payments[paymentHash].paymentValidity >= (block.number - payments[paymentHash].creationBlock));
        require(etherAvailable > 0);
        payments[paymentHash].etherValue = 0;
        msg.sender.transfer(etherAvailable);
        emit LogPayment(paymentSource,msg.sender,beneficiary,etherAvailable);
  }
    
  /* killRemittanceContract - Contract Owner can invoke this function to destroy the contract. */
  function killRemittanceContract() public onlyOwner{
        selfdestruct(msg.sender);
  }    
  
}
