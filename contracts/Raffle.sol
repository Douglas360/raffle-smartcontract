// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RaffleV2 {
    address public owner;
    uint256 private raffleCount = 0;
    uint256 private fee = 10; // 10% fee

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

    //Raffle[] public raffles;
    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => Ticket[]) internal raffleTickets;

    event RaffleCreated(
        uint256 id,
        string name,
        uint256 ticketPrice,
        uint256 ticketCount
    );
    event TicketBought(uint256 id, address participant, uint256 ticketCount);
    event RaffleWinner(uint256 id, address winner, uint256 numberSelected);

    constructor() {
        owner = msg.sender;
    }

    function onlyOwner() private view {
        require(msg.sender == owner, "Only owner can call this function");
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

        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    raffles[_raffleId].ticketSold
                )
            )
        ) % raffles[_raffleId].ticketSold;

        address winner = raffleTickets[_raffleId][randomNumber].participant;
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

    // function to withdraw the raffle amount by the owner
    function withdrawRaffleAmount(uint256 _raffleId) public {
        require(
            raffles[_raffleId].owner == msg.sender,
            "Only owner can withdraw the amount"
        );
        require(raffles[_raffleId].isActive == false, "Raffle is still active");
        require(
            raffles[_raffleId].isWhidrawn == false,
            "Amount already withdrawn"
        );

        uint256 ticketPrice = raffles[_raffleId].ticketPrice;
        uint256 totalTicketSales = raffles[_raffleId].ticketCount * ticketPrice;
        uint256 feeAmount = (totalTicketSales * fee) / 100;
        uint256 winnerAmount = raffles[_raffleId].totalAmountToWin;

        uint256 totalAmount = totalTicketSales - feeAmount - winnerAmount;

        (bool withdrawSuccess, ) = payable(msg.sender).call{value: totalAmount}(
            ""
        );
        require(withdrawSuccess, "Withdraw failed");

        raffles[_raffleId].isWhidrawn = true;
    }

    // function to owner of the contract to withdraw the fee amount
    function withdrawFeeAmount() public {
        onlyOwner();
        (bool withdrawSuccess, ) = payable(owner).call{
            value: address(this).balance
        }("");
        require(withdrawSuccess, "Withdraw failed");
    }

    //function to adjust the fee amount
    function setFee(uint256 _fee) public {
        onlyOwner();
        fee = _fee;
    }

    function sendToken(address tokenAddress, uint256 totalCost) public {
        // Approve the transfer of the ERC-20 token
        IERC20 token = IERC20(tokenAddress);
        require(
            token.approve(address(this), totalCost),
            "Failed to approve token transfer"
        );

        // Transfer ERC-20 tokens to the contract
        require(
            token.transferFrom(msg.sender, address(this), totalCost),
            "Failed to transfer tokens"
        );
    }
}
