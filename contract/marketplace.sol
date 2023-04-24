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


contract Aesthetics{

    event AestheticListed(uint indexed index, address owner, string name, string image, string description, string location, uint price, uint sold);
    event AestheticDeleted(uint indexed index);

    //track the number of  stored
      uint internal listedAestheticLength = 0;

    //cUSD token address
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;


    //struct to hold details
    struct aesthetic{
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint price;
        uint sold;
    }


    //store all the listed 
    mapping(uint => aesthetic) internal listedAesthetics;


    //modifier for onlyOwner
    modifier onlyOwner(uint _index){
        require(msg.sender == listedAesthetics[_index].owner,"You are not authorized");
        _;
    }

    //store  in the smart contract
    function listAesthetic(
        string calldata _name,
        string calldata _image,
        string calldata _description,
        string calldata _location,
        uint _price
    ) public {
        require(bytes(_name).length > 0, "name cannot be empty");
        require(bytes(_image).length > 0, "url cannot be empty");
        require(bytes(_description).length > 0, "details cannot be empty");
        require(bytes(_location).length > 0, "location cannot be empty");
        require(_price > 0, "Price is invalid");

        uint _sold = 0;
        listedAesthetics[listedAestheticLength] = aesthetic(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            _price,
            _sold
            );
            listedAestheticLength++;
            emit AestheticListed(listedAestheticLength, msg.sender, _name, _image, _description, _location, _price, _sold);
    }
    
    //get  with specific id
    function readAesthetic(uint _index) public view returns(
        address payable owner,
        string memory,
        string memory,
        string memory,
        string memory,
        uint,
        uint
    ){
        return 
        (
            listedAesthetics[_index].owner,
            listedAesthetics[_index].name,
            listedAesthetics[_index].image,
            listedAesthetics[_index].description,
            listedAesthetics[_index].location,
            listedAesthetics[_index].price,
            listedAesthetics[_index].sold

        );
    }

    //Buy
    function  buyAesthetic(uint _index) public payable {
        require(_index < listedAestheticLength, "Invalid aesthetic index");
        aesthetic memory _aesthetic = listedAesthetics[_index];
        require(msg.sender != _aesthetic.owner,"You are already the owner");
        require(IERC20Token(cUsdTokenAddress).balanceOf(msg.sender) >= listedAesthetics[_index].price, "Insufficient balance in cUSD token");

        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                _aesthetic.owner,
                _aesthetic.price
            ),
            "Transfer failed."
            );

            // increment the sold amount
            listedAesthetics[_index].sold++;

    }

    //get listed  length
    function aestheticLength() public view returns(uint){
        return listedAestheticLength;
    }

    // delete 
    function deleteAesthetic(uint _index) public onlyOwner(_index) {
        delete listedAesthetics[_index];
        listedAestheticLength--;
        emit AestheticDeleted(_index);
        
    }

    // Edit the price
    function editPrice(uint _index, uint _price) public onlyOwner(_index){
        require(_price > 0,"Price can not be zero");
        listedAesthetics[_index].price = _price;
    }


}
