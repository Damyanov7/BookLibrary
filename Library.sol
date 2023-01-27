// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";

contract Library is Ownable {

    struct Book {
        uint32 availableCopies;     // How much copies do we have from the book
        address[] borrowingLedger;  // Who has borrowed the book
    }

    /*  
    *   Users should be able to see the available books
    *   If I declare my mapping as public, getter method will be auto-generated.
    *   The problem with that is remix requires you to input key, to get a value from this getter.
    *   What I want to do is display all the available books in one go.
    *   To tackle this I'm creating a string array, which I update when the following conditions are met:
    *   1: If a book is added, it's title will be added here.
    *   1.2: If the title exists in the string array, it is not added again
    *   3: When borrowing a book, if the availableCopies get down to 0, array is updated by deleting the book title from it, leaving an empty string
    */
    string[] public availableTitles;

    /*
    *   The mapping books, cotains the information of the unique titles added.
    *   The logic here is as follows:
    *   1: We receive a book by string (bookName / title)
    *   2: I convert that name to bytes32 via keccak256 to get the id for that title
    *   3: I use the ID to access the title details
    *   3.1: I increment the amount of availableCopies
    *   3.2: When someone borrows a book, his address is saved to borrowingLedger
    */
    mapping(bytes32 => Book) public books;

    /*
    *   A user should not borrow more than one copy of a book at a time.
    *   The way I tackle this problem, if I understood it correctly is to have a mapping, that holds the ID's of all books that a user has borrowed
    *   The key to accessing the value is the address of the sender
    *   The value is array holding bytes32 ID's that are generated from having a book title go through keccak256
    */
    mapping(address => bytes32[]) private borrowedTitles;

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
 
    function addBooks(string memory _title) public onlyOwner {
        if(!stringExists(_title, availableTitles)) 
            availableTitles.push(_title);

        bytes32 id = keccak256(abi.encodePacked(_title));
        books[id].availableCopies++;
    }

    function checkIfUserHasBorrowedTitle(string memory _title) private view returns(bool) {
        bytes32 id = keccak256(abi.encodePacked(_title));
        uint32 borrowedTitlesAmount = uint32(borrowedTitles[msg.sender].length);

        for (uint32 i = 0; i < borrowedTitlesAmount; i++) {
            if(borrowedTitles[msg.sender][i] == id)
                return true;
        }

        return false;
    }

    function borrowBook(string memory _title) public {
        require(stringExists(_title, availableTitles), "No available copies of this book");
        bytes32 id = keccak256(abi.encodePacked(_title));

        require(!checkIfUserHasBorrowedTitle(_title), "User has already borrowed this title");
        borrowedTitles[msg.sender].push(id);   // In case the require passed, we add the _title ID to the sender borrowedTitles
        books[id].borrowingLedger.push(msg.sender);     // Add sender to the history of borrowings of the unique title
        books[id].availableCopies--;                        // Decrement the amount of available copies of the unique title 

        // If there are no available copies of the book, we must remove it from totalTiles, since there are no copies to borrow from
        if(books[id].availableCopies == 0) {
            uint32 availableTitlesLength = uint32(availableTitles.length);
            for(uint32 i = 0; i < availableTitlesLength; i++) {
                if(keccak256(abi.encodePacked(availableTitles[i])) == id)
                    delete availableTitles[i];
            }
        }  
    }

    function returnBook(string memory _title) public {
        require(checkIfUserHasBorrowedTitle(_title), "User has not borrowed this title, thus cannot return it");
        bytes32 id = keccak256(abi.encodePacked(_title));

        uint32 borrowedTitlesLength = uint32(borrowedTitles[msg.sender].length); 
        // This for loop will remove the borrowed title from the list of borrowed titles of the msg.sender
        for(uint32 i = 0; i < borrowedTitlesLength; i++) {
            if(borrowedTitles[msg.sender][i] == id) {
                delete (borrowedTitles[msg.sender])[i];
            }
        }

        // After we've removed the title from the msg.sender borrowed titles list, we need to increment the amount in the library (books mapping)
        books[id].availableCopies++;

        // Add book to availableTitles in case there are no other copies, and availableTitles doesn't contain the title anymore
        if(!stringExists(_title, availableTitles)) {
            availableTitles.push(_title);
        }
    }

    function listBorrowings(string memory _title) public view returns (address[] memory) {
        bytes32 id = keccak256(abi.encodePacked(_title));
        return books[id].borrowingLedger;
    }
}