pragma solidity ^0.4.24;

contract TokenInterface {
    function metadataOf(uint _tokenId) public view returns (uint8 red, uint8 green, uint8 blue, uint8 weather, uint8 picture, address boxOwner, uint value);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
    
}

contract Trade {
    
    event NewDealCreated(address indexed _from, address indexed _to, uint indexed _tokenId, uint _price, address _contractAddress);
    
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
    
    address ERC721Address;
    
    constructor (address _address) public {
        ERC721Address = _address;
    }
    
    function bytesToAddress(bytes a) public pure returns(address){
        bytes20 result = bytes20(0);
        for(uint i = 19; i > 0; i--){
            result = (result | (bytes20(a[i]))) >> 8;
        }
        return address(result | a[0]);
    }
    
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4){
        require(msg.sender == ERC721Address);
        
        uint val;
        (,,,,,,val) = TokenInterface(ERC721Address).metadataOf(_tokenId);
        
        Deal newDeal = new Deal(_from, bytesToAddress(_data), _tokenId, val, ERC721Address);
        TokenInterface(ERC721Address).safeTransferFrom(address(this), newDeal, _tokenId);
        
        require(Deal(newDeal).onERC721Received(_operator, _from, _tokenId, _data) == ERC721_RECEIVED);
        
        emit NewDealCreated(_from, bytesToAddress(_data), _tokenId, val, newDeal);
        
        return ERC721_RECEIVED;
    }
}

contract Deal {
    
    address ERC721Address;
    
    address public owner;
    address public buyer;
    uint public tokenId;
    uint public price;
    
    bool public active = true;
    
    constructor (address _owner, address _to, uint _tokenId, uint _price, address _erc721) public {
        owner = _owner;
        buyer = _to;
        tokenId = _tokenId;
        price = _price;
        ERC721Address = _erc721;
    }
    
    function buyToken() public payable {
        require(msg.sender == buyer && msg.value == price);
        owner.transfer(msg.value);
        TokenInterface(ERC721Address).safeTransferFrom(owner, buyer, tokenId);
        active = false;
    }
    
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4){
        return 0x150b7a02;
    }
    
    function cancelTransaction() public {
        require(msg.sender == owner || msg.sender == buyer);
        active = false;
        TokenInterface(ERC721Address).safeTransferFrom(address(this), owner, tokenId);
    }
}
