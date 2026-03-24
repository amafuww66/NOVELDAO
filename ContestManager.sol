// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovelToken.sol";
import "./RoleManager.sol";
import "./Membership.sol";

contract ContestManager is Ownable {
    NovelToken public novelToken;
    RoleManager public roleManager;
    Membership public membership;

    struct Contest {
        uint256 contestId;
        string name;
        uint256 deadline;
        bool exists;
        bool active;
        bool winnerFinalized;
        uint256 winningSubmissionId;
        uint256 submissionCount;
    }

    struct Submission {
        uint256 submissionId;
        uint256 contestId;
        address author;
        string title;
        string contentURI;
        uint256 voteCount;
        bool exists;
    }

    uint256 public nextContestId;
    uint256 public nextSubmissionId;

    mapping(uint256 => Contest) public contests;
    mapping(uint256 => mapping(uint256 => Submission)) public submissions;
    mapping(uint256 => uint256[]) public contestSubmissionIds;

    event ContestCreated(uint256 indexed contestId, string name, uint256 deadline);
    event NovelSubmitted(
        uint256 indexed contestId,
        uint256 indexed submissionId,
        address indexed author,
        string title,
        string contentURI
    );
    event Voted(
        uint256 indexed contestId,
        uint256 indexed submissionId,
        address indexed voter,
        uint256 amount
    );
    event VotingEnded(uint256 indexed contestId);
    event WinnerFinalized(
        uint256 indexed contestId,
        uint256 indexed submissionId,
        address indexed author,
        uint256 votes
    );

    constructor(
        address initialOwner,
        address _novelToken,
        address _roleManager,
        address _membership
    ) Ownable(initialOwner) {
        novelToken = NovelToken(_novelToken);
        roleManager = RoleManager(_roleManager);
        membership = Membership(_membership);
    }

    modifier onlyAdmin() {
        require(roleManager.isAdmin(msg.sender), "Not admin");
        _;
    }

    modifier onlyAuthor() {
        require(roleManager.isAuthor(msg.sender), "Not author");
        _;
    }

    function createContest(string calldata name, uint256 deadline) external onlyAdmin {
        require(bytes(name).length > 0, "Contest name required");
        require(deadline > block.timestamp, "Deadline must be in the future");

        contests[nextContestId] = Contest({
            contestId: nextContestId,
            name: name,
            deadline: deadline,
            exists: true,
            active: true,
            winnerFinalized: false,
            winningSubmissionId: 0,
            submissionCount: 0
        });

        emit ContestCreated(nextContestId, name, deadline);
        nextContestId++;
    }

    function submitNovel(
        uint256 contestId,
        string calldata title,
        string calldata contentURI
    ) external onlyAuthor {
        Contest storage contest = contests[contestId];

        require(contest.exists, "Contest does not exist");
        require(contest.active, "Contest is not active");
        require(block.timestamp < contest.deadline, "Contest deadline passed");
        require(bytes(title).length > 0, "Title required");
        require(bytes(contentURI).length > 0, "Content URI required");

        uint256 submissionId = nextSubmissionId;

        submissions[contestId][submissionId] = Submission({
            submissionId: submissionId,
            contestId: contestId,
            author: msg.sender,
            title: title,
            contentURI: contentURI,
            voteCount: 0,
            exists: true
        });

        contestSubmissionIds[contestId].push(submissionId);
        contest.submissionCount++;

        emit NovelSubmitted(contestId, submissionId, msg.sender, title, contentURI);
        nextSubmissionId++;
    }

    function vote(uint256 contestId, uint256 submissionId, uint256 amount) external {
        Contest storage contest = contests[contestId];

        require(contest.exists, "Contest does not exist");
        require(contest.active, "Contest is not active");
        require(block.timestamp < contest.deadline, "Voting period ended");
        require(membership.checkMembership(msg.sender), "Membership required");
        require(roleManager.isReader(msg.sender), "Not a reader");
        require(submissions[contestId][submissionId].exists, "Invalid submission");
        require(amount > 0, "Vote amount must be greater than 0");

        bool success = novelToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        submissions[contestId][submissionId].voteCount += amount;

        emit Voted(contestId, submissionId, msg.sender, amount);
    }

    function endVoting(uint256 contestId) external onlyAdmin {
        Contest storage contest = contests[contestId];

        require(contest.exists, "Contest does not exist");
        require(contest.active, "Contest already ended");

        contest.active = false;
        emit VotingEnded(contestId);
    }

    function finalizeWinner(uint256 contestId) external onlyAdmin {
        Contest storage contest = contests[contestId];

        require(contest.exists, "Contest does not exist");
        require(!contest.active, "Voting still active");
        require(!contest.winnerFinalized, "Winner already finalized");
        require(contest.submissionCount > 0, "No submissions");

        uint256[] memory submissionIds = contestSubmissionIds[contestId];
        uint256 highestVotes = 0;
        uint256 winningSubmissionId = submissionIds[0];

        for (uint256 i = 0; i < submissionIds.length; i++) {
            uint256 currentSubmissionId = submissionIds[i];
            uint256 currentVotes = submissions[contestId][currentSubmissionId].voteCount;

            if (currentVotes > highestVotes) {
                highestVotes = currentVotes;
                winningSubmissionId = currentSubmissionId;
            }
        }

        contest.winningSubmissionId = winningSubmissionId;
        contest.winnerFinalized = true;

        Submission memory winner = submissions[contestId][winningSubmissionId];

        emit WinnerFinalized(
            contestId,
            winningSubmissionId,
            winner.author,
            highestVotes
        );
    }

    function getWinner(uint256 contestId) external view returns (Submission memory) {
        Contest memory contest = contests[contestId];
        require(contest.exists, "Contest does not exist");
        require(contest.winnerFinalized, "Winner not finalized");

        return submissions[contestId][contest.winningSubmissionId];
    }

    function getWinnerAuthor(uint256 contestId) external view returns (address) {
        Contest memory contest = contests[contestId];
        require(contest.exists, "Contest does not exist");
        require(contest.winnerFinalized, "Winner not finalized");

        return submissions[contestId][contest.winningSubmissionId].author;
    }

    function getSubmissionIds(uint256 contestId) external view returns (uint256[] memory) {
        require(contests[contestId].exists, "Contest does not exist");
        return contestSubmissionIds[contestId];
    }
}