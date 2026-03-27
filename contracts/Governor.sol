// ============================================
// File 6: Governor.sol
// Minimal token-weighted governance for this course project.
// Scope: treasury and optional contest-admin actions.
// No snapshots, delegation, or timelock in this MVP.
// ============================================
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovelToken.sol";

contract Governor is Ownable {
    NovelToken public immutable novelToken;

    uint256 public proposalCount;
    uint256 public votingPeriod;
    uint256 public quorumTokens;
    uint256 public proposalThreshold;

    struct Proposal {
        address proposer;
        address target;
        uint256 value;
        bytes data;
        string description;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address indexed target,
        uint256 value,
        string description,
        uint256 deadline
    );
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event VotingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);
    event ProposalThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    constructor(
        address initialOwner,
        address _novelToken,
        uint256 _votingPeriod,
        uint256 _quorumTokens,
        uint256 _proposalThreshold
    ) Ownable(initialOwner) {
        require(_novelToken != address(0), "Zero token");
        require(_votingPeriod > 0, "Invalid voting period");

        novelToken = NovelToken(_novelToken);
        votingPeriod = _votingPeriod;
        quorumTokens = _quorumTokens;
        proposalThreshold = _proposalThreshold;
    }

    function setVotingPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Invalid period");
        uint256 oldPeriod = votingPeriod;
        votingPeriod = newPeriod;
        emit VotingPeriodUpdated(oldPeriod, newPeriod);
    }

    function setQuorumTokens(uint256 newQuorum) external onlyOwner {
        uint256 oldQuorum = quorumTokens;
        quorumTokens = newQuorum;
        emit QuorumUpdated(oldQuorum, newQuorum);
    }

    function setProposalThreshold(uint256 newThreshold) external onlyOwner {
        uint256 oldThreshold = proposalThreshold;
        proposalThreshold = newThreshold;
        emit ProposalThresholdUpdated(oldThreshold, newThreshold);
    }

    function propose(
        address target,
        uint256 value,
        bytes calldata data,
        string calldata description
    ) external returns (uint256) {
        require(target != address(0), "Zero target");
        require(bytes(description).length > 0, "Empty description");
        require(novelToken.balanceOf(msg.sender) >= proposalThreshold, "Below proposal threshold");

        uint256 proposalId = proposalCount;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            target: target,
            value: value,
            data: data,
            description: description,
            deadline: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        proposalCount += 1;
        emit ProposalCreated(proposalId, msg.sender, target, value, description, block.timestamp + votingPeriod);
        return proposalId;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.deadline > 0, "Proposal not found");
        require(block.timestamp < proposal.deadline, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 weight = novelToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.yesVotes += weight;
        } else {
            proposal.noVotes += weight;
        }

        emit Voted(proposalId, msg.sender, support, weight);
    }

    function canExecute(uint256 proposalId) public view returns (bool) {
        Proposal memory proposal = proposals[proposalId];
        if (proposal.deadline == 0) return false;
        if (block.timestamp < proposal.deadline) return false;
        if (proposal.executed) return false;
        if (proposal.yesVotes <= proposal.noVotes) return false;
        if (proposal.yesVotes < quorumTokens) return false;
        return true;
    }

    function execute(uint256 proposalId) external {
        require(canExecute(proposalId), "Proposal not executable");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Execution failed");

        emit ProposalExecuted(proposalId, msg.sender);
    }

    receive() external payable {}
}
