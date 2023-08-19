// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UnderTheRoof is ERC721URIStorage, Ownable {
    using SafeMath for uint256;

    uint256 private _tokenId;

    // Mapping to store the amount of Ether deposited by each address
    mapping(address => uint256) public deposits;

    // Array to store all depositors' addresses
    address[] public depositors;

    // Mapping to check if an address has already been added to the depositors array
    mapping(address => bool) public isDepositor;

    // Event to log deposits
    event Deposited(address indexed depositor, uint256 amount);

    struct Rental {
        uint256 rentPrice;
        address currentRenter;
    }

    mapping(uint256 => Rental) public rentals;

    constructor() ERC721("UnderTheRoof", "UTR") {}

    function registerProperty(
        address owner,
        string memory tokenURI
    ) external onlyOwner returns (uint256) {
        _tokenId++;
        _mint(owner, _tokenId);
        _setTokenURI(_tokenId, tokenURI);

        return _tokenId;
    }

    // Payable function to deposit Ether
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount should be greater than 0");

        // Update the deposits mapping
        deposits[msg.sender] += msg.value;

        // If first-time depositor, add to depositors array
        if (!isDepositor[msg.sender]) {
            depositors.push(msg.sender);
            isDepositor[msg.sender] = true;
        }

        emit Deposited(msg.sender, msg.value);
    }

    function sellProperty(
        address payable buyer,
        uint256 tokenId,
        uint256 _amount
    ) external {
        require(msg.sender == ownerOf(tokenId), "Wrong owner");
        require(deposits[buyer] == _amount, "Not enough deposited");

        safeTransferFrom(msg.sender, buyer, tokenId);

        require(_amount <= address(msg.sender).balance, "Not enough funds");

        buyer.transfer(_amount);
    }

    function propertyOwner(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    /* Rentals */
    function startRenting(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        rentals[tokenId] = Rental({
            rentPrice: price,
            currentRenter: address(0)
        });
    }

    function rentNFT(uint256 tokenId) external payable {
        Rental memory rental = rentals[tokenId];
        require(rental.rentPrice == msg.value, "Incorrect rent amount");
        require(rental.currentRenter == address(0), "Already rented");

        // Transfer the rent amount to the owner
        address owner = ownerOf(tokenId);
        payable(owner).transfer(msg.value);

        // Set the renter's address
        rentals[tokenId].currentRenter = msg.sender;
    }

    function stopRenting(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(rentals[tokenId].currentRenter == address(0), "Not returned");
        delete rentals[tokenId];
    }

    function returnNFT(uint256 tokenId) external {
        require(rentals[tokenId].currentRenter == msg.sender, "Not the renter");
        delete rentals[tokenId].currentRenter;
    }
}
