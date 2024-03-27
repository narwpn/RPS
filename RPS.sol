// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract RPS {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    uint public betAmount; // in wei

    constructor(uint _betAmount) {
        owner = msg.sender;
        betAmount = _betAmount;
    }

    event BetAmountChanged(uint betAmount);

    function updateBetAmount(uint _betAmount) public onlyOwner {
        if (_betAmount != betAmount) {
            betAmount = _betAmount;
            emit BetAmountChanged(betAmount);
        }
    }

    struct Player {
        address addr;
        bytes32 commit;
        bool revealed;
        uint num;
        bool withdrawn;
    }

    uint public firstCommitTimeStamp;
    mapping(address => bool) public isPlayer;
    mapping(address => uint) public playerIndex;
    Player[] public players;
    uint public playersRevealed = 0;
    bool public thereIsWinner = false;
    address public winner;

    function listPlayers() public view returns (Player[] memory) {
        return players;
    }

    event PlayerCommitted(address addr, bytes32 commit);

    function commit(bytes32 _commit) public payable {
        require(!isPlayer[msg.sender], "Player already commited");
        require(players.length < 2, "Maximum number of players reached");
        require(msg.value == betAmount, "Invalid value");
        isPlayer[msg.sender] = true;
        playerIndex[msg.sender] = players.length;
        players.push(Player(msg.sender, _commit, false, 0, false));
        if (players.length == 1) {
            firstCommitTimeStamp = block.timestamp;
        }
        emit PlayerCommitted(msg.sender, _commit);
    }

    event PlayerRevealed(address addr, bytes32 commit, uint num, string salt);

    function reveal(uint num, string memory salt) public {
        require(isPlayer[msg.sender], "Player has not commited");
        require(players.length == 2, "Not enough players");
        require(
            !players[playerIndex[msg.sender]].revealed,
            "Player already revealed"
        );
        require(
            keccak256(abi.encodePacked(num, salt)) ==
                players[playerIndex[msg.sender]].commit,
            "Invalid reveal"
        );
        require(num >= 0 && num <= 6, "Invalid number");
        players[playerIndex[msg.sender]].revealed = true;
        players[playerIndex[msg.sender]].num = num;
        playersRevealed++;
        emit PlayerRevealed(
            msg.sender,
            players[playerIndex[msg.sender]].commit,
            num,
            salt
        );
        if (playersRevealed == players.length) {
            determineWinner();
        }
    }

    event Winner(address addr, uint num);
    event NoWinner();

    function determineWinner() private {
        require(playersRevealed == players.length, "Not all players revealed");
        uint difference = (players[0].num - players[1].num + 7) % 7;
        if (difference == 1 || difference == 2 || difference == 5) {
            winner = players[0].addr;
            thereIsWinner = true;
            players[0].withdrawn = true;
            payable(winner).transfer(betAmount * 2);
            emit Winner(winner, players[0].num);
        } else if (difference == 4 || difference == 3 || difference == 6) {
            winner = players[1].addr;
            thereIsWinner = true;
            players[1].withdrawn = true;
            payable(winner).transfer(betAmount * 2);
            emit Winner(winner, players[1].num);
        } else {
            thereIsWinner = false;
            players[0].withdrawn = true;
            players[1].withdrawn = true;
            payable(players[0].addr).transfer(betAmount);
            payable(players[1].addr).transfer(betAmount);
            emit NoWinner();
        }
        reset();
    }

    function reset() private {
        require(
            players[0].withdrawn && players[1].withdrawn,
            "Players have not withdrawn"
        );
        for (uint i = 0; i < players.length; i++) {
            isPlayer[players[i].addr] = false;
            playerIndex[players[i].addr] = 0;
        }
        delete firstCommitTimeStamp;
        delete players;
        delete playersRevealed;
        delete thereIsWinner;
        delete winner;
    }

    function manualReset() public onlyOwner {
        require(
            players[0].withdrawn && players[1].withdrawn,
            "Players have not withdrawn"
        );
        reset();
    }

    function withdraw() public {
        // players can withdraw in case not enough players have succesfully commited or revealed in time
        require(isPlayer[msg.sender], "Player has not commited");
        require(
            this.players.length < 2 || playersRevealed < players.length,
            "Invalid conditions"
        );
        require(
            block.timestamp > firstCommitTimeStamp + 3600,
            "Not enough time has passed"
        );
        require(
            !players[playerIndex[msg.sender]].withdrawn,
            "Player already withdrawn"
        );
        players[playerIndex[msg.sender]].withdrawn = true;
        payable(msg.sender).transfer(betAmount);
    }
}
