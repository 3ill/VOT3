// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Ballot contract
 * @author 3illBaby
 * @notice A simple Governance solution
 */

contract Ballot {
    //? Declared the contract events
    event voterRegistered(address indexed voter);
    event proposalCreated(string newProposal);
    event proposalsReset();
    event votersAndAddressesReset();

    //? contract strct
    struct Voter {
        uint weight;
        bool voted;
        uint vote;
    }

    struct Proposal {
        string name;
        uint voteCount;
    }

    //? this enum keeps track of the voting stages
    enum Stage {
        init,
        reg,
        vote,
        done
    }

    //! contract states
    address private immutable chairPerson;
    mapping(address => Voter) voters;
    Proposal[] public proposals;
    address[] public Voters;
    Stage public stage = Stage.init;
    uint public startTime;

    /**
     * ! The constructor sets the deployer of the contract as the chairperson
     * ? it also sets the enum stage to reg
     */
    constructor() {
        chairPerson = msg.sender;
        voters[chairPerson].weight = 2;
        stage = Stage.reg;
        startTime = block.timestamp;
    }

    modifier onlyChairPerson() {
        require(
            msg.sender == chairPerson,
            "Only chairPerson can call this function"
        );
        _;
    }

    modifier stageCompliance(Stage _stage) {
        require(stage == _stage, "Invalid stage");
        _;
    }

    modifier blankAddressCompliance(address[] memory _addresses) {
        require(_addresses.length > 0, "Array cannot be empty");
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Cannot add a blank address");
        }
        _;
    }

    modifier blankStringCompliance(string memory _name) {
        require(bytes(_name).length > 0, "This field can't be left blank");
        _;
    }

    /**
     * ! This function creates a proposal and can be called by any address
     * @param _proposalName the name of the proposal is passed as a paramneter
     */
    function createProposal(
        string memory _proposalName
    ) public blankStringCompliance(_proposalName) {
        proposals.push(Proposal({name: _proposalName, voteCount: 0}));
        emit proposalCreated(_proposalName);
    }

    /**
     * !This function is used for register voters
     * ? only the chairperson can call this function
     * @param _voters this takes an array of address to register as voters
     */
    function registerVoters(
        address[] memory _voters
    ) public onlyChairPerson blankAddressCompliance(_voters) {
        for (uint256 i = 0; i < _voters.length; i++) {
            address _voter = _voters[i];
            require(isNewVoter(_voter), "Voter already added");
            require(
                voteCompliance(_voter),
                "Voter does not meet compliance criteria"
            );
            voters[_voter] = Voter({weight: 1, voted: false, vote: 0});
            Voters.push(_voter);
            emit voterRegistered(_voter);
        }

        if (block.timestamp >= (startTime + 30 seconds)) {
            stage = Stage.vote;
            startTime = block.timestamp;
        }
    }

    /**
     * ? This functio returns true if the voters weight is equal to 0
     * @param _voterAddress this takes ab address as a parameter
     */
    function isNewVoter(address _voterAddress) internal view returns (bool) {
        return voters[_voterAddress].weight == 0;
    }

    /**
     *? This function returns true if the voter hasn't voted on any proposal
     * @param _voterAddress this takes an address as a parameter
     */
    function voteCompliance(
        address _voterAddress
    ) internal view returns (bool) {
        return voters[_voterAddress].vote == 0;
    }

    /**
     * ! Only a registered voter can call this function
     * ? This function is called to vote on a proposal
     * @param _proposal this accepts a proposal index as a parameter
     */
    function vote(uint _proposal) public stageCompliance(Stage.vote) {
        require(_proposal < proposals.length, "Proposal does not exist");
        require(voteCompliance(msg.sender), "Already voted");
        require(!isNewVoter(msg.sender), "Sender has no voting rights");

        Voter storage sender = voters[msg.sender];
        sender.voted = true;
        sender.vote = _proposal;

        proposals[_proposal].voteCount += sender.weight;

        if (block.timestamp >= (startTime + 30 seconds)) {
            stage = Stage.done;
            startTime = block.timestamp;
        }
    }

    //? This function gets all the voters
    function getAllVoters() public view returns (address[] memory) {
        address[] memory _voters = new address[](Voters.length);
        for (uint256 i = 0; i < Voters.length; i++) {
            _voters[i] = Voters[i];
        }

        return _voters;
    }

    //? this calculates the proposal with the highest vote count
    function winningProposal()
        internal
        view
        stageCompliance(Stage.done)
        returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    //? this function reveals the winning proposal name
    function revealWinningProposal()
        public
        view
        returns (string memory winner)
    {
        uint256 winningIndex = winningProposal();
        string memory _winner = proposals[winningIndex].name;
        return _winner;
    }

    //? this is a function to delete the proposal array and can only be called by the chairperson
    function resetProposals()
        internal
        onlyChairPerson
        stageCompliance(Stage.done)
    {
        delete proposals;
        emit proposalsReset();
    }

    //? This is a reset function and can only be called by the chairperson
    function resetVotersAndAddresses()
        external
        onlyChairPerson
        stageCompliance(Stage.done)
    {
        for (uint256 i = 0; i < Voters.length; i++) {
            address _voter = Voters[i];
            delete voters[_voter];
        }

        delete Voters;
        emit votersAndAddressesReset();
    }
}
