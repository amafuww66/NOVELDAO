// ============================================
// File 3: RoleManager.sol
// Improvement: roles are now additive instead of mutually exclusive.
// A user can be both Reader and Author at the same time.
// ============================================
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RoleManager is Ownable {
    mapping(address => bool) public readers;
    mapping(address => bool) public authors;
    mapping(address => bool) public admins;
    mapping(address => bool) public managers;

    event ManagerUpdated(address indexed account, bool allowed);
    event ReaderUpdated(address indexed user, bool allowed);
    event AuthorUpdated(address indexed user, bool allowed);
    event AdminUpdated(address indexed user, bool allowed);

    constructor(address initialOwner) Ownable(initialOwner) {
        admins[initialOwner] = true;
        emit AdminUpdated(initialOwner, true);
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner() || managers[msg.sender], "Not authorized");
        _;
    }

    function setManager(address account, bool allowed) external onlyOwner {
        managers[account] = allowed;
        emit ManagerUpdated(account, allowed);
    }

    function setReader(address user, bool allowed) external onlyAuthorized {
        readers[user] = allowed;
        emit ReaderUpdated(user, allowed);
    }

    function setAuthor(address user, bool allowed) external onlyAuthorized {
        authors[user] = allowed;
        emit AuthorUpdated(user, allowed);
    }

    function setAdmin(address user, bool allowed) external onlyOwner {
        admins[user] = allowed;
        emit AdminUpdated(user, allowed);
    }

    function isReader(address user) external view returns (bool) {
        return readers[user];
    }

    function isAuthor(address user) external view returns (bool) {
        return authors[user];
    }

    function isAdmin(address user) external view returns (bool) {
        return admins[user];
    }
}

