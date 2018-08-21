pragma solidity ^0.4.24;

library SafeMath {



  /**

  * @dev Multiplies two numbers, reverts on overflow.

  */

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {

    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

    // benefit is lost if 'b' is also tested.

    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

    if (_a == 0) {

      return 0;

    }



    uint256 c = _a * _b;

    require(c / _a == _b);



    return c;

  }



  /**

  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.

  */

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {

    require(_b > 0); // Solidity only automatically asserts when dividing by 0

    uint256 c = _a / _b;

    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold



    return c;

  }



  /**

  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).

  */

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {

    require(_b <= _a);

    uint256 c = _a - _b;



    return c;

  }



  /**

  * @dev Adds two numbers, reverts on overflow.

  */

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {

    uint256 c = _a + _b;

    require(c >= _a);



    return c;

  }



  /**

  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),

  * reverts when dividing by zero.

  */

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b != 0);

    return a % b;

  }

}

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable;
  
  function transferFrom(address _from, address _to, uint256 _tokenId) public payable;
  
  function transfer(address _to, uint256 _tokenId) public;
  
  function approve(address _to, uint256 _tokenId) public;
  
  // function setApprovalForAll(address _operator) public;
  
  function getApproved() public view returns (address);
  
  // function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  // function takeOwnership(uint256 _tokenId) public;
  
}

contract Ownable {

  address public owner;
  
  event OwnershipRenounced(address indexed previousOwner);

  event OwnershipTransferred(

    address indexed previousOwner,

    address indexed newOwner

  );
  
  constructor() public {

    owner = msg.sender;

  }
  
  modifier onlyOwner() {

    require(msg.sender == owner);

    _;

  }

  function renounceOwnership() public onlyOwner {

    emit OwnershipRenounced(owner);

    owner = address(0);

  }
  
  function transferOwnership(address _newOwner) public onlyOwner {

    _transferOwnership(_newOwner);

  }

  function _transferOwnership(address _newOwner) internal {

    require(_newOwner != address(0));

    emit OwnershipTransferred(owner, _newOwner);

    owner = _newOwner;

  }

}

contract SafeTransferInterface{
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
    function addToken(uint _id, address _owner, uint _price) public;
}

contract createBoxes is Ownable {
    
    using SafeMath for uint;
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
    
    struct Box {
        uint8 Ox;
        uint8 Oy;
        uint8 red;
        uint8 green;
        uint8 blue;
        uint8 weather;
        uint8 shape;
        
        uint value;
        //uint id;
        //string description;

    }
    
    
    Box[] public boxes;
    mapping (uint => address) public ownerOf;
    mapping (address => uint) public balanceOf;
    
    mapping (uint => address) public getApproved;
    
    uint randNonce = 0;
    
    uint8 public width;
    uint8 public height;
    
    
    //ToDo
    //mapping (address => uint) tokenPrice;
    // mapping (address => uint) ownerBalance;
    
    address public market;
    address public transferToSomeoneContract;
    bool firstTime = true;
    // address approvedForAll = address(0);
    
    modifier onlyOwnerOf(uint _tokenId) {
        require(msg.sender == ownerOf[_tokenId]);
        _;
    }
    
    function totalBalance() public view returns(uint) {
        return boxes.length + 1;
    }
    
    function randMod(uint _modulus) internal returns(uint) {
        randNonce = randNonce.add(1);
        return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % _modulus;
    }
    

    constructor (uint8 _x, uint8 _y) public {
        //uint k = 0;
        width = _x;
        height = _y;
        for(uint8 i = 0; i < _x; i++){
            for(uint8 j = 0; j < _y; j++){
                Box memory temp = Box(i, j, 0,0,0, uint8(randMod(7)), uint8(randMod(7)), 0.000001 ether);
                ownerOf[boxes.push(temp)-1] = msg.sender;
                balanceOf[msg.sender] = balanceOf[msg.sender].add(1);
            }
        }
    }
    
    
    function generateRowAbove() public onlyOwner {
        for(uint8 i = 0; i < width; i++){
            safeTransferFrom(address(this), market, boxes.push(Box(i, height, 0,0,0, uint8(randMod(7)), uint8(randMod(7)), 0.000001 ether)));
        }
        height++;
    }
    
    
    function generateRowRigth() public onlyOwner {
        for(uint8 i = 0; i < height; i++){
            safeTransferFrom(address(this), market, boxes.push(Box(width, i, 0,0,0, uint8(randMod(7)), uint8(randMod(7)), 0.000001 ether)));
        }
        width++;
    }
    
    function changePrice(uint _tokenId, uint _price) public onlyOwnerOf(_tokenId) {
        boxes[_tokenId].value = _price;
    }

    function setAddressOfMarket(address _address) public onlyOwner {
        require(firstTime);
        market = _address;
        for(uint i = 0; i < boxes.length; i++){
            require(SafeTransferInterface(market).onERC721Received(market, msg.sender, i, "") == ERC721_RECEIVED);
        }
        firstTime = false;
    }
    
    
    
    function metadataOf(uint _tokenId) public view returns (uint8 Ox, uint8 Oy, uint8 red, uint8 green, uint8 blue, uint8 weather, uint8 shape, address boxOwner, bool isFree) {
        Ox = boxes[_tokenId].Ox;
        Oy = boxes[_tokenId].Oy;
        red = boxes[_tokenId].red;
        green = boxes[_tokenId].green;
        blue = boxes[_tokenId].blue;
        weather = boxes[_tokenId].weather;
        shape = boxes[_tokenId].shape;
        boxOwner = ownerOf[_tokenId];
        isFree = (ownerOf[_tokenId] == address(0));
    }

   
   function getTokensOfUser(address _userId) public view returns (uint[] memory result){
       result = new uint[](balanceOf[_userId]);
       uint counter = 0;
       for(uint i = 0; i < boxes.length; i++){
           if(_userId == ownerOf[i]){
               result[counter] = i;
               counter++;
           }
       }
   }
   
   function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
      safeTransferFrom(_from,_to, _tokenId, "");
  }  
  
  

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public {
      require(msg.sender == ownerOf[_tokenId] || msg.sender == getApproved[_tokenId]);
      getApproved[_tokenId] = _to;
      if(isContract(_to)){
        require(SafeTransferInterface(_to).onERC721Received(msg.sender, _from, _tokenId, data) == ERC721_RECEIVED);
      } else {
          transferFrom(_from, _to, _tokenId);
      }
  }
  
  
  function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
      require(msg.sender == ownerOf[_tokenId] || getApproved[_tokenId] == msg.sender || msg.sender == address(this) || msg.sender == market);
      ownerOf[_tokenId] = _to;
      balanceOf[_from] = balanceOf[_from].sub(1);
      balanceOf[_to] = balanceOf[_to].add(1);
  }
  
  
  function transfer(address _to, uint256 _tokenId) public {
        require(msg.sender == ownerOf[_tokenId] || getApproved[_tokenId] == msg.sender || msg.sender == address(this) || msg.sender == market);
        ownerOf[_tokenId] = _to;
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(1);
        balanceOf[_to] = balanceOf[_to].add(1);
  }
  
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
      getApproved[_tokenId] = _to;
  }
  
  
  function isContract(address _account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(_account) }
    return size > 0;
  }
  
 
}


