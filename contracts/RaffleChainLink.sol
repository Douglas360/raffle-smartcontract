// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts@1.1.0/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts@1.1.0/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts@1.1.0/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract RaffleV2ChainLink is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RaffleCreated(
        uint256 id,
        string name,
        uint256 ticketPrice,
        uint256 ticketCount
    );
    event TicketBought(uint256 id, address participant, uint256 ticketCount);
    event RaffleWinner(uint256 id, address winner, uint256 numberSelected);

    address public ownerContract;
    uint256 private raffleCount = 0;
    uint256 private fee = 10; // 10% fee
    uint256 private numberSelected = 0;

    struct Raffle {
        address owner;
        uint256 id;
        string name;
        string image;
        uint256 ticketPrice; //preço do ticket
        uint256 ticketCount; // quantidade de tickets
        uint256 ticketSold; // quantidade de tickets vendidos
        uint256 totalAmountToWin; // total de dinheiro a ser sorteado
        bool isActive;
        uint256 createadAt;
        address winner;
        bool isWhidrawn;
    }

    struct Ticket {
        uint256 ticketNumber;
        uint256 raffleId;
        address participant;
        uint256 createdAt;
        Raffle raffleinfo;
    }

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => Ticket[]) internal raffleTickets;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     */
    constructor(
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0x2eD832Ba664535e5886b75D64C46EB9a228C2610)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2eD832Ba664535e5886b75D64C46EB9a228C2610
        );
        s_subscriptionId = subscriptionId;
        //ownerContract = msg.sender;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        numberSelected = _randomWords[0] % raffles[_requestId].ticketSold; // numberSelected is the winner ticket number
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function createRaffle(
        string memory _name,
        string memory _image,
        uint256 _ticketPrice,
        uint256 _ticketCount,
        uint256 _totalAmountToWin
    ) public {
        raffleCount++;
        raffles[raffleCount] = Raffle({
            owner: msg.sender,
            id: raffleCount,
            name: _name,
            image: _image,
            ticketPrice: _ticketPrice,
            ticketCount: _ticketCount,
            ticketSold: 0,
            totalAmountToWin: _totalAmountToWin,
            isActive: true,
            createadAt: block.timestamp,
            winner: address(0),
            isWhidrawn: false
        });
        emit RaffleCreated(raffleCount, _name, _ticketPrice, _ticketCount);
    }

    function createRaffle(
        string memory _name,
        string memory _image,
        uint256 _ticketPrice,
        uint256 _ticketCount,
        uint256 _totalAmountToWin
    ) public {
        raffleCount++;
        raffles[raffleCount] = Raffle({
            owner: msg.sender,
            id: raffleCount,
            name: _name,
            image: _image,
            ticketPrice: _ticketPrice,
            ticketCount: _ticketCount,
            ticketSold: 0,
            totalAmountToWin: _totalAmountToWin,
            isActive: true,
            createadAt: block.timestamp,
            winner: address(0),
            isWhidrawn: false
        });
        emit RaffleCreated(raffleCount, _name, _ticketPrice, _ticketCount);
    }

    function buyTicket(uint256 _raffleId, uint256 _ticketCount) public payable {
        require(raffles[_raffleId].isActive, "Raffle is not active");
        require(
            msg.value == raffles[_raffleId].ticketPrice * _ticketCount,
            "Invalid amount"
        );
        require(
            raffles[_raffleId].ticketCount >=
                raffles[_raffleId].ticketSold + _ticketCount,
            "Not enough tickets"
        );

        for (uint256 i = 0; i < _ticketCount; i++) {
            raffleTickets[_raffleId].push(
                Ticket({
                    ticketNumber: raffles[_raffleId].ticketSold + i + 1,
                    raffleId: _raffleId,
                    participant: msg.sender,
                    createdAt: block.timestamp,
                    raffleinfo: raffles[_raffleId]
                })
            );
        }

        raffles[_raffleId].ticketSold += _ticketCount;

        emit TicketBought(_raffleId, msg.sender, _ticketCount);

        // Check if the raffle is complete, and if so, draw the winner
        if (raffles[_raffleId].ticketCount == raffles[_raffleId].ticketSold) {
            drawWinner(_raffleId);
        }
    }

    function getRaflle(address _address) public view returns (Raffle[] memory) {
        uint256 count = 0;

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (raffles[i].owner == _address) {
                count++;
            }
        }

        Raffle[] memory ownerRaffles = new Raffle[](count);
        uint256 index = 0;

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (raffles[i].owner == _address) {
                ownerRaffles[index] = raffles[i];
                index++;
            }
        }

        return ownerRaffles;
    }

    function getRaffleTickets(
        uint256 _raffleId
    ) public view returns (Ticket[] memory) {
        return raffleTickets[_raffleId];
    }

    //Function to list raffle tickets by participant address
    function getParticipantTickets(
        address _participant
    ) public view returns (Ticket[] memory) {
        uint256 count = 0;

        // First, count the number of tickets the participant has
        for (uint256 i = 1; i <= raffleCount; i++) {
            for (uint256 j = 0; j < raffleTickets[i].length; j++) {
                if (raffleTickets[i][j].participant == _participant) {
                    count++;
                }
            }
        }

        // Then, create an array with the number of tickets
        Ticket[] memory participantTickets = new Ticket[](count);
        uint256 index = 0;

        // Finally, populate the array with the participant's tickets
        for (uint256 i = 1; i <= raffleCount; i++) {
            for (uint256 j = 0; j < raffleTickets[i].length; j++) {
                if (raffleTickets[i][j].participant == _participant) {
                    participantTickets[index] = raffleTickets[i][j];
                    participantTickets[index].raffleinfo = raffles[i];
                    index++;
                }
            }
        }

        return participantTickets;
    }

    function drawWinner(uint256 _raffleId) private {
        require(raffles[_raffleId].isActive, "Raffle is not active");
        require(
            raffles[_raffleId].ticketCount == raffles[_raffleId].ticketSold,
            "Raffle is not complete"
        );

        //call the chainlink VRF to get the random number
        requestRandomWords();

        /*uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    raffles[_raffleId].ticketSold
                )
            )
        ) % raffles[_raffleId].ticketSold;*/

        address winner = raffleTickets[_raffleId][numberSelected].participant;
        raffles[_raffleId].winner = winner;
        raffles[_raffleId].isActive = false;

        // Calculate the amount to be transferred
        uint256 ticketPrice = raffles[_raffleId].ticketPrice;
        uint256 totalTicketSales = raffles[_raffleId].ticketCount * ticketPrice;
        uint256 feeAmount = (totalTicketSales * fee) / 100;
        uint256 winnerAmount = raffles[_raffleId].totalAmountToWin;

        // Transfer funds
        (bool feeTransferSuccess, ) = payable(owner).call{value: feeAmount}("");
        require(feeTransferSuccess, "Fee transfer to owner failed");

        (bool winnerTransferSuccess, ) = payable(winner).call{
            value: winnerAmount
        }("");
        require(winnerTransferSuccess, "Winner transfer failed");

        emit RaffleWinner(_raffleId, winner, randomNumber);
    }
}
