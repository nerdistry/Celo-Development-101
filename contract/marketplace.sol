// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract  discover_aesthetics{

    //track the number of arts stored
    uint internal listedArtLength;

    //cUSD token address
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;


    //struct to hold art details
    struct artInfo{
        address payable owner;
        string name;
        string ImgUrl;
        string Details;
        string Location;
        uint price;
        string email;
    }


//store purchased arts
struct purchasedArt{
    address From;
    string name;
    string imgUrl;
    uint timestamp;
    uint price;
    string email;
}


//store all the listed arts
mapping(uint => artInfo) internal listedArts;

//store purchased arts
mapping(address => purchasedArt[]) internal purchasedArts;



//modifier for onlyOwner
modifier onlyOwner(uint _index){
    require(msg.sender == listedArts[_index].owner,"You are not authorized");
    _;
}

//event emitted when an art is listed
    event ArtListed(
        address indexed owner,
        string name,
        string ImgUrl,
        string Details,
        string Location,
        uint price,
        string email
    );

     //event emitted when an art is purchased
    event ArtPurchased(
        address indexed buyer,
        string name,
        string imgUrl,
        uint price
    );

mapping(string => bool) internal listedArtwork;


//store  art in the smart contract
function listArt(
    string calldata _name,
    string calldata _ImgUrl,
    string calldata _details,
    string calldata _location,
    uint _price,
    string calldata _email
) public {
    require(bytes(_name).length > 0, "name cannot be empty");
    require(bytes(_ImgUrl).length > 0, "url cannot be empty");
    require(bytes(_details).length > 0, "details cannot be empty");
    require(bytes(_location).length > 0, "location cannot be empty");
    require(bytes(_email).length > 0, "email cannot be empty");
    require(_price > 0, "Price is invalid");
    require(!listedArtwork[_ImgUrl], "Artwork has already been listed");

    listedArtwork[_ImgUrl] = true;
    listedArts[listedArtLength] = artInfo(
        payable(msg.sender),
        _name,
        _ImgUrl,
        _details,
        _location,
        _price,
        _email
        );
        listedArtLength++;

      emit ArtListed(msg.sender, _name, _ImgUrl, _details, _location, _price, _email);

}
 
//get  art with specific id
function getSpecificArt(uint _index) public view returns(artInfo memory){
    return listedArts[_index];
}

//Buy art 
function  buyArt(uint _index) public payable {
    artInfo memory art = listedArts[_index];
    require(msg.sender != art.owner,"You are already the owner");

        art.owner = payable(msg.sender);
        
    require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            art.owner,
            art.price
          ),
          "Transfer failed."
        );
        purchasedArts[msg.sender].push(purchasedArt(
            art.owner,
            art.name,
            art.ImgUrl,
            block.timestamp,
            art.price,
            art.email
        ));

emit ArtPurchased(msg.sender, art.name, art.ImgUrl, art.price);

}

//Retreive art purchased by a specific buyer
function getMyArts() public view returns(purchasedArt[] memory){
    return purchasedArts[msg.sender];
}

//get listed art length
function artLength() public view returns(uint){
    return listedArtLength;
}

//Edit the art price
function EditPrice(uint _index, uint _price) public onlyOwner(_index){
    require(_price > 0,"Price can not be zero");
    listedArts[_index].price = _price;
}

event ArtDeleted(uint indexed index, address owner);

//delete art from store
function deleteArt(uint _index) public onlyOwner(_index){
    require(_index < listedArtLength, "Invalid index");
    delete listedArts[_index];
     emit ArtDeleted(_index, msg.sender);
}

 fallback() external payable {
     revert("No function specified to handle the transaction");
 }



}