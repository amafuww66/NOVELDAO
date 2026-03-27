// ============================================
// File 2: Membership.sol
// ============================================
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Membership is Ownable {
    mapping(address => bool) public isMember;
    mapping(address => bool) public managers;

    event ManagerUpdated(address indexed account, bool allowed);
    event MembershipGranted(address indexed user);
    event MembershipRevoked(address indexed user);

    constructor(address initialOwner) Ownable(initialOwner) {}

    modifier onlyAuthorized() {
        require(msg.sender == owner() || managers[msg.sender], "Not authorized");
        _;
    }

    function setManager(address account, bool allowed) external onlyOwner {
        managers[account] = allowed;
        emit ManagerUpdated(account, allowed);
    }

    function grantMembership(address user) external onlyAuthorized {
        require(!isMember[user], "Already a member");
        isMember[user] = true;
        emit MembershipGranted(user);
    }

    function revokeMembership(address user) external onlyAuthorized {
        require(isMember[user], "Not a member");
        isMember[user] = false;
        emit MembershipRevoked(user);
    }

    function checkMembership(address user) external view returns (bool) {
        return isMember[user];
    }
}