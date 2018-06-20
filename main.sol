pragma solidity ^0.4.24;

contract Voter {
    string public subject;
    DevOps public parent;
    uint32 public count = 0;
    uint256 birthday;
    
    mapping(address => bool) public voted;
    
    modifier OnlyActiveMembers(address _a) {
        require(parent.is_member(_a));
        _;
    }
    
    modifier NotVoted(address _a) {
        require(!voted[_a]);
        _;
    }
    
    modifier Alive() {
        require(block.number - birthday < 40000);
        _;
    }
    
    constructor(string _subject) public {
        subject = _subject;
        parent = DevOps(msg.sender);
        birthday = block.number;
    }
    
    function Vote() public OnlyActiveMembers(msg.sender) NotVoted(msg.sender) Alive() {
        count++;
        voted[msg.sender] = true;
        if (Eval()) {
            selfdestruct(parent);
        }
    }
    
    function Eval() private returns (bool);
}

contract RemoveMemberVoter is Voter {
    address public proposal;
    
    constructor(address _proposal, string _subject) Voter(_subject) public {
        proposal = _proposal;
    }
    
    function Eval() private returns (bool){
        if (count * 3 >= parent.get_member_count() * 2) {
            parent.remove_member(proposal);
            return true;
        }
        return false;
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
        members[_proposal] = CreateMember(_name, _role);
        emit NewMember(_proposal);
    }
    
    function propose_member_removal(address _proposal, string _subject) public OnlyActiveMembers(msg.sender) returns (address) {
        address c = new RemoveMemberVoter(_proposal, _subject);
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
    
    function remove_member(address _a) public IsVoterContract(msg.sender) {
        members[_a].active = false;
    }
}
