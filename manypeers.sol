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
    function metadataOf(uint _tokenId) public view returns (uint8 red, uint8 green, uint8 blue, uint8 weather, uint8 picture, address boxOwner, uint value);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
}

contract multiToken is Owner {
    
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
    
    struct Token {
        uint price;
        address Owner;
        bool isSold;
    }
    
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
        if (msg.sender == getTokenById[_id].Owner){
            getTokenById[_id].isSold = true;
            TokenInterface(ERC721Address).safeTransferFrom(address(this), getTokenById[_id].Owner, _id);
        } else if (msg.sender == address(this)) {
            getTokenById[_id].isSold = true;
        }
    }
    
    function buyToken(uint _id) public payable
    {
        require(getTokenById[_id].price <= msg.value);
        removeToken(_id);
        (getTokenById[_id].Owner).transfer(getTokenById[_id].price);
        (msg.sender).transfer(msg.value - getTokenById[_id].price);
        TokenInterface(ERC721Address).safeTransferFrom(address(this), msg.sender, _id);
    }
    
    /*function updatePrice(uint _tokenId, uint _price) public {
        require(msg.sender == ERC721Address);
        getTokenById[_tokenId].price = _price;
    }*/
    
    function onERC721Received (address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4)  {
        require(msg.sender == ERC721Address);
        addToken(_tokenId, _from, getTokenById[_tokenId].price);
        return ERC721_RECEIVED;
    }
    
    function getMetadataOf(uint _id) public view returns (uint8 red, uint8 green, uint8 blue, uint8 weather, uint8 picture, address boxOwner, uint value) {
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
