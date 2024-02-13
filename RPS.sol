// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "contracts/CommitReveal.sol";
import "contracts/Ownable.sol";

contract RPS is CommitReveal, Ownable{

    uint public entryFee;
    address[] public players;
    mapping(address => bool) public isInGame;
    mapping(address => uint) public blockNumWhenJoined;
    mapping(address => uint) public playerChoice;
    uint numCommited;
    uint numRevealed;
    address public winner;

    constructor() {
        entryFee = 1 wei;
    }

    function setEntryFee(uint _entryFee) public onlyOwner {
        entryFee = _entryFee;
    }

    modifier onlyPlayers() {
        require(isInGame[msg.sender]);
        _;
    }

    function addPlayer() public payable {
        require(players.length < 2);
        require(msg.value == entryFee);
        players.push(msg.sender);
        isInGame[msg.sender] = true;
    }

    function makeChoice(bytes32 choiceHash) public onlyPlayers() {
        require(players.length == 2);
        require(commits[msg.sender].commit == 0);
        commit(choiceHash);
        numCommited++;
        if (numCommited == 2) {
            emit AllPlayersMadeChoice();
        }
    }

    event AllPlayersMadeChoice();

    function revealChoice(uint choice, bytes32 salt) public onlyPlayers(){
        require(players.length == 2);
        require(numCommited == 2);
        require(commits[msg.sender].revealed == false);
        require(choice == 0 || choice == 1 || choice == 2);
        revealAnswer(bytes32(choice), salt);
        playerChoice[msg.sender] = choice;
        numRevealed++;
        if (numRevealed == 2) {
            emit AllPlayersRevealedChoice();
            _determineWinner();
        }
    }

    event AllPlayersRevealedChoice();

    function cancelGame() public onlyPlayers() {
        require(block.number > blockNumWhenJoined[msg.sender] + 250);
        if (players.length < 2 || numCommited < 2 || numRevealed < 2) {
            for (uint i = 0; i < players.length; i++) {
                payable(players[i]).transfer(entryFee);
                _resetGame();
            }
        }
    }

    function _resetGame() private {
        for (uint i = 0; i < players.length; i++) {
            isInGame[players[i]] = false;
            blockNumWhenJoined[players[i]] = 0;
            playerChoice[players[i]] = 0;
        }
        players = new address[](0);
        numCommited = 0;
        numRevealed = 0;
        winner = address(0);
    }

    function _determineWinner() private {
        if (playerChoice[players[0]] == playerChoice[players[1]]) {
            winner = address(0);
        } else if (playerChoice[players[0]] == 0 && playerChoice[players[1]] == 2) {
            winner = players[0];
        } else if (playerChoice[players[0]] == 1 && playerChoice[players[1]] == 0) {
            winner = players[0];
        } else if (playerChoice[players[0]] == 2 && playerChoice[players[1]] == 1) {
            winner = players[0];
        } else {
            winner = players[1];
        }
        if (winner != address(0)) {
            payable(winner).transfer(entryFee * 2);
        }
        _resetGame();
    }
}
