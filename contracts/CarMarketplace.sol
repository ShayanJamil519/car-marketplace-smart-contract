// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CarMarketplace {
    address public contractOwner; // address of contract deployer/owner
    uint256 public carCount; //  number of files uploaded to the marketplace.
    bool private reentrancyLock = false; // lock to track if the buy function is currently executing

    struct Car {
        uint256 carId; // unique identifier of the car.
        string name; // name of the car.
        string description; // description of the car.
        string link; // description of the car.
        uint256 price; // the price of the car in Wei.
        bool isForSale; // check that car for sale or not
        bool isSold; // check that car for sale or not
        address owner; // address of the user who owns the car.
        address[] oldOwner; // address of the user who are the old owners of the car.
    }

    mapping(uint256 => Car) public cars; //  a mapping of file IDs to File structs

    // ===========================================
    // Modifier
    // ===========================================

    /**
     * @dev Throws if called by any account other than the file owner.
     */
    modifier onlyCarOwner(uint256 _carId) {
        require(
            cars[_carId].owner == msg.sender,
            "Only the owner of this car can perform this action."
        );
        _;
    }

    /**
     * @dev Throws if fileId is invalid
     */
    modifier validCarId(uint256 _carId) {
        require(_carId > 0 && _carId <= carCount, "Invalid car ID.");
        _;
    }

    // ===========================================
    // Constructor
    // ===========================================

    constructor() {
        contractOwner = msg.sender;
    }

    // ===========================================
    // Functions
    // ===========================================

    function uploadCar(
        string memory _name,
        string memory _description,
        string memory _link,
        uint256 _price
    ) public returns (bool) {
        require(bytes(_name).length > 0, "Car name cannot be empty.");
        require(
            bytes(_description).length > 0,
            "Car description cannot be empty."
        );
        require(bytes(_link).length > 0, "Car link cannot be empty.");
        require(_price > 0, "Car price must be greater than zero.");
        carCount++;

        cars[carCount] = Car({
            carId: carCount,
            name: _name,
            description: _description,
            link: _link,
            price: _price,
            isForSale: false,
            isSold: false,
            owner: msg.sender,
            oldOwner: new address[](0)
        });

        return true;
    }

    function setCarForSale(uint256 _carId)
        public
        onlyCarOwner(_carId)
        validCarId(_carId)
        returns (bool)
    {
        require(!cars[_carId].isForSale, "Car is already for sale");
        cars[_carId].isForSale = true;
        return true;
    }

    function removeCarFromSale(uint256 _carId)
        public
        onlyCarOwner(_carId)
        validCarId(_carId)
        returns (bool)
    {
        require(cars[_carId].isForSale, "Car is not for sale already");
        cars[_carId].isForSale = false;
        return true;
    }

    function editCarDetails(
        uint256 _carId,
        string memory _name,
        string memory _description,
        uint256 _price
    ) public onlyCarOwner(_carId) validCarId(_carId) returns (bool) {
        require(bytes(_name).length > 0, "Car name cannot be empty.");
        require(
            bytes(_description).length > 0,
            "Car description cannot be empty."
        );
        require(_price > 0, "Price must be greater than 0 ether");

        cars[_carId].name = _name;
        cars[_carId].description = _description;
        cars[_carId].price = _price;

        return true;
    }

    function buyCar(uint256 _carId)
        public
        payable
        validCarId(_carId)
        returns (bool)
    {
        // Prevent reentrancy attacksa
        require(!reentrancyLock, "Reentrant call");
        reentrancyLock = true;

        require(msg.value == cars[_carId].price, "Incorrect payment amount");

        address payable seller = payable(cars[_carId].owner);



    // Push the seller's address to the first index of the oldOwner array
    cars[_carId].oldOwner.push(cars[_carId].owner);
    for (uint256 i = cars[_carId].oldOwner.length - 1; i > 0; i--) {
        cars[_carId].oldOwner[i] = cars[_carId].oldOwner[i - 1];
    }
    cars[_carId].oldOwner[0] = seller;

        cars[_carId].owner = msg.sender;
        cars[_carId].isForSale = false;
        cars[_carId].isSold = true;

        (bool success, ) = seller.call{value: msg.value}("");
        require(success, "Payment transfer failed");

        // Unlock the function
        reentrancyLock = false;

        return true;
    }

    fallback() external payable {}

    receive() external payable {}

    // getters function

    function getCarsForSale() public view returns (Car[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= carCount; i++) {
            if (cars[i].isForSale) {
                count++;
            }
        }

        Car[] memory carsForSale = new Car[](count);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= carCount; i++) {
            if (cars[i].isForSale) {
                carsForSale[currentIndex] = cars[i];
                currentIndex++;
            }
        }

        return carsForSale;
    }

    function getMyCars() public view returns (Car[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= carCount; i++) {
            if (cars[i].owner == msg.sender) {
                count++;
            }
        }

        Car[] memory carsForSale = new Car[](count);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= carCount; i++) {
            if (cars[i].owner == msg.sender) {
                carsForSale[currentIndex] = cars[i];
                currentIndex++;
            }
        }

        return carsForSale;
    }

    function getAllSoldFile() public view returns (Car[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= carCount; i++) {
            if (cars[i].isSold) {
                count++;
            }
        }

        Car[] memory carsForSale = new Car[](count);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= carCount; i++) {
            if (cars[i].isSold) {
                carsForSale[currentIndex] = cars[i];
                currentIndex++;
            }
        }
        return carsForSale;
    }
}
