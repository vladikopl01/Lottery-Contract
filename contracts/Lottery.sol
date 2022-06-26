// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBaseV2 {
    enum Stages {
        NEW,
        IN_PROGRESS,
        FINALIZING_RESULTS,
        FINISHED
    }

    uint8 private constant MAX_TICKETS_TO_BUY = 10;
    uint16 private constant MAX_TICKET_NUMBER = 1000;

    Stages private _stage = Stages.NEW;
    uint256 private immutable _creationTime = block.timestamp;
    address private immutable _owner;
    uint256 private immutable _durationBetweenStages;
    uint256 private immutable _pricePerTicket;

    mapping(address => uint16[]) private _participantTickets;
    mapping(uint16 => address[]) private _ticketParticipants;

    uint16 private _maxTicketValue;

    uint256 private _participantRewards;
    uint256 private _ownerRewards;

    mapping(address => bool) private _receivedRewards;

    event StageChangedTo(Stages _newStage);
    event TicketsBought(address indexed _participant, uint8 _numberOfTickets);
    event RevealResults(
        uint256 _onwerRewards,
        uint256 _participantRewards,
        address[] _participants
    );
    event WithdrawRewards(address indexed _participant, uint256 _reward);

    VRFCoordinatorV2Interface internal immutable vrfCoordinator;
    bytes32 internal immutable keyHash;
    uint64 internal immutable subscriptionId;
    uint32 internal immutable callbackGasLimit;
    uint16 internal immutable requestConfirmations;

    mapping(uint256 => address) internal requestToSender;
    uint256 internal randomRequests;

    event RandomnessRequested(uint256 indexed requestId);

    constructor(
        address owner_,
        uint256 durationBetweenStages_,
        uint256 pricePerTicket_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint32 callbackGasLimit_,
        uint16 requestConfirmations_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        _owner = owner_;
        _durationBetweenStages = durationBetweenStages_;
        _pricePerTicket = pricePerTicket_;
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        callbackGasLimit = callbackGasLimit_;
        requestConfirmations = requestConfirmations_;
    }

    modifier atStage(Stages stage_) {
        require(_stage == stage_, "Lottery: invalid stage");
        _;
    }

    modifier transitionAfter() {
        _;
        nextStage();
    }

    modifier timedTransition() {
        if (
            _stage == Stages.NEW &&
            block.timestamp >= _creationTime + _durationBetweenStages
        ) {
            nextStage();
        } else if (
            _stage == Stages.IN_PROGRESS &&
            block.timestamp >= _creationTime + _durationBetweenStages * 2
        ) {
            nextStage();
        } else if (
            _stage == Stages.FINALIZING_RESULTS &&
            block.timestamp >= _creationTime + _durationBetweenStages * 3
        ) {
            nextStage();
        }
        _;
    }

    function getMyTickets() public view returns (uint16[] memory) {
        return _participantTickets[msg.sender];
    }

    function buyTickets()
        public
        payable
        timedTransition
        atStage(Stages.IN_PROGRESS)
    {
        require(
            msg.value >= _pricePerTicket,
            "Lottery: insufficient ether value"
        );

        uint8 ticketsToBuy;
        if (msg.value >= MAX_TICKETS_TO_BUY * _pricePerTicket) {
            ticketsToBuy = MAX_TICKETS_TO_BUY;
        } else {
            ticketsToBuy = uint8(msg.value / _pricePerTicket);
        }

        uint8 existsTickets = uint8(_participantTickets[msg.sender].length);
        require(
            existsTickets + ticketsToBuy <= MAX_TICKETS_TO_BUY,
            "Lottery: exceeded limit of tickets"
        );

        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            ticketsToBuy
        );

        requestToSender[requestId] = msg.sender;
        randomRequests++;

        uint256 ticketsPrice = ticketsToBuy * _pricePerTicket;
        if (msg.value > ticketsPrice) {
            payable(msg.sender).transfer(msg.value - ticketsPrice);
        }

        emit RandomnessRequested(requestId);
        emit TicketsBought(msg.sender, ticketsToBuy);
    }

    function revealResults()
        public
        timedTransition
        atStage(Stages.FINALIZING_RESULTS)
        transitionAfter
    {
        require(
            randomRequests == 0,
            "Lottery: not all requests are fullfilled"
        );

        uint256 currentBalance = address(this).balance;
        _ownerRewards = currentBalance / 10;
        _participantRewards =
            (currentBalance - _ownerRewards) /
            _ticketParticipants[_maxTicketValue].length;

        emit RevealResults(
            _ownerRewards,
            _participantRewards,
            _ticketParticipants[_maxTicketValue]
        );
    }

    function withdrawRewards() public atStage(Stages.FINISHED) {
        require(
            _receivedRewards[msg.sender] == false,
            "Lottery: sender has already received the reward"
        );

        if (_owner == msg.sender) {
            (bool sent, ) = msg.sender.call{value: _ownerRewards}("");
            require(sent == true, "Lottery: failed to send rewards");

            emit WithdrawRewards(msg.sender, _ownerRewards);
        } else {
            bool isSenderWins;
            uint8 boughtTickets = uint8(_participantTickets[msg.sender].length);

            require(boughtTickets > 0, "Lottery: sender is not participating");

            for (uint8 i = 0; i < boughtTickets; i++) {
                if (_participantTickets[msg.sender][i] == _maxTicketValue) {
                    isSenderWins = true;
                    break;
                }
            }

            require(isSenderWins == true, "Lottery: sender is not a winner");

            (bool sent, ) = msg.sender.call{value: _participantRewards}("");
            require(sent == true, "Lottery: failed to send rewards");

            emit WithdrawRewards(msg.sender, _participantRewards);
        }

        _receivedRewards[msg.sender] = true;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomNumbers
    ) internal override {
        require(
            requestToSender[requestId] != address(0),
            "Lottery: no such request"
        );

        uint256 arrayLength = randomNumbers.length;
        for (uint8 i = 0; i < arrayLength; i++) {
            uint16 ticket = uint16((randomNumbers[i] % MAX_TICKET_NUMBER) + 1);
            if (_maxTicketValue < ticket) {
                _maxTicketValue = ticket;
            }
            address sender = requestToSender[requestId];
            _ticketParticipants[ticket].push(sender);
            _participantTickets[sender].push(ticket);
        }

        delete requestToSender[requestId];
        randomRequests--;
    }

    function nextStage() internal {
        _stage = Stages(uint256(_stage) + 1);

        emit StageChangedTo(_stage);
    }
}
