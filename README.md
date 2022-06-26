# Lottery contract

**Implement a lottery contract that meets the following conditions:**

1. New lotteries must be created through the factory. Creation is possible only by the owner of the factory. The factory must keep the addresses of all lotteries created by it.
2. The lottery contract must have 3 states: _NEW_, _IN_PROGRESS_, _FINALIZING_RESULTS_, _FINISHED_. Each of these states is determined by a certain period of time that is specified when creating a contract.
3. It is impossible to buy tickets in the _NEW_ state.
4. In the _IN_PROGRESS_ state, users can purchase tickets. Each user can buy up to 10 tickets. All 10 tickets can be purchased in one transaction.
5. Each ticket has a fixed price in coins (ETH). The price is specified when creating a contract.
6. For each ticket the user receives one random number from 1 to 1000
7. In the _FINALIZING_RESULTS_ state, the lottery results are calculated. The transition to the next state is possible only after complete processing of the results.
8. After the contract becomes _FINISHED_, the factory owner has the opportunity to withdraw exactly 10% of the funds collected.
9. The remaining funds should be divided between the users who dropped the most random number.

**External part of oracle is not included in the task**

**Will be a plus:**

1. Configure the development environment (Truffle, Hardhat, etc).
2. Cover the functionality of the factory and lottery with tests.
