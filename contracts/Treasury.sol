// ============================================
// File 5: Treasury.sol
// Accepted improvements included:
// - Governor-controlled policy functions
// - platform fees retained in treasury
// - oracle freshness check
// - reward distribution remains push-based for MVP
// ============================================
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./NovelToken.sol";
import "./Membership.sol";
import "./RoleManager.sol";
import "./ContestManager.sol";

contract Treasury is Ownable {
    NovelToken public immutable novelToken;
    Membership public immutable membership;
    RoleManager public immutable roleManager;
    ContestManager public immutable contestManager;
    AggregatorV3Interface public immutable priceFeed;

    address public governor;

    uint256 public membershipPriceUsd;
    uint256 public tokenPriceUsd;
    uint256 public accumulatedPlatformFees;

    uint256 public constant INITIAL_VOTING_TOKENS = 3 * 10**18;
    uint256 public constant PLATFORM_FEE_PERCENT = 10;
    uint256 public constant MAX_PRICE_AGE = 1 days;

    mapping(uint256 => uint256) public contestPrizePool;

    event GovernorUpdated(address indexed oldGovernor, address indexed newGovernor);
    event MembershipPurchased(
        address indexed reader,
        uint256 indexed contestId,
        uint256 paidWei,
        uint256 votingTokensGranted
    );
    event ExtraTokensPurchased(
        address indexed buyer,
        uint256 indexed contestId,
        uint256 paidWei,
        uint256 tokenAmount
    );
    event MembershipPriceUpdated(uint256 oldPriceUsd, uint256 newPriceUsd);
    event TokenPriceUpdated(uint256 oldPriceUsd, uint256 newPriceUsd);
    event RewardDistributed(
        uint256 indexed contestId,
        uint256 totalPool,
        uint256 platformFee,
        uint256 firstPrize,
        uint256 secondPrize,
        uint256 thirdPrize
    );

    constructor(
        address initialOwner,
        address _novelToken,
        address _membership,
        address _roleManager,
        address _contestManager,
        address _priceFeed,
        uint256 _membershipPriceUsd,
        uint256 _tokenPriceUsd
    ) Ownable(initialOwner) {
        novelToken = NovelToken(_novelToken);
        membership = Membership(_membership);
        roleManager = RoleManager(_roleManager);
        contestManager = ContestManager(_contestManager);
        priceFeed = AggregatorV3Interface(_priceFeed);
        membershipPriceUsd = _membershipPriceUsd;
        tokenPriceUsd = _tokenPriceUsd;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Not governor");
        _;
    }

    function setGovernor(address _governor) external onlyOwner {
        require(_governor != address(0), "Zero address");
        address oldGovernor = governor;
        governor = _governor;
        emit GovernorUpdated(oldGovernor, _governor);
    }

    function setMembershipPriceUsd(uint256 newPriceUsd) external onlyGovernor {
        require(newPriceUsd > 0, "Invalid price");
        uint256 oldPriceUsd = membershipPriceUsd;
        membershipPriceUsd = newPriceUsd;
        emit MembershipPriceUpdated(oldPriceUsd, newPriceUsd);
    }

    function setTokenPriceUsd(uint256 newPriceUsd) external onlyGovernor {
        require(newPriceUsd > 0, "Invalid price");
        uint256 oldPriceUsd = tokenPriceUsd;
        tokenPriceUsd = newPriceUsd;
        emit TokenPriceUpdated(oldPriceUsd, newPriceUsd);
    }

    function getLatestETHPrice() public view returns (uint256) {
        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        require(updatedAt > 0, "Round incomplete");
        require(block.timestamp - updatedAt <= MAX_PRICE_AGE, "Stale oracle price");
        return uint256(price);
    }

    function getPriceFeedDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function usdToWei(uint256 usdAmount) public view returns (uint256) {
    uint256 ethPrice = getLatestETHPrice();
    uint8 decimals = getPriceFeedDecimals();
    uint256 normalizedPrice;

    if (decimals == 18) {
        normalizedPrice = ethPrice;
    } else if (decimals > 18) {
        normalizedPrice = ethPrice / (10 ** (decimals - 18));
    } else {
        normalizedPrice = ethPrice * (10 ** (18 - decimals));
    }

    return (usdAmount * 10**18) / normalizedPrice;
}
    function getMembershipPriceInWei() public view returns (uint256) {
        return usdToWei(membershipPriceUsd);
    }

    function getTokenPriceInWei(uint256 tokenAmount) public view returns (uint256) {
        require(tokenAmount > 0, "Invalid token amount");
        uint256 totalUsdCost = (tokenAmount * tokenPriceUsd) / 10**18;
        return usdToWei(totalUsdCost);
    }

    function purchaseMembership(uint256 contestId) external payable {
        require(!membership.checkMembership(msg.sender), "Already a member");

        uint256 requiredWei = getMembershipPriceInWei();
        require(msg.value >= requiredWei, "Insufficient membership payment");

        membership.grantMembership(msg.sender);
        roleManager.setReader(msg.sender, true);
        novelToken.mint(msg.sender, INITIAL_VOTING_TOKENS);

        contestPrizePool[contestId] += msg.value;

        emit MembershipPurchased(msg.sender, contestId, msg.value, INITIAL_VOTING_TOKENS);
    }

    function buyExtraTokens(uint256 contestId, uint256 tokenAmount) external payable {
        require(membership.checkMembership(msg.sender), "Membership required");
        require(roleManager.isReader(msg.sender), "Not reader");
        require(tokenAmount > 0, "Invalid token amount");

        uint256 requiredWei = getTokenPriceInWei(tokenAmount);
        require(msg.value >= requiredWei, "Insufficient ETH");

        novelToken.mint(msg.sender, tokenAmount);
        contestPrizePool[contestId] += msg.value;

        emit ExtraTokensPurchased(msg.sender, contestId, msg.value, tokenAmount);
    }

    function distributeReward(uint256 contestId) external onlyGovernor {
        address[3] memory winners = contestManager.getTop3Authors(contestId);

        uint256 totalPool = contestPrizePool[contestId];
        require(totalPool > 0, "No prize pool");
        require(winners[0] != address(0), "Invalid first winner");
        require(winners[1] != address(0), "Invalid second winner");
        require(winners[2] != address(0), "Invalid third winner");

        uint256 platformFee = (totalPool * PLATFORM_FEE_PERCENT) / 100;
        uint256 authorPool = totalPool - platformFee;

        uint256 firstPrize = (authorPool * 60) / 100;
        uint256 secondPrize = (authorPool * 30) / 100;
        uint256 thirdPrize = authorPool - firstPrize - secondPrize;

        contestPrizePool[contestId] = 0;
        accumulatedPlatformFees += platformFee;

        (bool s1, ) = payable(winners[0]).call{value: firstPrize}("");
        require(s1, "First prize transfer failed");

        (bool s2, ) = payable(winners[1]).call{value: secondPrize}("");
        require(s2, "Second prize transfer failed");

        (bool s3, ) = payable(winners[2]).call{value: thirdPrize}("");
        require(s3, "Third prize transfer failed");

        emit RewardDistributed(contestId, totalPool, platformFee, firstPrize, secondPrize, thirdPrize);
    }

    function getContestPrizePool(uint256 contestId) external view returns (uint256) {
        return contestPrizePool[contestId];
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
