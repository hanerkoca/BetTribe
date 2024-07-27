// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

contract BettingPlatform {
    // Struct representing a football match
    struct Match {
        uint256 matchId;    // Unique identifier for the match
        string homeTeam;    // Name of the home team
        string awayTeam;    // Name of the away team
        uint256 matchTime;  // Timestamp of the match's start time
    }

    // Struct representing a betting group
    struct Group {
        uint256 betValue;   // The amount of ETH each participant must bet (in Wei)
        uint256 matchId;    // Identifier linking the group to a specific match
        uint8 maxParticipants; // Maximum number of participants allowed in the group
        uint8 minParticipants; // Minimum number of participants required for the group to be valid (fixed at 2)
        address creator;    // Address of the group creator
        string password;    // Password to join the group
        bool isActive;      // Boolean indicating whether the group is active
        address[] participants; // List of addresses of participants
        mapping(address => uint8) bets; // Mapping from participant addresses to their bets (1: home win, 0: draw, 2: away win)
        mapping(address => bool) hasParticipated; // Mapping to track if an address has already joined the group
        mapping(address => uint256) winnings; // Mapping from participant addresses to their winnings
    }

    address public platformAccount;  // Address of the platform account for commission
    address public owner;            // Address of the contract owner
    uint256 public commissionPercentage = 50; // 0.5% commission (expressed as 50 basis points)
    uint256 public constant BASIS_POINTS = 10000; // Basis points for percentage calculations

    mapping(uint256 => Group) private groups; // Mapping from group ID to Group struct
    mapping(uint256 => Match) public matches; // Mapping from match ID to Match struct
    uint256 public groupCount; // Counter for group IDs
    uint256 public matchCount; // Counter for match IDs

    // Events
    event MatchCreated(uint256 matchId, string homeTeam, string awayTeam, uint256 matchTime);
    event GroupCreated(uint256 groupId, address creator);
    event BetPlaced(uint256 groupId, address participant, uint8 bet);
    event WinningsDistributed(uint256 groupId, address winner, uint256 amount);
    event BetsRefunded(uint256 groupId);
    event GroupCancelled(uint256 groupId);

    // Modifier to restrict function access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    // Constructor to initialize the platform account and the contract owner
    constructor(address _platformAccount) {
        platformAccount = _platformAccount;
        owner = msg.sender; // Set the contract deployer as the owner
    }

    // Function to create a new match (only accessible by the owner)
    function createMatch(string memory _homeTeam, string memory _awayTeam, uint256 _matchTime) public onlyOwner {
        Match storage newMatch = matches[matchCount++];
        newMatch.matchId = matchCount - 1;
        newMatch.homeTeam = _homeTeam;
        newMatch.awayTeam = _awayTeam;
        newMatch.matchTime = _matchTime;

        emit MatchCreated(newMatch.matchId, _homeTeam, _awayTeam, _matchTime);
    }

    // Function to create a new betting group
    function createGroup(uint256 _betValue, uint256 _matchId, uint8 _maxParticipants, string memory _password, uint8 _creatorBet) public payable {
        require(matches[_matchId].matchId == _matchId, "Match does not exist.");
        require(matches[_matchId].matchTime > block.timestamp, "Cannot create group for a match that has already started.");
        require(_maxParticipants >= 2 && _maxParticipants <= 10, "Invalid number of participants.");
        require(msg.value == _betValue, "Incorrect bet value.");

        Group storage newGroup = groups[groupCount++];
        newGroup.betValue = _betValue;
        newGroup.matchId = _matchId;
        newGroup.maxParticipants = _maxParticipants;
        newGroup.minParticipants = 2;  
        newGroup.creator = msg.sender;
        newGroup.password = _password;
        newGroup.isActive = true;

        // Creator places their bet during group creation
        newGroup.participants.push(msg.sender);
        newGroup.bets[msg.sender] = _creatorBet;
        newGroup.hasParticipated[msg.sender] = true;

        emit GroupCreated(groupCount - 1, msg.sender);
        emit BetPlaced(groupCount - 1, msg.sender, _creatorBet);
    }

    // Function to join an existing betting group
    function joinGroup(uint256 _groupId, string memory _password, uint8 _bet) public payable {
        Group storage group = groups[_groupId];
        require(group.isActive, "Group is not active.");
        require(keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(group.password)), "Incorrect password.");
        require(msg.value == group.betValue, "Incorrect bet value.");
        require(group.participants.length < group.maxParticipants, "Group is full.");
        require(!group.hasParticipated[msg.sender], "You have already participated.");
        require(_bet == 1 || _bet == 0 || _bet == 2, "Invalid bet option.");

        // Add participant to the group
        group.participants.push(msg.sender);
        group.bets[msg.sender] = _bet;
        group.hasParticipated[msg.sender] = true;

        emit BetPlaced(_groupId, msg.sender, _bet);
    }

    // Function to distribute winnings to the winners of the bet
    function distributeWinnings(uint256 _groupId, uint8 _winningBet) public onlyOwner {
        Group storage group = groups[_groupId];
        require(group.isActive, "Group is not active.");
        require(group.participants.length >= group.minParticipants, "Not enough participants.");

        uint256 totalBetValue = group.betValue * group.participants.length;
        uint256 commission = (totalBetValue * commissionPercentage) / BASIS_POINTS;
        uint256 prizePool = totalBetValue - commission;

        bool winnerFound = false;
        uint256 winnerCount = 0;

        // Count the number of winners
        for (uint256 i = 0; i < group.participants.length; i++) {
            if (group.bets[group.participants[i]] == _winningBet) {
                winnerCount++;
            }
        }

        // Distribute prize pool to winners
        if (winnerCount > 0) {
            uint256 winnerShare = prizePool / winnerCount;
            for (uint256 i = 0; i < group.participants.length; i++) {
                if (group.bets[group.participants[i]] == _winningBet) {
                    (bool sent, ) = group.participants[i].call{value: winnerShare}("");
                    require(sent, "Failed to send prize.");
                    emit WinningsDistributed(_groupId, group.participants[i], winnerShare);
                }
            }
        } else {
            // Refund bets if there are no winners
            uint256 refundValue = group.betValue - (group.betValue * commissionPercentage) / BASIS_POINTS;
            for (uint256 i = 0; i < group.participants.length; i++) {
                (bool sent, ) = group.participants[i].call{value: refundValue}("");
                require(sent, "Failed to refund bet.");
            }
            emit BetsRefunded(_groupId);
        }

        // Send commission to the platform account
        (bool sent, ) = platformAccount.call{value: commission}("");
        require(sent, "Failed to send commission.");

        group.isActive = false;
    }

    // Function to cancel a betting group by the creator (only if the group is not full)
    function cancelGroup(uint256 _groupId) public {
        Group storage group = groups[_groupId];
        require(group.creator == msg.sender, "Only the group creator can cancel the group.");
        require(group.isActive, "Group is not active.");
        require(group.participants.length < group.maxParticipants, "Group is full and cannot be cancelled.");

        group.isActive = false;

        // Refund all participants
        for (uint256 i = 0; i < group.participants.length; i++) {
            (bool sent, ) = group.participants[i].call{value: group.betValue}("");
            require(sent, "Failed to refund bet.");
        }

        emit GroupCancelled(_groupId);
    }

    // Function to view match details by match ID
    function viewMatch(uint256 _matchId) public view returns (string memory homeTeam, string memory awayTeam, uint256 matchTime) {
        Match storage matchInfo = matches[_matchId];
        return (matchInfo.homeTeam, matchInfo.awayTeam, matchInfo.matchTime);
    }

    // Function to view participants of a group by group ID
    function viewParticipants(uint256 _groupId) public view returns (address[] memory) {
        Group storage group = groups[_groupId];
        return group.participants;
    }
}