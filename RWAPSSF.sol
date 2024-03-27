// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract RWAPSSF {
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
        bytes32 commit1;
        bytes32 commit2;
        bool revealed;
        uint num1;
        uint num2;
        bool withdrawn;
    }

    uint public firstCommitTimeStamp;
    mapping(address => bool) public isPlayer;
    mapping(address => uint) public playerIndex;
    Player[] public players;
    uint public playersRevealed = 0;
    uint[] public playerPoints;
    bool public thereIsWinner = false;
    address public winner;

    function listPlayers() public view returns (Player[] memory) {
        return players;
    }

    event PlayerCommitted(address addr, bytes32 commit1, bytes32 commit2);

    function commit(bytes32 commit1, bytes32 commit2) public payable {
        require(!isPlayer[msg.sender], "Player already commited");
        require(players.length < 2, "Maximum number of players reached");
        require(msg.value == betAmount, "Invalid value");
        isPlayer[msg.sender] = true;
        playerIndex[msg.sender] = players.length;
        players.push(Player(msg.sender, commit1, commit2, false, 0, 0, false));
        if (players.length == 1) {
            firstCommitTimeStamp = block.timestamp;
        }
        emit PlayerCommitted(msg.sender, commit1, commit2);
    }

    event PlayerRevealed(
        address addr,
        bytes32 commit1,
        bytes32 commit2,
        uint num1,
        uint num2,
        string salt1,
        string salt2
    );

    function reveal(
        uint num1,
        uint num2,
        string memory salt1,
        string memory salt2
    ) public {
        require(isPlayer[msg.sender], "Player has not commited");
        require(players.length == 2, "Not enough players");
        require(
            !players[playerIndex[msg.sender]].revealed,
            "Player already revealed"
        );

        require(
            keccak256(abi.encodePacked(num1, salt1)) ==
                players[playerIndex[msg.sender]].commit1,
            "Invalid reveal 1"
        );
        require(num1 >= 0 && num1 <= 6, "Invalid number 1");

        require(
            keccak256(abi.encodePacked(num2, salt2)) ==
                players[playerIndex[msg.sender]].commit2,
            "Invalid reveal 2"
        );
        require(num2 >= 0 && num2 <= 6, "Invalid number 2");

        players[playerIndex[msg.sender]].revealed = true;
        players[playerIndex[msg.sender]].num1 = num1;
        players[playerIndex[msg.sender]].num2 = num2;
        playersRevealed++;
        emit PlayerRevealed(
            msg.sender,
            players[playerIndex[msg.sender]].commit1,
            players[playerIndex[msg.sender]].commit2,
            num1,
            num2,
            salt1,
            salt2
        );
        if (playersRevealed == players.length) {
            determineWinner();
        }
    }

    event Winner(address addr, uint num1, uint num2);
    event NoWinner();

    function determineWinner() private {
        require(playersRevealed == players.length, "Not all players revealed");

        uint difference = (players[0].num1 - players[1].num1 + 7) % 7;
        if (difference == 1 || difference == 2 || difference == 5) {
            playerPoints[0] += 2;
        } else if (difference == 4 || difference == 3 || difference == 6) {
            playerPoints[1] += 2;
        } else {
            playerPoints[0] += 1;
            playerPoints[1] += 1;
        }

        difference = (players[0].num2 - players[1].num2 + 7) % 7;
        if (difference == 1 || difference == 2 || difference == 5) {
            playerPoints[0] += 2;
        } else if (difference == 4 || difference == 3 || difference == 6) {
            playerPoints[1] += 2;
        } else {
            playerPoints[0] += 1;
            playerPoints[1] += 1;
        }

        if (playerPoints[0] > playerPoints[1]) {
            winner = players[0].addr;
            thereIsWinner = true;
            players[0].withdrawn = true;
            payable(winner).transfer(betAmount * 2);
            emit Winner(winner, players[0].num1, players[1].num2);
        } else if (playerPoints[0] < playerPoints[1]) {
            winner = players[1].addr;
            thereIsWinner = true;
            players[1].withdrawn = true;
            payable(winner).transfer(betAmount * 2);
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
        delete playerPoints;
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
            players.length < 2 || playersRevealed < players.length,
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
