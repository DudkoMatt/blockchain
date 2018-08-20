pragma solidity ^0.4.24;

library SafeMat
{
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

contract Owner
{
    address public owner;
    constructor() public
    { owner = msg.sender; }

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    //function changeOwnership(address _) public onlyOwner{ owner = _; }

    function destroy() internal onlyOwner
    {
        selfdestruct(0);
    }
}

contract ERC20
{

    string public constant token = "EarthCoin";
    string public constant symbol = "Ercoin";
    uint public constant digits = 3;

    uint public TotalSupply = 0;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed sender, uint value);

    mapping (address => uint) balances;
    mapping (address => mapping( address => uint)) allowed;

    function balanceOf(address User) public view returns(uint)
    {
        return balances[User];
    }

    function transferTo(address to, uint value) public returns(bool success)
    {
        /* Send user */
        SafeMat.sub(balances[msg.sender], value);
        SafeMat.add(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, uint value) public returns(bool success)
    {
        SafeMat.sub(allowed[from][msg.sender], value);
        SafeMat.add(balances[msg.sender], value);
        emit Transfer(from, msg.sender, value);
        return true;
    }
    function mint(uint newCoin) internal view
    {
        SafeMat.add(TotalSupply, newCoin);
    }
    function allowing(address peer, uint value) public returns(bool success)
    {
        SafeMat.add(allowed[msg.sender][peer], value);
        emit Approval(msg.sender, peer, value);
        return true;
    }
    function allowance(address peer) public view returns(uint)
    {
        return allowed[peer][msg.sender];
    }

}

contract ICO is Owner, ERC20  /* Initial Coin Offering */
{
    uint constant private start = 1534326305;
    uint constant private period = 10;

    event BuyToken(address sender, uint value);

    function getMoney(address sender, uint request) private view onlyOwner returns(bool success)
    {
        SafeMat.add(balances[sender], request);
        return true;
    }
    modifier checkTimeSalling()
    {

        require(now > start && now < start + period*24*60*60);
        _;
    }

    function() external payable /*checkTimeSalling*/
    {
        owner.transfer(msg.value);
        uint tmp = SafeMat.mul(msg.value, 30);
        mint(tmp);
        getMoney(msg.sender, tmp);
        emit BuyToken(msg.sender, msg.value);
    }
    function donate() external payable
    {
        owner.transfer(msg.value);
    }
}



contract TokenInterface {
    function metadataOf(uint _tokenId) public view returns (uint8 Ox, uint8 Oy, uint8 red, uint8 green, uint8 blue, uint8 weather, uint8 shape, address boxOwner, bool isFree);
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable;
}


///@dev Contract for peer to peers communication
contract multiToken is Owner
{
    
    event NewDealCreated(address indexed _from, address indexed _to, uint indexed _tokenId, uint _price, address _contractAddress);
    
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
    
    struct Token
    {
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
        // TokenInterface(_address).firstTimeFunction();
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


    //ToDo: security
    function addToken(uint _id, address _owner, uint _price) public onlyERC721
    {
        
        if(getTokenById[_id].isSold){
            readdToken(_id);
        } else {
            getTokenById[_id] = Token(_price, _owner, false);
            getAllTokens.push(_id);
        }
        
    }
    
    //ToDo: security
    function readdToken(uint _id) public {
        
        getTokenById[_id].isSold = false;
        
    }
    
    
    function removeToken(uint _id) public
    {
        
        getTokenById[_id].isSold = true;
        
        // //getTokenById[_id].isSold = true;
        
        // require(msg.sender == getTokenById[_id].Owner);
        
        // //if(_id >= getAllTokens.length) return;
        
        // bool flag = false;
        
        // for(uint i = 0; i < getAllTokens.length; i++){
        //     //getAllTokens[i] = getAllTokens[i+1];
        //     if(flag){
        //       getAllTokens[i-1] = getAllTokens[i];
        //     }
        //     if(getAllTokens[i] == _id){
        //         flag = true;
        //         break;
        //     } else {
        //         continue;
        //     }
        // }
        
        // delete getAllTokens[getAllTokens.length-1];
        // getAllTokens.length--;
        // delete getTokenById[_id];
        
    }
    
    function buyToken(address _seller, uint _id) public payable
    {
        
        //ToDo: РАСКОММЕНТИРОВАТЬ
        //require(getTokenById[_id].price == msg.value);
        
        
        TokenInterface(ERC721Address).transferFrom(_seller, msg.sender, _id);
        
        
        removeToken(_id);
        
        
        //_seller.transfer(msg.value);
        
        
        
        //getAllTokens[seller][id].isOnSale = false;
    }
    
    
    

    function bytesToAddress(bytes a) public pure returns(address){
        bytes20 result = bytes20(0);
        for(uint i = 19; i > 0; i--){
            result = (result | (bytes20(a[i]))) >> 8;
        }
        return address(result | a[0]);
    }
    
    
    function onERC721Received (address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4)  {
        
        //ToDo: Это будет так работать???
        //require(_operator == ERC721Address);
        
        if(keccak256('') == keccak256(_data)){
            addToken(_tokenId, _from, getTokenById[_tokenId].price);
            TokenInterface(ERC721Address).transferFrom(_from, address(this), _tokenId);
        } else {
            Deal newDeal = new Deal(_from, bytesToAddress(_data), _tokenId, getTokenById[_tokenId].price, ERC721Address);
            TokenInterface(ERC721Address).transferFrom(_from, newDeal, _tokenId);
            emit NewDealCreated(_from, bytesToAddress(_data), _tokenId, getTokenById[_tokenId].price, newDeal);
            allDeals.push(newDeal);
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
        TokenInterface(ERC721Address).transferFrom(address(this), buyer, tokenId);
    }
    
}
