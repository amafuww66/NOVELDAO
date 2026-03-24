// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RoleManager is Ownable {
    enum Role {
        None,
        Reader,
        Author,
        Admin
    }

    mapping(address => Role) public roles;
    mapping(address => bool) public managers;

    event ManagerUpdated(address indexed account, bool allowed);
    event RoleAssigned(address indexed user, Role role);
    event RoleCleared(address indexed user);

    constructor(address initialOwner) Ownable(initialOwner) {
        roles[initialOwner] = Role.Admin;
        emit RoleAssigned(initialOwner, Role.Admin);
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == owner() || managers[msg.sender],
            "Not authorized"
        );
        _;
    }

    function setManager(address account, bool allowed) external onlyOwner {
        managers[account] = allowed;
        emit ManagerUpdated(account, allowed);
    }

    function assignReader(address user) external onlyAuthorized {
        roles[user] = Role.Reader;
        emit RoleAssigned(user, Role.Reader);
    }

    function assignAuthor(address user) external onlyAuthorized {
        roles[user] = Role.Author;
        emit RoleAssigned(user, Role.Author);
    }

    function assignAdmin(address user) external onlyOwner {
        roles[user] = Role.Admin;
        emit RoleAssigned(user, Role.Admin);
    }

    function clearRole(address user) external onlyAuthorized {
        roles[user] = Role.None;
        emit RoleCleared(user);
    }

    function getRole(address user) external view returns (Role) {
        return roles[user];
    }

    function isReader(address user) external view returns (bool) {
        return roles[user] == Role.Reader;
    }

    function isAuthor(address user) external view returns (bool) {
        return roles[user] == Role.Author;
    }

    function isAdmin(address user) external view returns (bool) {
        return roles[user] == Role.Admin;
    }
}