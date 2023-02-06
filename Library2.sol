// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Library is Ownable {

    struct Book {
        bool firstAdd;
        uint32 availableCopies;     
        string title; 
        address[] borrowingHistory;
        mapping(address => bool) currentBorrowers; 
    }

    mapping(bytes32 => Book) public books; 
    bytes32[] public iterator;           
    
    // Checking if such a book was ever added to the library
    // There is a case where user is trying to borrow a book, and there are 0 left
    // If there are 0 left, there are either borrowed or never added
    // In case they are borrowed, user can expect them to be returned at some point
    modifier checkTitle(string memory _title) {
        bytes32 key = keccak256(abi.encodePacked(_title));
        require(books[key].firstAdd == true, "Library doesn't contain the specified book");
        _;
    }

    function addBooks(string memory _title) public onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(_title));

        if(!books[key].firstAdd) {
            books[key].title = _title;
            books[key].availableCopies++;
            books[key].firstAdd = true;      
            iterator.push(key);
        } else {
            books[key].availableCopies++;
        }

        return;
    }

    function borrowBook(string memory _title) public checkTitle(_title) {
        bytes32 key = keccak256(abi.encodePacked(_title));
        require(books[key].availableCopies > 0, "There are no copies available from this book");
        require(!books[key].currentBorrowers[msg.sender], "The user has already borrowed this book");

        books[key].availableCopies--;
        books[key].currentBorrowers[msg.sender] = true;
        books[key].borrowingHistory.push(msg.sender);

        return;
    }

    function returnBook(string memory _title) public checkTitle(_title) {
        bytes32 key = keccak256(abi.encodePacked(_title));
        require(books[key].currentBorrowers[msg.sender], "User has not borrowed such a book");

        books[key].availableCopies++;
        books[key].currentBorrowers[msg.sender] = false;
    }
    
    function getNumberOfBooks() public view returns(uint) {
        return iterator.length;
    }

    function getBorrowingHistory(string memory _title) public view checkTitle(_title) returns(address[] memory) {
        bytes32 key = keccak256(abi.encodePacked(_title));
        return books[key].borrowingHistory;
    }
}