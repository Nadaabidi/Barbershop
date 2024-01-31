// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract BarberShop {
    address[] public owners; // List of authorized owners

    enum AppointmentState { Pending, Booked, Paid }

    struct Client {
        string name;
        uint256 phoneNumber;
        mapping(uint256 => Appointment) appointments;
    }

    struct Staff {
        string name;
        address staffId;
        mapping(uint256 => uint256) services; // serviceId => price
    }

    struct Service {
        string name;
        address staffId;
    }

    struct Appointment {
        uint256 serviceId;
        uint256 timestamp;
        AppointmentState state;
    }

    mapping(address => Client) public clients;
    mapping(address => Staff) public staff;
    mapping(uint256 => Service) public services;

    event ClientAdded(address indexed clientAddress, string name, uint256 phoneNumber);
    event StaffAdded(address indexed staffAddress, string name, address employeeId);
    event ClientUpdated(address indexed clientAddress, string newName, uint256 newPhoneNumber);
    event StaffUpdated(address indexed staffAddress, string newName, address newEmployeeId);
    event ClientRemoved(address indexed clientAddress);
    event StaffRemoved(address indexed staffAddress);
    event ServiceAdded(uint256 indexed serviceId, string name, address staffId);
    event AppointmentBooked(address indexed clientAddress, uint256 serviceId, uint256 timestamp);
    event AppointmentPaid(address indexed clientAddress, uint256 serviceId, uint256 amount);

    modifier onlyOwner() {
        require(isOwner(msg.sender), "You are not an owner");
        _;
    }

      constructor() {
        owners.push(msg.sender); // The deployer is the initial owner
    }

       function isOwner(address _address) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                return true;
            }
        }
        return false;
    }

       function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid owner address");
        owners.push(_newOwner);
    }

 function addClient(address _clientAddress, string memory _name, uint256 _phoneNumber) external onlyOwner {
    Client storage newClient = clients[_clientAddress];
    newClient.name = _name;
    newClient.phoneNumber = _phoneNumber;
    emit ClientAdded(_clientAddress, _name, _phoneNumber);
}


    function updateClient(address _clientAddress, string memory _newName, uint256 _newPhoneNumber) external onlyOwner {
        clients[_clientAddress].name = _newName;
        clients[_clientAddress].phoneNumber = _newPhoneNumber;
        emit ClientUpdated(_clientAddress, _newName, _newPhoneNumber);
    }

    function removeClient(address _clientAddress) external onlyOwner {
        delete clients[_clientAddress];
        emit ClientRemoved(_clientAddress);
    }

  function addStaff(address _staffAddress, string memory _name, address _staffId) external onlyOwner {
    Staff storage newStaff = staff[_staffAddress];
    newStaff.name = _name;
    newStaff.staffId = _staffId;
    emit StaffAdded(_staffAddress, _name, _staffId);
}


    function updateStaff(address _staffAddress, string memory _newName, address _newStaffId) external onlyOwner {
        staff[_staffAddress].name = _newName;
        staff[_staffAddress].staffId = _newStaffId;
        emit StaffUpdated(_staffAddress, _newName, _newStaffId);
    }

    function removeStaff(address _staffAddress) external onlyOwner {
        delete staff[_staffAddress];
        emit StaffRemoved(_staffAddress);
    }

    function addService(uint256 _serviceId, string memory _name, address _staffId) external onlyOwner {
        services[_serviceId] = Service(_name, _staffId);
        emit ServiceAdded(_serviceId, _name, _staffId);
    }

    function viewService(uint256 _serviceId) external view returns (string memory serviceName, address staffId) {
        return (services[_serviceId].name, services[_serviceId].staffId);
    }

    function viewStaff(address _staffId) external view returns (string memory staffName, address staffId) {
        return (staff[_staffId].name, staff[_staffId].staffId);
    }

     function bookAppointment(uint256 _serviceId) external {
         require(clients[msg.sender].phoneNumber != 0, "Client not registered");
           require(services[_serviceId].staffId != address(0), "Service not found");

         clients[msg.sender].appointments[_serviceId] = Appointment(_serviceId, block.timestamp, AppointmentState.Booked);
         emit AppointmentBooked(msg.sender, _serviceId, block.timestamp);
     }

     function payForAppointment(uint256 _serviceId) external payable {
         require(clients[msg.sender].phoneNumber != 0, "Client not registered");
         Appointment storage appointment = clients[msg.sender].appointments[_serviceId];
         require(appointment.timestamp != 0, "No appointment found");
         require(appointment.state == AppointmentState.Booked, "Appointment already paid");

         uint256 amount = msg.value;
         uint256 price = staff[services[_serviceId].staffId].services[_serviceId];

         require(amount >= price, "Insufficient funds");

         // Mark the appointment as paid
         appointment.state = AppointmentState.Paid;

         // Transfer the payment to the staff
         payable(staff[services[_serviceId].staffId].staffId).transfer(price);

         emit AppointmentPaid(msg.sender, _serviceId, price);
     }
}
