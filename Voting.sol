// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
}

contract VotingSystem {
    using SafeMath for uint;

    address public owner;
    bool public registrationOpen;
    bool public votingOpen;
    uint public winnerIndex;

    struct Candidate {
        string name;
        uint voteCount;
    }

    struct Voter {
        bool registered;
        bool hasVoted;
        uint votedFor;
    }

    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    mapping(address => bool) public authorizedRegistrants;

    event VoterRegistered(address indexed voter);
    event CandidateRegistered(string name, uint indexed candidateIndex);
    event VoteCasted(address indexed voter, uint indexed candidateIndex);
    event VotingClosed(uint indexed winnerIndex);
    event AuthorizedRegistrantAdded(address indexed registrant);
    event AuthorizedRegistrantRemoved(address indexed registrant);

    uint constant INVALID_CANDIDATE_INDEX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyAuthorizedRegistrant() {
        require(
            msg.sender == owner || authorizedRegistrants[msg.sender],
            "Only the owner or authorized registrants can call this function."
        );
        _;
    }

    modifier onlyIfRegistrationOpen() {
        require(registrationOpen, "Voter registration is closed.");
        _;
    }

    modifier onlyIfVotingOpen() {
        require(votingOpen, "Voting is closed.");
        _;
    }

    constructor() {
        owner = msg.sender;
        registrationOpen = true;
    }

    function openVoting() public onlyOwner {
        require(registrationOpen, "Voting cannot be opened when registration is closed.");
        votingOpen = true;
    }

    function closeVoting() public onlyOwner {
        require(votingOpen, "Voting is not open");
        uint maxVotes = 0;
        uint maxVotesIndex;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                maxVotesIndex = i;
            }
        }
        winnerIndex = maxVotesIndex;
        votingOpen = false;
        emit VotingClosed(winnerIndex);
    }

    // Candidate functions
    function registerCandidate(string memory _name) public onlyAuthorizedRegistrant onlyIfRegistrationOpen {
        require(!isCandidateRegistered(_name), "Candidate with the same name already exists");
        candidates.push(Candidate(_name, 0));
        emit CandidateRegistered(_name, candidates.length.sub(1));
    }

    function isCandidateRegistered(string memory _name) public view returns (bool) {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        for (uint i = 0; i < candidates.length; i++) {
            if (keccak256(abi.encodePacked(candidates[i].name)) == nameHash) {
                return true;
            }
        }
        return false;
    }

    function getCandidateNames() public view returns (string[] memory) {
        string[] memory names = new string[](candidates.length);
        for (uint i = 0; i < candidates.length; i++) {
            names[i] = candidates[i].name;
        }
        return names;
    }

    function getCandidateIndex(string memory _name) public view returns (uint) {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        for (uint i = 0; i < candidates.length; i++) {
            if (keccak256(abi.encodePacked(candidates[i].name)) == nameHash) {
                return i;
            }
        }
        return INVALID_CANDIDATE_INDEX;
    }

    // Voting functions
    function registerVoter() public onlyIfRegistrationOpen {
        require(!voters[msg.sender].registered, "You are already registered.");
        voters[msg.sender].registered = true;
        emit VoterRegistered(msg.sender);
    }

    function isVoterRegistered(address _address) public view returns (bool) {
        return voters[_address].registered;
    }

    function hasVoterVoted(address _address) public view returns (bool) {
        return voters[_address].hasVoted;
    }

    function isVoteOpen() public view returns (bool) {
        return votingOpen;
    }

    function numberOfVotes(string memory _name) public view returns (uint) {
        uint candidateIndex = getCandidateIndex(_name);
        require(candidateIndex != INVALID_CANDIDATE_INDEX, "Invalid candidate name.");
        return candidates[candidateIndex].voteCount;
    }

    // Winner function
    function getWinnerName() public view returns (string memory) {
        require(!votingOpen, "Voting is still open.");
        return candidates[winnerIndex].name;
    }

    // Authorized registrant functions
    function addAuthorizedRegistrant(address _registrant) public onlyOwner {
        authorizedRegistrants[_registrant] = true;
        emit AuthorizedRegistrantAdded(_registrant);
    }

    function removeAuthorizedRegistrant(address _registrant) public onlyOwner {
        authorizedRegistrants[_registrant] = false;
        emit AuthorizedRegistrantRemoved(_registrant);
    }

    // Voting functions
function castVote(string memory _candidateName) public onlyIfVotingOpen {
    require(voters[msg.sender].registered, "You are not registered to vote.");
    require(!voters[msg.sender].hasVoted, "You have already voted.");
    uint candidateIndex = getCandidateIndex(_candidateName);
    require(candidateIndex != INVALID_CANDIDATE_INDEX, "Invalid candidate name.");
    voters[msg.sender].hasVoted = true;
    voters[msg.sender].votedFor = candidateIndex;
    candidates[candidateIndex].voteCount = candidates[candidateIndex].voteCount.add(1);
    emit VoteCasted(msg.sender, candidateIndex);
}
}
