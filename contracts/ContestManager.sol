// ============================================
// File 4: ContestManager.sol
// Accepted improvements included:
// - Governor integration
// - clearer top-3 finalization rules
// - insufficient-submission handling
// - deterministic tie-breaker: lower submissionId wins ties
// - previewURI + fullContentURI support
// ============================================
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovelToken.sol";
import "./RoleManager.sol";
import "./Membership.sol";

contract ContestManager is Ownable {
    NovelToken public immutable novelToken;
    RoleManager public immutable roleManager;
    Membership public immutable membership;

    address public governor;

    struct Contest {
        string name;
        uint256 deadline;
        bool active;
        bool exists;
        bool winnerFinalized;
        uint256 submissionCount;
        uint256[3] winningSubmissionIds;
    }

    struct Submission {
        string title;
        string previewURI;
        string fullContentURI;
        address author;
        uint256 voteCount;
        bool exists;
    }

    uint256 public nextContestId;
    uint256 public nextSubmissionId;

    mapping(uint256 => Contest) public contests;
    mapping(uint256 => mapping(uint256 => Submission)) public submissions;
    mapping(uint256 => uint256[]) public contestSubmissionIds;
    mapping(uint256 => mapping(address => bool)) public hasSubmittedToContest;

    event GovernorUpdated(address indexed oldGovernor, address indexed newGovernor);
    event ContestCreated(uint256 indexed contestId, string name, uint256 deadline);
    event NovelSubmitted(
        uint256 indexed contestId,
        uint256 indexed submissionId,
        address indexed author,
        string title,
        string previewURI,
        string fullContentURI
    );
    event Voted(
        uint256 indexed contestId,
        uint256 indexed submissionId,
        address indexed voter,
        uint256 amount
    );
    event VotingEnded(uint256 indexed contestId);
    event WinnersFinalized(
        uint256 indexed contestId,
        uint256 firstSubmissionId,
        uint256 secondSubmissionId,
        uint256 thirdSubmissionId
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

    modifier onlyOwnerOrGovernor() {
        require(msg.sender == owner() || msg.sender == governor, "Not owner/governor");
        _;
    }

    modifier onlyAuthor() {
        require(roleManager.isAuthor(msg.sender), "Not author");
        _;
    }

    function setGovernor(address _governor) external onlyOwner {
        require(_governor != address(0), "Zero address");
        address oldGovernor = governor;
        governor = _governor;
        emit GovernorUpdated(oldGovernor, _governor);
    }

    function createContest(string calldata name, uint256 deadline) external onlyOwnerOrGovernor {
        require(bytes(name).length > 0, "Empty name");
        require(deadline > block.timestamp, "Deadline must be future");

        contests[nextContestId] = Contest({
            name: name,
            deadline: deadline,
            active: true,
            exists: true,
            winnerFinalized: false,
            submissionCount: 0,
            winningSubmissionIds: [uint256(0), uint256(0), uint256(0)]
        });

        emit ContestCreated(nextContestId, name, deadline);

        unchecked {
            nextContestId++;
        }
    }

    function submitNovel(
        uint256 contestId,
        string calldata title,
        string calldata previewURI,
        string calldata fullContentURI
    ) external onlyAuthor {
        Contest storage contest = contests[contestId];
        require(contest.exists, "Contest does not exist");
        require(contest.active, "Contest not active");
        require(block.timestamp < contest.deadline, "Submission closed");
        require(bytes(title).length > 0, "Empty title");
        require(bytes(previewURI).length > 0, "Empty preview URI");
        require(bytes(fullContentURI).length > 0, "Empty full content URI");
        require(!hasSubmittedToContest[contestId][msg.sender], "Already submitted");

        submissions[contestId][nextSubmissionId] = Submission({
            title: title,
            previewURI: previewURI,
            fullContentURI: fullContentURI,
            author: msg.sender,
            voteCount: 0,
            exists: true
        });

        contestSubmissionIds[contestId].push(nextSubmissionId);
        hasSubmittedToContest[contestId][msg.sender] = true;
        contest.submissionCount += 1;

        emit NovelSubmitted(
            contestId,
            nextSubmissionId,
            msg.sender,
            title,
            previewURI,
            fullContentURI
        );

        unchecked {
            nextSubmissionId++;
        }
    }

    function vote(uint256 contestId, uint256 submissionId, uint256 amount) external {
        Contest storage contest = contests[contestId];
        require(contest.exists, "Contest does not exist");
        require(contest.active, "Contest not active");
        require(block.timestamp < contest.deadline, "Voting ended");
        require(membership.checkMembership(msg.sender), "Membership required");
        require(roleManager.isReader(msg.sender), "Not reader");

        Submission storage submission = submissions[contestId][submissionId];
        require(submission.exists, "Invalid submission");
        require(amount > 0, "Invalid vote amount");

        bool success = novelToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        submission.voteCount += amount;
        emit Voted(contestId, submissionId, msg.sender, amount);
    }

    function endVoting(uint256 contestId) external onlyOwnerOrGovernor {
        Contest storage contest = contests[contestId];
        require(contest.exists, "Contest does not exist");
        require(contest.active, "Contest already ended");
        require(block.timestamp >= contest.deadline, "Voting still active");

        contest.active = false;
        emit VotingEnded(contestId);
    }

    function _betterSubmission(
        uint256 contestId,
        uint256 candidateId,
        uint256 currentId
    ) internal view returns (bool) {
        if (currentId == type(uint256).max) return true;

        uint256 candidateVotes = submissions[contestId][candidateId].voteCount;
        uint256 currentVotes = submissions[contestId][currentId].voteCount;

        if (candidateVotes > currentVotes) return true;
        if (candidateVotes < currentVotes) return false;

        return candidateId < currentId;
    }

    function finalizeWinner(uint256 contestId) external onlyOwnerOrGovernor {
        Contest storage contest = contests[contestId];
        require(contest.exists, "Contest does not exist");
        require(!contest.active, "Contest still active");
        require(!contest.winnerFinalized, "Already finalized");
        require(contest.submissionCount >= 3, "Need at least 3 submissions");

        uint256[] storage ids = contestSubmissionIds[contestId];

        uint256 firstId = type(uint256).max;
        uint256 secondId = type(uint256).max;
        uint256 thirdId = type(uint256).max;

        for (uint256 i = 0; i < ids.length; ) {
            uint256 currentId = ids[i];

            if (_betterSubmission(contestId, currentId, firstId)) {
                thirdId = secondId;
                secondId = firstId;
                firstId = currentId;
            } else if (_betterSubmission(contestId, currentId, secondId)) {
                thirdId = secondId;
                secondId = currentId;
            } else if (_betterSubmission(contestId, currentId, thirdId)) {
                thirdId = currentId;
            }

            unchecked {
                ++i;
            }
        }

        require(firstId != type(uint256).max, "Missing first winner");
        require(secondId != type(uint256).max, "Missing second winner");
        require(thirdId != type(uint256).max, "Missing third winner");

        contest.winningSubmissionIds[0] = firstId;
        contest.winningSubmissionIds[1] = secondId;
        contest.winningSubmissionIds[2] = thirdId;
        contest.winnerFinalized = true;

        emit WinnersFinalized(contestId, firstId, secondId, thirdId);
    }

    function getTop3SubmissionIds(uint256 contestId) external view returns (uint256[3] memory) {
        Contest memory contest = contests[contestId];
        require(contest.exists, "Contest does not exist");
        require(contest.winnerFinalized, "Winner not finalized");
        return contest.winningSubmissionIds;
    }

    function getTop3Authors(uint256 contestId) external view returns (address[3] memory) {
        Contest memory contest = contests[contestId];
        require(contest.exists, "Contest does not exist");
        require(contest.winnerFinalized, "Winner not finalized");

        address[3] memory authors;
        authors[0] = submissions[contestId][contest.winningSubmissionIds[0]].author;
        authors[1] = submissions[contestId][contest.winningSubmissionIds[1]].author;
        authors[2] = submissions[contestId][contest.winningSubmissionIds[2]].author;
        return authors;
    }

    function getSubmission(uint256 contestId, uint256 submissionId) external view returns (Submission memory) {
        require(submissions[contestId][submissionId].exists, "Invalid submission");
        return submissions[contestId][submissionId];
    }
}