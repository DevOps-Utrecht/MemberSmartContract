pragma solidity ^0.4.24;

contract Voter {
    enum Action { REMOVE_MEMBER, ADD_MEMBER }
    
    string public subject;
    DevOps parent;
    address public proposal;
    uint32 public count = 0;
    Action action;
    
    mapping(address => bool) voted;
    
    modifier OnlyActiveMembers(address _a) {
        require(parent.is_member(_a));
        _;
    }
    
    modifier NotVoted(address _a) {
        require(!voted[_a]);
        _;
    }
    
    constructor(address _proposal, string _subject, Action _action) public payable {
        subject = _subject;
        parent = DevOps(tx.origin);
        proposal = _proposal;
        action = _action;
    }
    
    //Known issue: parent contract is probably not correctly referenced.
    function Vote() public OnlyActiveMembers(msg.sender) NotVoted(msg.sender) {
        count++;
        voted[msg.sender] = true;
        if (count * 3 >= parent.get_member_count() * 2) {
            if (action == Action.REMOVE_MEMBER)
                parent.remove_member(proposal);
        }
    }
}

contract DevOps {
    //EVENTS
    event NewMember(address id); //Can be used to derive all the members
    event NewVoteContract(address location);
    
    struct Member {
        string name;
        string role;
        bool active;    
    }
    
    string public name = "DevOps";
    //Keep track of the members
    mapping(address => Member) public members;
    //Keep track of voter contracts
    mapping(address => bool) public voters;
    //Keep track of members in a countable array
    Member[] member_array;
    
    modifier OnlyActiveMembers(address _a) {
        require(members[_a].active);
        _;
    }
    
    modifier IsVoterContract(address _a) {
        assert(voters[_a]);
        _;
    }
    
    constructor(string _name, string _role) public {
        members[msg.sender] = CreateMember(_name, _role);
    }
    
    function CreateMember(string _name, string _role) private returns(Member) {
        Member memory m = Member({
            name:_name,
            role:_role,
            active: true
        });
        member_array.push(m);
        return m;
    }
    
    function add_member(address _proposal, string _name, string _role) public OnlyActiveMembers(msg.sender) {
        Member memory m = CreateMember(_name, _role);
        members[_proposal] = m;
        emit NewMember(_proposal);
    }
    
    function propose_member_removal(address _proposal, string _subject) public OnlyActiveMembers(msg.sender) returns (address) {
        address c = new Voter(_proposal, _subject, Voter.Action.REMOVE_MEMBER);
        voters[c] = true;
        emit NewVoteContract(c);
        return c;
    }
    
    function is_member(address _a) public view returns (bool) {
        return members[_a].active;
    }
    
    function get_member_count() view public returns (uint32) {
        uint32 sum = 0;
        for(uint32 i=0; i<member_array.length; i++) {
            if (member_array[i].active) {
                sum++;
            }
        }
        return sum;
    }
    
    function remove_member(address _a) public IsVoterContract(_a) {
        members[_a].active = false;
    }
}
