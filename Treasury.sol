// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovelToken.sol";
import "./Membership.sol";
import "./RoleManager.sol";
import "./ContestManager.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Treasury is Ownable {
    NovelToken public novelToken;
    Membership public membership;
    RoleManager public roleManager;
    ContestManager public contestManager;
    AggregatorV3Interface public priceFeed;

    uint256 public membershipPriceUsd; // 18 decimals
    uint256 public tokenPriceUsd; // 18 decimals per full token
    uint256 public constant INITIAL_VOTING_TOKENS = 3 * 10**18;
    uint256 public constant PLATFORM_FEE_PERCENT = 3;

    mapping(uint256 => uint256) public contestPrizePool;

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
        address indexed winner,
        uint256 winnerAmount,
        uint256 adminFee
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

    function setMembershipPriceUsd(uint256 newPriceUsd) external onlyOwner {
        uint256 oldPriceUsd = membershipPriceUsd;
        membershipPriceUsd = newPriceUsd;
        emit MembershipPriceUpdated(oldPriceUsd, newPriceUsd);
    }

    function setTokenPriceUsd(uint256 newPriceUsd) external onlyOwner {
        uint256 oldPriceUsd = tokenPriceUsd;
        tokenPriceUsd = newPriceUsd;
        emit TokenPriceUpdated(oldPriceUsd, newPriceUsd);
    }

    function getLatestETHPrice() public view returns (uint256) {
        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        require(updatedAt > 0, "Round not complete");
        return uint256(price);
    }

    function getPriceFeedDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function usdToWei(uint256 usdAmount) public view returns (uint256) {
        uint256 ethPrice = getLatestETHPrice();
        uint8 decimals = getPriceFeedDecimals();

        if (decimals >= 8) {
            uint256 scaleDown = 10 ** (decimals - 8);
            return (usdAmount * 10**8) / (ethPrice / scaleDown);
        } else {
            uint256 scaleUp = 10 ** (8 - decimals);
            return (usdAmount * 10**8) / (ethPrice * scaleUp);
        }
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
        roleManager.assignReader(msg.sender);
        novelToken.mint(msg.sender, INITIAL_VOTING_TOKENS);

        contestPrizePool[contestId] += msg.value;

        emit MembershipPurchased(
            msg.sender,
            contestId,
            msg.value,
            INITIAL_VOTING_TOKENS
        );
    }

    function buyExtraTokens(uint256 contestId, uint256 tokenAmount) external payable {
        require(membership.checkMembership(msg.sender), "Membership required");
        require(roleManager.isReader(msg.sender), "Not a reader");
        require(tokenAmount > 0, "Invalid token amount");

        uint256 requiredWei = getTokenPriceInWei(tokenAmount);
        require(msg.value >= requiredWei, "Insufficient ETH");

        novelToken.mint(msg.sender, tokenAmount);
        contestPrizePool[contestId] += msg.value;

        emit ExtraTokensPurchased(
            msg.sender,
            contestId,
            msg.value,
            tokenAmount
        );
    }

    function distributeReward(uint256 contestId) external onlyOwner {
        address winner = contestManager.getWinnerAuthor(contestId);
        require(winner != address(0), "Invalid winner");

        uint256 totalPool = contestPrizePool[contestId];
        require(totalPool > 0, "No prize pool for this contest");

        uint256 adminFee = (totalPool * PLATFORM_FEE_PERCENT) / 100;
        uint256 winnerAmount = totalPool - adminFee;

        contestPrizePool[contestId] = 0;

        (bool successWinner, ) = payable(winner).call{value: winnerAmount}("");
        require(successWinner, "Winner transfer failed");

        (bool successAdmin, ) = payable(owner()).call{value: adminFee}("");
        require(successAdmin, "Admin fee transfer failed");

        emit RewardDistributed(contestId, winner, winnerAmount, adminFee);
    }

    function getContestPrizePool(uint256 contestId) external view returns (uint256) {
        return contestPrizePool[contestId];
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}