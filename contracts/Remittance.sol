pragma solidity ^0.4.21;

contract Remittance {
    
    /* Data Structure to store individual payment requests */
    struct RemittanceStruct {
    uint etherValue;
    address owner;
    address exchange;
    bytes32 puzzle;
    uint  creationBlock;
    uint paymentDuration;
   }

   bool isPaused = false;
   uint maxDuration = 100;
   address contractOwner;
   mapping(bytes32=>RemittanceStruct) public payments;
   
   /* Events */ 
   event LogRemittance(address indexed owner,address indexed exchange, bytes32 puzzle,uint value,uint duration);
   event LogPayment(address indexed owner, address indexed exchange, bytes32 paymentHash, uint value);
   event LogKill(address indexed owner);
   
   /* Modifiers */
   modifier onlyOwner {
       require(msg.sender == contractOwner);
       _;
   }
   modifier isContractActive {
       require(!isPaused);
       _;
   }
  
  /* Constructor - Storing the Contract Owner details. Only 
  Contract Owner can pause/unpause this contract */
  constructor() public {
      contractOwner = msg.sender;
  } 
   
  /* createRemittance - Anyone can create new Remittance request. msg.sender will be the payer. 
      @params : exchange    - Exchange through which payee is getting paid.
                paymentHash - Hash of exchange address and receiver's OTP generated off-chain.
                puzzle      - A puzzle which exchange and payee should resolve to open this payment
                duration    - defines for how many blocks (from current block) will the payment be available
  */ 
  function createRemittance(address exchange, bytes32 paymentHash, bytes32 puzzle, uint duration) public payable
            isContractActive {
        require(paymentHash != 0);
        require((payments[paymentHash].etherValue) == 0);
        require(duration <= maxDuration);
        payments[paymentHash].exchange = exchange;
        payments[paymentHash].creationBlock = block.number;
        payments[paymentHash].paymentDuration= duration;
        payments[paymentHash].owner = msg.sender;
        payments[paymentHash].etherValue = msg.value;
        payments[paymentHash].puzzle = puzzle;
        emit LogRemittance(msg.sender, exchange, puzzle, msg.value, duration);
    }
    
  /* payRemittance - Exchange will pass on their OTP along with the payee's OTP to reeive a payment. 
     @params : paymentHash   - Hash of exchange address and receiver's OTP generated off-chain..
               exchangeOTP   - OTP received by the exchange.
               receiverOTP   - OTP received by the payee.
  */ 
  function payRemittance (bytes32 paymentHash, bytes32 exchangeOTP, bytes32 receiverOTP) public isContractActive{
        require(paymentHash!= 0);
        bytes32 passCode = keccak256(exchangeOTP,receiverOTP);
        require(payments[paymentHash].puzzle == passCode);
        require(payments[paymentHash].paymentDuration >= (block.number - payments[paymentHash].creationBlock));
        require(payments[paymentHash].etherValue > 0);
        require(payments[paymentHash].exchange == msg.sender);
        uint etherAvailable = payments[paymentHash].etherValue;
        payments[paymentHash].etherValue = 0;
        msg.sender.transfer(etherAvailable);
        emit LogPayment(payments[paymentHash].owner,msg.sender,paymentHash,etherAvailable);
  }
    
  /* pauseRemittanceContract - Contract Owner can invoke this function to pause the contract. */
  function pauseRemittanceContract() public onlyOwner{
      isPaused = true;
  }   
  
   /* resumeRemittanceContract - Contract Owner can invoke this function to resume the contract. */
  function resumeRemittanceContract() public onlyOwner{
      isPaused = false;
  } 
  
  /* generatePuzzle - This function will be used internally by the contract (to validate
                      the puzzle) as well as from the User side application (to generate
                      the puzzle) */
    function generatePuzzle(bytes32 exchangeOTP, bytes32 receiverOTP) pure returns(bytes32) {
        return (keccak256(exchangeOTP,receiverOTP));
  }
  
}

