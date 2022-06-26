// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./Lottery.sol";

contract LotteryFactory is Ownable {
    VRFCoordinatorV2Interface internal immutable coordinator;
    LinkTokenInterface internal immutable linkToken;

    Lottery[] private _lotteries;

    address internal immutable vrfCoordinatorAddress;
    address internal immutable linkTokenAddress;
    bytes32 internal immutable keyHash;
    uint64 internal subscriptionId;
    uint32 internal callbackGasLimit;
    uint16 internal requestConfirmations;

    constructor(
        address vrfCoordinatorAddress_,
        address linkTokenAddress_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint32 callbackGasLimit_,
        uint16 requestConfirmations_
    ) {
        coordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress_);
        linkToken = LinkTokenInterface(linkTokenAddress_);

        vrfCoordinatorAddress = vrfCoordinatorAddress_;
        linkTokenAddress = linkTokenAddress_;
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        callbackGasLimit = callbackGasLimit_;
        requestConfirmations = requestConfirmations_;
    }

    function getLottery(uint256 lotteryId_) external view returns (Lottery) {
        require(
            lotteryId_ < _lotteries.length,
            "LotteryFactory: invalid lottery id"
        );
        return _lotteries[lotteryId_];
    }

    function getLastLottery() external view returns (Lottery) {
        require(_lotteries.length > 0, "LotteryFactory: no lotteries yet");
        return _lotteries[_lotteries.length - 1];
    }

    function getAllLotteries() external view returns (Lottery[] memory) {
        return _lotteries;
    }

    function updateVRFConfiguration(
        uint32 callbackGasLimit_,
        uint16 requestConfirmations_
    ) external onlyOwner {
        callbackGasLimit = callbackGasLimit_;
        requestConfirmations = requestConfirmations_;
    }

    function createLottery(
        uint256 durationBetweenStages_,
        uint256 pricePerTicket_
    ) external onlyOwner {
        require(
            pricePerTicket_ > 0,
            "LotteryFactory: invalid price per ticket"
        );

        Lottery lottery = new Lottery(
            owner(),
            durationBetweenStages_,
            pricePerTicket_,
            vrfCoordinatorAddress,
            keyHash,
            subscriptionId,
            callbackGasLimit,
            requestConfirmations
        );
        _lotteries.push(lottery);
        coordinator.addConsumer(subscriptionId, address(lottery));
    }

    function createNewSubscription() external onlyOwner {
        require(
            subscriptionId == 0,
            "LotteryFactory: subscription already created"
        );
        subscriptionId = coordinator.createSubscription();
    }

    function topUpSubscription(uint256 amount_) external onlyOwner {
        linkToken.transferAndCall(
            address(coordinator),
            amount_,
            abi.encode(subscriptionId)
        );
    }

    function cancelSubscription() external onlyOwner {
        require(
            subscriptionId != 0,
            "LotteryFactory: subscription already canceled"
        );
        coordinator.cancelSubscription(subscriptionId, owner());
        subscriptionId = 0;
    }

    function addConsumer(address consumerAddress_) external onlyOwner {
        require(
            consumerAddress_ != address(0),
            "LotteryFactory: consumer is the zero address"
        );
        coordinator.addConsumer(subscriptionId, consumerAddress_);
    }

    function removeConsumer(address consumerAddress_) external onlyOwner {
        require(
            consumerAddress_ != address(0),
            "LotteryFactory: consumer is the zero address"
        );
        coordinator.removeConsumer(subscriptionId, consumerAddress_);
    }

    function withdrawLinkToken(uint256 amount_, address to_)
        external
        onlyOwner
    {
        require(
            to_ != address(0),
            "LotteryFactory: transfer to the zero address"
        );
        linkToken.transfer(to_, amount_);
    }
}
