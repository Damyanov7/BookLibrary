// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";

contract Library is Ownable {

    struct Book {
        string title;
        uint32 availableCopies;
        address[] historyOfBorrowings;
    }

    string[] totalTitles;

    mapping(bytes32 => Book) private books;
    mapping(address => bytes32[]) private usersCurrentlyBorrowedBooks;

    // Function that check if string is present in array
    function stringExists(string memory target, string[] memory arr) internal pure returns (bool) {
        bytes memory targetBytes = bytes(target);

        for (uint i = 0; i < arr.length; i++) {
            if (keccak256(bytes(arr[i])) == keccak256(targetBytes)) {
                return true;
            }
        }
        return false;
    }
 
    function addBooks(string memory _bookName) public onlyOwner {
        if(!stringExists(_bookName, totalTitles)) 
            totalTitles.push(_bookName);
        bytes32 id = keccak256(abi.encodePacked(_bookName));
        books[id].availableCopies++;
        books[id].title = _bookName;
    }

    function checkIfUserHasBorrowedTitle(string memory _bookName) private view returns(bool) {
        bytes32 id = keccak256(abi.encodePacked(_bookName));
        bytes32[] memory borrowedTitles = usersCurrentlyBorrowedBooks[msg.sender];  // Getting the current user borrowed titles
        uint32 borrowedTitlesLength = uint32(borrowedTitles.length);                // Getting the amount of borrowed titles

        // For loop, checking if the title we are gonna borrow is already borrowed by the user
        bool isBorrowed = false;
        for (uint32 i = 0; i < borrowedTitlesLength; i++) {
            if(borrowedTitles[i] == id)
                isBorrowed = true;
        }

        return isBorrowed;
    }

    function borrowBooks(string memory _bookName) public {
        require(stringExists(_bookName, totalTitles), "There is no such book title");
        bytes32 id = keccak256(abi.encodePacked(_bookName));
        require(books[id].availableCopies != 0, "There are no more available copies of this book");

        require(!checkIfUserHasBorrowedTitle(_bookName), "User has already borrowed this title");
        usersCurrentlyBorrowedBooks[msg.sender].push(id); // In case user hasn't borrow this title, we add it to his list of borrowed titles

        books[id].historyOfBorrowings.push(msg.sender);    // Add sender to the history of borrowings of the unique title
        books[id].availableCopies--;                       // Decrement the amount of available copies of the unique title 

        // If there are no available copies of the book, we must remove it from totalTiles, since there are no copies to borrow from
        if(books[id].availableCopies == 0) {
            uint32 totalTitlesLength = uint32(totalTitles.length);

            for(uint32 i = 0; i < totalTitlesLength; i++) {
                if(keccak256(abi.encodePacked(totalTitles[i])) == id)
                    delete totalTitles[i];
            }
        }  
    }

    function returnBook(string memory _bookName) public {
        require(checkIfUserHasBorrowedTitle(_bookName), "User has not borrowed this title, this cannot return it");

        // Getting some id of the title, and the msg.sender borrowed titles list
        bytes32 id = keccak256(abi.encodePacked(_bookName));
        bytes32[] memory borrowedTitles = usersCurrentlyBorrowedBooks[msg.sender];
        uint32 borrowedTitlesLength = uint32(borrowedTitles.length); 

        // This for loop will remove the borrowed title from the list of borrowed titles of the msg.sender
        for(uint32 i = 0; i < borrowedTitlesLength; i++)
            if(borrowedTitles[i] == id)
                delete (usersCurrentlyBorrowedBooks[msg.sender])[i];

        // After we've remove the title from the msg.sender borrowed titles list, we need to increment the amount 
        books[id].availableCopies++;

        // Add book to totalTitles in case there are no other copies, and totalTitles doesn't contain the title anymore
        if(!stringExists(_bookName, totalTitles)) 
            totalTitles.push(_bookName);
    }

    function availableBooks() public view  returns (string[] memory) {
        require(totalTitles.length > 0, "No available books");
        return totalTitles;
    }

    function listBorrowings(string memory _bookName) public view returns (address[] memory) {
        bytes32 id = keccak256(abi.encodePacked(_bookName));
        return books[id].historyOfBorrowings;
    }
}