# RPS Contract

This is a smart contract for a Rock-Water-Air-Paper-Sponge-Scissors-Fire game. The contract allows two players to participate and compete against each other.

## Game Rules

- The choices are represented by the following numbers:

  - 0: ROCK
  - 1: WATER
  - 2: AIR
  - 3: PAPER
  - 4: SPONGE
  - 5: SCISSORS
  - 6: FIRE

- Players must commit and reveal their choices within 1 hour of the first player's commit.

- If there are not enough players or not all players committed in time, players can withdraw their bet using the `withdraw` function. The contract owner must manually reset the game.

- If everything goes as planned, the game will automatically restart.

- The winner is determined using modular arithmetic after both players have successfully revealed their choices.

## Contract Functions

### `changeOwner(address newOwner)`

- Only the current owner of the contract can call this function.
- Changes the owner of the contract to the specified `newOwner` address.

### `updateBetAmount(uint _betAmount)`

- Only the owner of the contract can call this function.
- Updates the bet amount to the specified `_betAmount` value.
- Emits a `BetAmountChanged` event with the updated bet amount.

### `commit(bytes32 _commit)`

- Players can call this function to commit their choice.
- Requires that the player has not already committed.
- Requires that the maximum number of players has not been reached.
- Requires that the value sent with the transaction is equal to the current bet amount.
- Adds the player to the list of players with the specified commit.
- Emits a `PlayerCommitted` event with the player's address and commit.

### `reveal(uint num, string memory salt)`

- Players can call this function to reveal their choice.
- Requires that the player has already committed.
- Requires that there are exactly two players.
- Requires that the player has not already revealed.
- Requires that the revealed choice matches the commit.
- Requires that the revealed number is valid (between 0 and 6).
- Updates the player's revealed status and choice.
- Increments the count of players revealed.
- Emits a `PlayerRevealed` event with the player's address, commit, revealed number, and salt.
- If all players have revealed their choices, calls the `determineWinner` function.

### `withdraw()`

- Players can call this function to withdraw their bet.
- Requires that the player has committed.
- Requires that the conditions for withdrawal are met (not enough players or not all players revealed in time).
- Requires that enough time has passed since the first commit.
- Requires that the player has not already withdrawn.
- Transfers the bet amount back to the player.
- Marks the player as withdrawn.

### `manualReset()`

- Only the owner of the contract can call this function.
- Calls the `reset` function to manually reset the game.

## Events

### `BetAmountChanged(uint betAmount)`

- Emitted when the bet amount is changed.
- Contains the updated bet amount.

### `PlayerCommitted(address addr, bytes32 commit)`

- Emitted when a player commits their choice.
- Contains the player's address and commit.

### `PlayerRevealed(address addr, bytes32 commit, uint num, string salt)`

- Emitted when a player reveals their choice.
- Contains the player's address, commit, revealed number, and salt.

### `Winner(address addr, uint num)`

- Emitted when a winner is determined.
- Contains the winner's address and their chosen number.

### `NoWinner()`

- Emitted when there is no winner.
