# StackLock

A small Clarity smart contract to lock STX with a time-based unlock. A sender can deposit STX for a recipient, specify an unlock block height, and optionally allow cancellation before unlock. The contract prevents double-claims and records deposits in a map.

## Features
- Lock STX until a specified block height
- Only designated recipient can withdraw after unlock
- Optional cancelability by the sender before unlock
- Simple deposit indexing via an incrementing counter

## Contract interface

Functions:
- lock-funds(recipient: principal, unlock-block: uint, cancelable: bool, amount: uint) -> (response uint uint)
  - Deposits `amount` STX into the contract and returns deposit-id.
- withdraw(deposit-id: uint) -> (response (string) uint)
  - Recipient withdraws after unlock.
- cancel(deposit-id: uint) -> (response (string) uint)
  - Sender cancels (refund) if deposit is cancelable and before unlock.
- get-deposit(deposit-id: uint) -> (response deposit uint)
  - Read-only view returning the deposit struct.

Deposit struct fields:
- sender: principal
- recipient: principal
- amount: uint
- unlock-block: uint
- cancelable: bool
- claimed: bool

Error codes:
- ERR_INVALID_AMOUNT (u400)
- ERR_INVALID_UNLOCK_BLOCK (u401)
- ERR_NOT_RECIPIENT (u402)
- ERR_ALREADY_CLAIMED (u403)
- ERR_NOT_UNLOCKED (u404)
- ERR_NOT_FOUND (u405)
- ERR_NOT_SENDER (u406)
- ERR_NOT_CANCELABLE (u407)
- ERR_TOO_LATE_TO_CANCEL (u408)

## Quick usage (local development with Clarinet)

Prerequisites:
- Node.js (LTS)
- Clarinet installed globally or in your project (https://github.com/hirosystems/clarinet)

Run tests:
- In PowerShell (Windows):
  - npm install
  - npx clarinet test

Example Clarinet-style test snippet (tests/integration):

```javascript
const { Clarinet, Tx, Chain, Account, types } = require("clarinet");

Clarinet.test("lock -> withdraw flow", async (chain, accounts) => {
  const deployer = accounts.get("deployer");
  const alice = accounts.get("wallet_1");
  const bob = accounts.get("wallet_2");

  // lock 100 STX with unlock block height 10 (relative to chain height)
  const lockTx = Tx.contractCall(
    "stacklock",
    "lock-funds",
    [types.principal(bob.address), types.uint(10), types.bool(true), types.uint(100)],
    alice.address
  );
  let block = chain.mineBlock([lockTx]);

  // simulate advancing blocks to >= unlock block
  for (let i = 0; i < 11; i++) chain.mineEmptyBlock();

  // bob withdraws deposit 0
  const withdrawTx = Tx.contractCall("stacklock", "withdraw", [types.uint(0)], bob.address);
  block = chain.mineBlock([withdrawTx]);

  block.receipts[0].result.expectOk().expectAscii("Withdrawn successfully");
});
```

## Recommended tests
- Successful lock -> withdraw by recipient after unlock
- Reject withdraw by non-recipient
- Successful cancel by sender before unlock when cancelable
- Reject cancel after unlock or when not cancelable
- Prevent double-claiming of a deposit

## Security notes / considerations
- Ensure callers and transfers use correct principals; the contract uses STX transfers and must set the correct sender/recipient principals for as-contract calls.
- Add integration tests to simulate realistic block progression and multi-account interactions.
- Review gas and transfer behavior on mainnet before deploying real funds.

## Deployment
- For local development use Clarinet.
- For testnet/mainnet deployments, use your standard Stacks deployment tooling (stacks.js + wallets, or deploy via an operator). Verify ABI and initial tests on testnet before mainnet.

## License
MIT

```// filepath: c:\Users\USER\Desktop\STACKS\AUGUST\stacklock\README.md
# StackLock

A small Clarity smart contract to lock STX with a time-based unlock. A sender can deposit STX for a recipient, specify an unlock block height, and optionally allow cancellation before unlock. The contract prevents double-claims and records deposits in a map.

## Features
- Lock STX until a specified block height
- Only designated recipient can withdraw after unlock
- Optional cancelability by the sender before unlock
- Simple deposit indexing via an incrementing counter

## Contract interface

Functions:
- lock-funds(recipient: principal, unlock-block: uint, cancelable: bool, amount: uint) -> (response uint uint)
  - Deposits `amount` STX into the contract and returns deposit-id.
- withdraw(deposit-id: uint) -> (response (string) uint)
  - Recipient withdraws after unlock.
- cancel(deposit-id: uint) -> (response (string) uint)
  - Sender cancels (refund) if deposit is cancelable and before unlock.
- get-deposit(deposit-id: uint) -> (response deposit uint)
  - Read-only view returning the deposit struct.

Deposit struct fields:
- sender: principal
- recipient: principal
- amount: uint
- unlock-block: uint
- cancelable: bool
- claimed: bool

Error codes:
- ERR_INVALID_AMOUNT (u400)
- ERR_INVALID_UNLOCK_BLOCK (u401)
- ERR_NOT_RECIPIENT (u402)
- ERR_ALREADY_CLAIMED (u403)
- ERR_NOT_UNLOCKED (u404)
- ERR_NOT_FOUND (u405)
- ERR_NOT_SENDER (u406)
- ERR_NOT_CANCELABLE (u407)
- ERR_TOO_LATE_TO_CANCEL (u408)


Run tests:
- In PowerShell (Windows):
  - npm install
  - npx clarinet test



## License
MIT
