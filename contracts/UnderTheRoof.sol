// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UnderTheRoof is ERC721URIStorage, Ownable {
    // library to use for safe integer overflow avoidance
    using SafeMath for uint256;

    // current token ID
    uint256 private _tokenId;

    // Mapping to store the amount of Ether deposited by each address
    mapping(address => uint256) public deposits;

    // Array to store all depositors' addresses
    address[] public depositors;

    // Mapping to check if an address has already been added to the depositors array
    mapping(address => bool) public isDepositor;

    // structure to save each rental data
    struct Rental {
        uint256 rentPrice;
        address currentRenter;
    }

    // mapping that holds rentals
    mapping(uint256 => Rental) public rentals;

    // Create smart contract
    constructor() ERC721("UnderTheRoof", "UTR") {}

    // Register a company that can be called only by contract owner who deploys it
    function registerProperty(
        address owner,
        string memory tokenURI
    ) external onlyOwner returns (uint256) {
        // increase token ID
        _tokenId++;

        // mint token with the new ID and assign to the owner
        _mint(owner, _tokenId);

        // set token metadata
        _setTokenURI(_tokenId, tokenURI);

        return _tokenId;
    }

    // Payable function to deposit Ether to this contract
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount should be greater than 0");

        // Update the deposits mapping
        deposits[msg.sender] += msg.value;

        // If first-time depositor, add to depositors array
        if (!isDepositor[msg.sender]) {
            depositors.push(msg.sender);
            isDepositor[msg.sender] = true;
        }
    }

    // Sell property to a buyer
    // function checks if the buyer has deposited the sell price before
    // essentially smart contract acts like an escrow
    function sellProperty(
        address payable buyer,
        uint256 tokenId,
        uint256 _amount
    ) external {
        require(msg.sender == ownerOf(tokenId), "Wrong owner");

        // Check if enough deposited by the buyer
        require(deposits[buyer] >= _amount, "Not enough deposited");

        // transfer the NFT
        safeTransferFrom(msg.sender, buyer, tokenId);

        // transfer deposited amount
        address seller = payable(msg.sender);
        payable(seller).transfer(_amount);
    }

    // Who is owner the property?
    function propertyOwner(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    /* Rentals */
    // Create a rental
    function startRenting(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");

        // register NFT for rentals
        // to simplify the case everyone can rent it
        rentals[tokenId] = Rental({
            rentPrice: price,
            currentRenter: address(0)
        });
    }

    // Rent the NFT by providing the ETH amount
    function rentNFT(uint256 tokenId) external payable {
        Rental memory rental = rentals[tokenId];
        require(rental.rentPrice >= msg.value, "Incorrect rent amount");
        require(rental.currentRenter == address(0), "Already rented");

        // Transfer the rent amount to the owner
        address owner = ownerOf(tokenId);
        payable(owner).transfer(msg.value);

        // Set the renter's address
        rentals[tokenId].currentRenter = msg.sender;
    }

    // Return the NFT after renting
    function returnNFT(uint256 tokenId) external {
        require(rentals[tokenId].currentRenter == msg.sender, "Not the renter");
        delete rentals[tokenId].currentRenter;
    }

    // Owner of the NFT can stop renting of the NFT
    function stopRenting(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(rentals[tokenId].currentRenter == address(0), "Not returned");
        delete rentals[tokenId];
    }
}
