// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";

error Voting__NotTheGoodPhase(); //

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    Proposal[] public proposals;

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    WorkflowStatus phase; // Enum inital value is index 0

    mapping(address => Voter) private _whitelist;

    constructor() {
        _whitelist[msg.sender].isRegistered = true; // Registered the Owner a deploy of the contract
    }

    uint256 winningProposalId = 0;

    modifier onlyVoterRegistered() {
        require(
            _whitelist[msg.sender].isRegistered = true,
            "you are not registered"
        );
        _;
    }

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    //Registration Part

    function RegisteringVoters(address _address) public onlyOwner {
        require(
            phase == WorkflowStatus.RegisteringVoters,
            "The registration session ended"
        ); //check if voter registration isn't finish
        require(
            !_whitelist[_address].isRegistered,
            "This address is already registered !"
        );
        _whitelist[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    function isRegistered(address _address)
        public
        view
        onlyOwner
        returns (bool)
    {
        return _whitelist[_address].isRegistered;
    }

    //Proposal Part

    function setProposals(string memory _proposal) public onlyVoterRegistered {
        //require(_whitelist[msg.sender].isRegistered, "This address isn't registered !");
        if (uint256(getPhase()) != 1) revert Voting__NotTheGoodPhase();
        Proposal memory thisProposal = Proposal(_proposal, 0);
        proposals.push(thisProposal);
        uint256 proposalId = proposals.length; // lenght give use the ID of the new proposal
        emit ProposalRegistered(proposalId);
    }

    //Vote Part

    function setVote(uint256 _index) public onlyVoterRegistered {
        require(
            !_whitelist[msg.sender].hasVoted,
            "You already voted for this session!"
        );
        if (uint256(getPhase()) != 3)
            // check if the vote session start 3 index of the enum
            revert Voting__NotTheGoodPhase();
        _whitelist[msg.sender].hasVoted = true;
        _whitelist[msg.sender].votedProposalId = _index;
        proposals[_index].voteCount++;
        emit Voted(msg.sender, _index);
    }

    function CountVote() external onlyOwner {
        require(
            phase == WorkflowStatus.VotingSessionEnded,
            "Votes session not yet finished."
        );
        uint256 result = 0;
        string memory description;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > result) {
                result = proposals[i].voteCount;
                description = proposals[i].description;
                winningProposalId = i; // store the winner proposal used in getWinningProposal function
            }
        }
    }

    function getWinningProposal() public view returns (Proposal memory) {
        require(
            phase == WorkflowStatus.VotesTallied,
            "Vote count not finished"
        );
        return proposals[winningProposalId]; // return 'description, voteCount'
    }

    //Workflow Part - Only Owner able to change the workflow of the sessions Vote
    //We allow owner to change the status only

    function setRegisteringVotersPhase() external onlyOwner {
        //owner can restart from the beginning the voting process
        WorkflowStatus previousStatus = phase;
        phase = WorkflowStatus.RegisteringVoters;
        emit WorkflowStatusChange(previousStatus, phase);
    }

    function setProposalsRegistrationStartedPhase() external onlyOwner {
        require(
            phase == WorkflowStatus.RegisteringVoters,
            "Need to start with Voters registration phase"
        ); //check if the previous status is Registration of Voters
        WorkflowStatus previousStatus = phase;
        phase = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(previousStatus, phase);
    }

    function setProposalsRegistrationEndedPhase() external onlyOwner {
        require(
            phase == WorkflowStatus.ProposalsRegistrationStarted,
            "The proposals registration isn't started"
        ); //check if proposals registration is open
        WorkflowStatus previousStatus = phase;
        phase = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(previousStatus, phase);
    }

    function setVotingSessionStartedPhase() external onlyOwner {
        require(
            phase == WorkflowStatus.ProposalsRegistrationEnded,
            "The proposals registration isn't finish"
        ); //check if proposals registration is finish
        WorkflowStatus previousStatus = phase;
        phase = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(previousStatus, phase);
    }

    function setVotingSessionEndedPhase() external onlyOwner {
        require(
            phase == WorkflowStatus.VotingSessionStarted,
            "The voting session isn't started"
        ); //check if voting session is open
        WorkflowStatus previousStatus = phase;
        phase = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(previousStatus, phase);
    }

    function setVotesTalliedPhase() external onlyOwner {
        require(
            phase == WorkflowStatus.VotingSessionEnded,
            "The voting session isn't ended"
        ); //check if voting session is closed
        WorkflowStatus previousStatus = phase;
        phase = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(previousStatus, phase);
    }

    //Anyone can ask the current status of the workflow
    function getPhase() public view returns (WorkflowStatus) {
        return phase;
    }
}
