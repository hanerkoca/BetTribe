# BetTribe

## Overview

**BetTribe** is a decentralized betting platform designed for football fans to create and join private betting groups. With BetTribe, users can form groups, place bets on football matches, and distribute winnings transparently and fairly. The platform ensures a secure and engaging experience for group-based betting. BetTribe is currently deployed on the Scroll Network (Sepolia Testnet) for testing.

## Features

- **Group Creation**: Users can create private betting groups for specific football matches.
- **Betting Options**: Participants can place bets on three possible outcomes: home win, draw, or away win.
- **Commission System**: The platform takes a small commission on winnings to support its operations.
- **Winnings Distribution**: Winnings are distributed to correct betters or refunded if no bets are correct.
- **Group Management**: Creators can manage group settings and cancel groups if necessary.
- **Match Details**: View detailed information about football matches available for betting.
- **Security**: Transactions are secure, and while the contract owner currently manages match creation and winnings distribution, future updates will integrate Chainlink oracles to automate these processes and ensure accuracy without requiring owner intervention.

## Smart Contract Functions

### `createMatch(string memory _homeTeam, string memory _awayTeam, uint256 _matchTime)`

Creates a new football match. This function is restricted to the contract owner.

- **Parameters**:
  - `_homeTeam`: Name of the home team.
  - `_awayTeam`: Name of the away team.
  - `_matchTime`: Timestamp when the match will start.

### `createGroup(uint256 _betValue, uint256 _matchId, uint8 _maxParticipants, string memory _password, uint8 _creatorBet)`

Creates a new betting group. Allows the creator to place their bet at the time of group creation.

- **Parameters**:
  - `_betValue`: The amount of ETH each participant must bet (in Wei).
  - `_matchId`: ID of the match this group is for.
  - `_maxParticipants`: Maximum number of participants allowed in the group.
  - `_password`: Password required to join the group.
  - `_creatorBet`: Bet placed by the group creator.

### `joinGroup(uint256 _groupId, string memory _password, uint8 _bet)`

Allows a user to join an existing group and place their bet.

- **Parameters**:
  - `_groupId`: ID of the group to join.
  - `_password`: Password for the group.
  - `_bet`: Bet option (1 for home win, 0 for draw, 2 for away win).

### `distributeWinnings(uint256 _groupId, uint8 _winningBet)`

Distributes winnings based on the correct bet. Only accessible by the contract owner.

- **Parameters**:
  - `_groupId`: ID of the group for which winnings are distributed.
  - `_winningBet`: The winning bet option (1 for home win, 0 for draw, 2 for away win).

### `cancelGroup(uint256 _groupId)`

Allows the group creator to cancel the group and refund all participants, only if the group is not full.

- **Parameters**:
  - `_groupId`: ID of the group to cancel.

### `viewMatch(uint256 _matchId)`

Retrieves details of a football match.

- **Parameters**:
  - `_matchId`: ID of the match to view.

### `viewParticipants(uint256 _groupId)`

Retrieves the list of participants in a betting group.

- **Parameters**:
  - `_groupId`: ID of the group to view participants for.

## Future Enhancements

**BetTribe** is designed with scalability and future growth in mind. Upcoming enhancements include:

- **Integration with Chainlink**: To ensure accurate match results and reliable data feeds, we plan to integrate Chainlink oracles. This will provide real-time match results and automate the outcome verification process.
  
- **User Interface Development**: We aim to develop a web-based interface and a mobile application to make it easier for users to interact with BetTribe. The UI will allow users to create groups, place bets, view match results, and manage their accounts with ease.

- **Expanded Functionality**: Future updates may include additional betting options, support for more sports, and enhanced features based on user feedback and technological advancements.

## Deployment

BetTribe is currently deployed on the **Scroll Network (Sepolia Testnet)**.