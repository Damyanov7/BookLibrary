// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "hardhat/console.sol";

contract Library is Ownable {

    struct BookContext {
        uint32 id;
        bool firstAdd;
        address[] borrowingHistory;
        mapping(address => bool) currentBorrowers; 
    }

    struct Book {
        uint32 availableCopies;     
        string title; 
    }

    // Our context will contain id, which we are gonna use to index our books array
    // A boolean that will tell us if the owner has ever pushed such a book in the books array
    // And borrowing ledger, that lets us know the history of borrowings of certain title
    // And a mapping that tracks current borrowers, so they cannot borrow the same book again
    mapping(bytes32 => BookContext) bookContext; 
    uint32 uniqueTitles;    // Size of the books array
    Book[] books;           // Our books array contains the available copies of the unique book and it's title

    modifier checkTitle(string memory _title) {
        bytes32 key = keccak256(abi.encodePacked(_title));
        require(bookContext[key].firstAdd, "Library doesn't contain the specified book");
        _;
    }

    function addBooks(string memory _title) public onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(_title));

        if(!bookContext[key].firstAdd) {
            bookContext[key].id = uniqueTitles++;   // This is going to be the index for this title, e.g. they way we get books.availableCopies
            bookContext[key].firstAdd = true;       // Making sure we wont rewrite something that is already pushed to the array

            // Pushing this book title for the first time in the array, that is why available copies == 1
            books.push(Book({
                availableCopies: 1,
                title: _title
            }));
        } else {
            books[bookContext[key].id].availableCopies++;
        }

        return;
    }

    function borrowBook(string memory _title) public checkTitle(_title) {
        bytes32 key = keccak256(abi.encodePacked(_title));
        require(books[bookContext[key].id].availableCopies > 0, "There are no copies available from this book");
        require(!bookContext[key].currentBorrowers[msg.sender], "The user has already borrowed this book");

        books[bookContext[key].id].availableCopies--;
        bookContext[key].currentBorrowers[msg.sender] = true;
        bookContext[key].borrowingHistory.push(msg.sender);

        return;
    }

    function returnBook(string memory _title) public checkTitle(_title) {
        bytes32 key = keccak256(abi.encodePacked(_title));
        require(bookContext[key].currentBorrowers[msg.sender], "User has not borrowed such a book");

        books[bookContext[key].id].availableCopies++;
        bookContext[key].currentBorrowers[msg.sender] = false;
    }
    
    function getAvailableTitles() public view returns (Book[] memory) {
        require(uniqueTitles > 0, "Library is empty, need to add books first");
        

        uint32 retSize = 0;
        for(uint32 i = 0; i < uniqueTitles; i++) {
            if(books[i].availableCopies > 0) {
                retSize++;
            }
        }

        uint32 retPosition = 0;
        Book[] memory ret = new Book[](retSize);
        for(uint32 i = 0; i < uniqueTitles; i++) {
            if(books[i].availableCopies > 0) {
                ret[retPosition].title = books[i].title;
                ret[retPosition].availableCopies = books[i].availableCopies;
                retPosition++;
            }
        }

        return ret;
    }

    function getBorrowingHistory(string memory _title) public view checkTitle(_title) returns(address[] memory) {
        bytes32 key = keccak256(abi.encodePacked(_title));

        return bookContext[key].borrowingHistory;
    }
}