// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IERC20Token.sol";

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
}
 
//get  art with specific id
function getSpecificArt(uint _index) public view returns(artInfo memory){
    return listedArts[_index];
}

//Buy art 
function buyArt(uint _index) public payable {
    artInfo memory art = listedArts[_index];
    require(msg.sender != art.owner, "You are already the owner");

    require(
        IERC20Token(cUsdTokenAddress).allowance(msg.sender, address(this)) >= art.price,
        "You have not approved this contract to spend your cUSD tokens"
    );

    require(
        IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            art.owner,
            art.price
        ),
        "Transfer failed."
    );
    purchasedArts[msg.sender].push(
        purchasedArt(
            art.owner,
            art.name,
            art.ImgUrl,
            block.timestamp,
            art.price,
            art.email
        )
    );
    art.owner = payable(msg.sender);
}

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
function EditPrice(uint _index, uint _price) public {
    require(_price > 0,"Price can not be zero");
    listedArts[_index].price = _price;
}

//delete art from store
function deleteArt(uint _index) public {
    delete listedArts[_index];
}


}
