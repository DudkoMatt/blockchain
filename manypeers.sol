pragma solidity ^0.4.24;

library SafeMat {
    function add(uint256 _first, uint256 _second) internal pure returns(uint256)
    {
        uint256 rslt = _first + _second; require( rslt >= _first);
        return rslt;
    }
    function sub(uint256 _, uint256 __) internal pure returns(uint256)
    {
        require(_ >= __);
        return _ - __;
    }
    function mul(uint256 _, uint256 __) internal pure returns(uint256)
    {
        uint256 rslt = _ * __; require(_ == 0 || rslt / _ == __);
    }
    function div(uint256 _, uint256 __) internal pure returns(uint256)
    {
        return _ / __;
    }
}

contract Owner {
    address public owner;
    constructor() public
    { owner = msg.sender; }

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    function changeOwnership(address _) public onlyOwner{ owner = _; }

    function destroy() internal onlyOwner
    {
        selfdestruct(0);
    }
}

contract TokenInterface {
    function metadataOf(uint _tokenId) public view returns (uint8 Ox, uint8 Oy, uint8 red, uint8 green, uint8 blue, uint8 weather, uint8 shape, address boxOwner, bool isFree);
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable;
}

contract multiToken is Owner {
    
    event NewDealCreated(address indexed _from, address indexed _to, uint indexed _tokenId, uint _price, address _contractAddress);
    
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
    
    struct Token {
        uint price;
        address Owner;
        bool isSold;
    }
    
    Deal[] allDeals;
    
    uint[] getAllTokens;
    mapping (uint => Token) public getTokenById;

    address ERC721Address;

    constructor (address _address) public {
        ERC721Address = _address;
    }

    modifier onlyERC721() {
        require(msg.sender == ERC721Address);
        _;
    }
    
    function getAllTokensOnMarket() public view returns (uint[], uint) {
        uint[] memory res = new uint[](getAllTokens.length);
        uint counter = 0;
        for(uint i = 0; i < getAllTokens.length; i++){
            if(!getTokenById[i].isSold){
                res[counter++] = i;
            }
        }
        return (res, counter);
        
    }


    function addToken(uint _id, address _owner, uint _price) public onlyERC721
    {
        if(getTokenById[_id].isSold){
            readdToken(_id);
        } else {
            getTokenById[_id] = Token(_price, _owner, false);
            getAllTokens.push(_id);
        }
        
    }
    
    function readdToken(uint _id) private {
        getTokenById[_id].isSold = false;
        
    }
    
    
    function removeToken(uint _id) public
    {
        require(msg.sender == getTokenById[_id].Owner || msg.sender == address(this));
        getTokenById[_id].isSold = true;
    }
    
    function buyToken(uint _id) public payable
    {
        require(getTokenById[_id].price <= msg.value);
        removeToken(_id);
        (getTokenById[_id].Owner).transfer(getTokenById[_id].price);
        (msg.sender).transfer(msg.value - getTokenById[_id].price);
        TokenInterface(ERC721Address).transferFrom(address(this), msg.sender, _id);
    }
    

    function bytesToAddress(bytes a) public pure returns(address){
        bytes20 result = bytes20(0);
        for(uint i = 19; i > 0; i--){
            result = (result | (bytes20(a[i]))) >> 8;
        }
        return address(result | a[0]);
    }
    
    
    function onERC721Received (address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4)  {
        
        require(msg.sender == ERC721Address);
        
        if(keccak256('') == keccak256(_data)){
            addToken(_tokenId, _from, getTokenById[_tokenId].price);
            TokenInterface(ERC721Address).transferFrom(_from, address(this), _tokenId);
        } else {
            Deal newDeal = new Deal(_from, bytesToAddress(_data), _tokenId, getTokenById[_tokenId].price, ERC721Address);
            TokenInterface(ERC721Address).transferFrom(_from, newDeal, _tokenId);
            emit NewDealCreated(_from, bytesToAddress(_data), _tokenId, getTokenById[_tokenId].price, newDeal);
        }
        return ERC721_RECEIVED;
        
    }
    
    function getMetadataOf(uint _id) public view returns (uint8 Ox, uint8 Oy, uint8 red, uint8 green, uint8 blue, uint8 weather, uint8 shape, address boxOwner, bool isFree) {
        return TokenInterface(ERC721Address).metadataOf(_id);
    }
    
    function priceOf(uint _id) public view returns (uint) {
        if(getTokenById[_id].isSold) return 0;
        return getTokenById[_id].price;
    }
    
    function ownerOf (uint _id) public view returns (address) {
        if(getTokenById[_id].isSold) return address(0);
        return getTokenById[_id].Owner;
    }
    
}


contract Deal {
    
    address ERC721Address;
    
    address public owner;
    address public buyer;
    uint public tokenId;
    uint public price;
    
    bool active = true;
    
    constructor (address _owner, address _to, uint _tokenId, uint _price, address _erc721) public {
        owner = _owner;
        buyer = _to;
        tokenId = _tokenId;
        price = _price;
        ERC721Address = _erc721;
    }
    
    function buyToken() public payable {
        require(active);
        active = false;
        address flag = address(0);
        (,,,,,,,flag,) = TokenInterface(ERC721Address).metadataOf(tokenId);
        require(msg.sender == buyer && msg.value >= price && flag == address(this));
        (msg.sender).transfer(msg.value - price);
        owner.transfer(price);
        TokenInterface(ERC721Address).transferFrom(address(this), buyer, tokenId);
    }
    
    function cancelTransaction() public {
        require(msg.sender == owner || msg.sender == buyer);
        active = false;
        TokenInterface(ERC721Address).transferFrom(address(this), owner, tokenId);
    }
    
}

