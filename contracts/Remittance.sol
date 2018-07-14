pragma solidity ^ 0.4 .21;

contract Remittance {

    /* Data Structure to store individual payment requests */
    struct RemittanceStruct {
        uint etherValue;
        address owner;
        bytes32 puzzle;
        uint maxBlock;
    }

    bool isPaused = false;
    uint maxDuration = 100;
    address contractOwner;
    mapping(bytes32 => RemittanceStruct) public payments;
    mapping(bytes32 => uint1) puzzleUsage;

    /* Events */
    event LogRemittance(address indexed owner, bytes32 puzzle, uint value, uint duration);
    event LogPayment(address indexed owner, address indexed exchange, bytes32 paymentId, uint value);
    event LogPause(bool contractStatus);

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
                  paymentId   - Hash of exchange address and receiver's OTP generated off-chain.
                  puzzle      - A puzzle which exchange and payee should resolve to open this payment
                  duration    - defines for how many blocks (from current block) will the payment be available
    */
    function createRemittance(bytes32 paymentId, bytes32 puzzle, uint duration) public payable
    isContractActive {
        require(paymentId != 0);
	require(puzzleUsage[puzzle] == 0);
        require((payments[paymentId].etherValue) == 0);
        require(duration <= maxDuration);
	puzzleUsage[puzzle] = 1;
        payments[paymentId].maxBlock = block.number + duration;
        payments[paymentId].owner = msg.sender;
        payments[paymentId].etherValue = msg.value;
        payments[paymentId].puzzle = puzzle;
        emit LogRemittance(msg.sender, puzzle, msg.value, duration);
    }

    /* payRemittance - Exchange will pass on their OTP along with the payee's OTP to reeive a payment. 
       @params : exchangeOTP   - OTP received by the exchange.
                 receiverOTP   - OTP received by the payee.
    */
    function payRemittance(bytes32 exchangeOTP, bytes32 receiverOTP) public isContractActive {
        require(exchangeOTP != 0);
        require(receiverOTP != 0);
        bytes32 paymentId = generatePaymentId(receiverOTP);
        require(payments[paymentId].etherValue != 0);
        bytes32 passCode = generatePuzzle(exchangeOTP, receiverOTP);
        require(payments[paymentId].puzzle == passCode);
        require(payments[paymentId].maxBlock >= block.number);
        require(payments[paymentId].etherValue > 0);
        uint etherAvailable = payments[paymentId].etherValue;
        payments[paymentId].etherValue = 0;
        emit LogPayment(payments[paymentId].owner, msg.sender, paymentId, etherAvailable);
        msg.sender.transfer(etherAvailable);
    }

    /* pauseRemittanceContract - Contract Owner can invoke this function to pause the contract. */
    function pauseContract() public onlyOwner {
        isPaused = true;
        emit LogPause(isPaused);
    }

    /* resumeRemittanceContract - Contract Owner can invoke this function to resume the contract. */
    function resumeeContract() public onlyOwner {
        isPaused = false;
        emit LogPause(isPaused);
    }

    /* generatePuzzle - This function will be used internally by the contract (to validate
                        the puzzle) as well as from the User side application (to generate
                        the puzzle) */
    function generatePuzzle(bytes32 exchangeOTP, bytes32 receiverOTP) pure returns(bytes32) {
        return (keccak256(address(this), exchangeOTP, receiverOTP));
    }

    /* generatePaymentId - This function will be used internally by the contract (to validate
                      the paymentId) as well as from the User side application (to validate
                      the paymentId) */
    function generatePaymentId(bytes32 receiverOTP) view returns(bytes32) {
        return (keccak256(msg.sender, receiverOTP));
    }

}
