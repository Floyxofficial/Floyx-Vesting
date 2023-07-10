//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IFloyx.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom error for indicating that all tokens have been released for a beneficiary
error AllTokensAreReleleased(address _beneficiary);

/**
 * @title FloyxTokenVesting
 * @dev A token vesting contract that allows the controlled release of tokens over a specified period of time.
 */
contract FloyxTokenVesting is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IFloyx private immutable token;
    uint256 private totalReleasedAmount;
    uint256 private totalVestedAmount;
    uint256 private seedStartTime;
    uint256 private privateStartTime;
    uint256 private testStartTime;

    struct VestingSchedule {
        bool initialized;
        // cliff period in seconds
        uint256 cliff;
        // start time of the vesting period
        uint256 startTime;
        // duration of the vesting period in seconds
        uint256 duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodInDays;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
        // released % for each slice period and it should be in multiple of 10
        uint256 releasedPercent;
        // tgeAmount which will be released at start
        uint256 tgePercent;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    /**
     * @dev Constructor function
     * @param _token The address of the token contract
     */
    constructor(address _token) {
        token = IFloyx(_token);
    }

    // Events
    event addVesting(
        address indexed beneficiary,
        uint256 cliff,
        uint256 startTime,
        uint256 duration,
        uint256 slicePeriod,
        uint256 amountTotal,
        uint256 releasedPercent,
        uint256 tgePercent
    );
    event withdraw(address indexed beneficiary, uint256 amount);

    modifier onlyIfVestingScheduleInitialized(address _beneficiary) {
        require(
            vestingSchedules[_beneficiary].initialized,
            "Vesting schedule not initialized"
        );
        _;
    }

    /**
     * @dev Adds a seed vesting schedule for a beneficiary
     * @param _beneficiary The address of the beneficiary
     * @param _amount The total amount of tokens to be vested
     */
    function SeedVestingSchedule(
        address _beneficiary,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_beneficiary != address(0), "Beneficiary is zero address.");
        require(
            _amount <= getUnallocatedFundsAmount(),
            "Insufficient funds available"
        );
        require(
            !vestingSchedules[_beneficiary].initialized,
            "Vesting schedule for this beneficiary already exists"
        );

        uint256 _start = seedStartTime;
        uint256 _cliff = _start.add(60 days);
        uint256 _duration = _start.add(660);
        uint256 _slicePeriod = 30 days;
        uint256 _releasedPercent = 500;

        VestingSchedule memory vestingSchedule = VestingSchedule({
            initialized: true,
            startTime: _start,
            cliff: _cliff,
            duration: _duration,
            slicePeriodInDays: _slicePeriod,
            amountTotal: _amount,
            released: 0,
            releasedPercent: _releasedPercent,
            tgePercent: 0
        });

        vestingSchedules[_beneficiary] = vestingSchedule;
        totalVestedAmount = totalVestedAmount.add(_amount);
        emit addVesting(
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriod,
            _amount,
            _releasedPercent,
            0
        );
    }

    /**
     * @dev Adds a private sale vesting schedule for a beneficiary
     * @param _beneficiary The address of the beneficiary
     * @param _amount The total amount of tokens to be vested
     */
    function PrivateSaleVestingSchedule(
        address _beneficiary,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_beneficiary != address(0), "Beneficiary is zero address.");
        require(
            _amount <= getUnallocatedFundsAmount(),
            "Insufficient funds available"
        );
        require(
            !vestingSchedules[_beneficiary].initialized,
            "Vesting schedule for this beneficiary already exists"
        );

        uint256 _start = privateStartTime;
        uint256 _cliff = _start.add(60 days);
        uint256 _duration = _start.add(600 days);
        uint256 _slicePeriod = 30 days;
        uint256 _releasedPercent = 528;
        uint256 _tgePercent = 500;

        VestingSchedule memory vestingSchedule = VestingSchedule({
            initialized: true,
            startTime: _start,
            cliff: _cliff,
            duration: _duration,
            slicePeriodInDays: _slicePeriod,
            amountTotal: _amount,
            released: 0,
            releasedPercent: _releasedPercent,
            tgePercent: _tgePercent
        });

        vestingSchedules[_beneficiary] = vestingSchedule;
        totalVestedAmount = totalVestedAmount.add(_amount);
        emit addVesting(
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriod,
            _amount,
            _tgePercent,
            0
        );
    }

    /**
     * @dev Retrieves the amount of tokens claimable by a beneficiary based on their vesting schedule
     * @param _beneficiary The address of the beneficiary
     * @return The amount of tokens claimable by the beneficiary
     */

    function getClaimableAmount(
        address _beneficiary
    )
        external
        view
        onlyIfVestingScheduleInitialized(_beneficiary)
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            _beneficiary
        ];
        uint256 currentTime = getCurrentTime();
        require(
            currentTime >= vestingSchedule.startTime,
            "vesting not started yet"
        );
        uint256 releaseAmount = _getClaimableAmount(_beneficiary);
        if (
            releaseAmount.add(vestingSchedule.released) >
            vestingSchedule.amountTotal
        ) {
            releaseAmount = vestingSchedule.amountTotal.sub(
                vestingSchedule.released
            );
        }
        return releaseAmount;
    }

    /**
     * @dev Retrieves the total amount of tokens to be vested
     * @return The total amount of tokens to be vested
     */
    function getTotalVestingAmount() public view returns (uint256) {
        return totalVestedAmount;
    }

    /**
     * @dev Retrieves the total amount of tokens released from the vesting contract
     * @return The total amount of tokens released
     */

    function getTotalReleasedAmount() external view returns (uint256) {
        return totalReleasedAmount;
    }

    /**
     * @dev Retrieves the amount of unallocated funds (tokens) remaining in the vesting contract
     * @return The amount of unallocated funds
     */

    function getUnallocatedFundsAmount() public view returns (uint256) {
        return token.balanceOf(address(this)).sub(totalVestedAmount);
    }

    /**
     * @dev Retrieves the available funds (tokens) in the vesting contract
     * @return The available funds
     */

    function getAvailableFunds() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Retrieves the address of the token contract
     * @return The address of the token contract
     */

    function getToken() external view returns (address) {
        return address(token);
    }

    /**
     * @dev Claims the vested tokens for a beneficiary
     * @param _beneficiary The address of the beneficiary
     */

    function claimVestedToken(
        address _beneficiary
    ) public nonReentrant onlyIfVestingScheduleInitialized(_beneficiary) {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            _beneficiary
        ];
        uint256 currentTime = getCurrentTime();
        require(
            currentTime > vestingSchedule.startTime,
            "vesting not started yet"
        );
        if (vestingSchedule.amountTotal == vestingSchedule.released) {
            revert AllTokensAreReleleased(_beneficiary);
        }
        uint256 releaseAmount = _getClaimableAmount(_beneficiary);
        require(releaseAmount > 0, "there no token to release");
        if (
            releaseAmount.add(vestingSchedule.released) >
            vestingSchedule.amountTotal
        ) {
            releaseAmount = vestingSchedule.amountTotal.sub(
                vestingSchedule.released
            );
        }
        vestingSchedule.released = vestingSchedule.released.add(releaseAmount);
        totalVestedAmount = totalVestedAmount.sub(releaseAmount);
        totalReleasedAmount = totalReleasedAmount.add(releaseAmount);
        require(
            token.approve(address(this), releaseAmount),
            "token transfer not apporoved"
        );
        require(
            token.transfer(_beneficiary, releaseAmount),
            "Token withdrawal failed."
        );
        emit withdraw(_beneficiary, releaseAmount);
    }

    /**
     * @dev Withdraws unallocated funds (tokens) from the vesting contract to a specified receiver
     * @param _receiver The address of the receiver
     * @param _amount The amount of unallocated funds to withdraw
     */

    function withdrawUnallocatedFunds(
        address _receiver,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_receiver != address(0), "Receiver is the zero address.");
        require(
            _amount > 0 && _amount <= getUnallocatedFundsAmount(),
            "Invalid amount of unallocated funds."
        );

        require(
            token.transfer(_receiver, _amount),
            "Unallocated funds withdrawal failed."
        );
        emit withdraw(_receiver, _amount);
    }

    /**
     * @dev Initializes the start time for the seed vesting schedule
     * @param _startTime The start time for the seed vesting schedule
     */

    function initializeSeedVesting(uint256 _startTime) external onlyOwner {
        seedStartTime = _startTime;
    }

    /**
     * @dev Initializes the start time for the private sale vesting schedule
     * @param _startTime The start time for the private sale vesting schedule
     */

    function initializePrivateSaleVesting(
        uint256 _startTime
    ) external onlyOwner {
        privateStartTime = _startTime;
    }

    function _getClaimableAmount(
        address _beneficiary
    )
        internal
        view
        onlyIfVestingScheduleInitialized(_beneficiary)
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            _beneficiary
        ];
        if (vestingSchedule.released >= vestingSchedule.amountTotal) {
            revert AllTokensAreReleleased(_beneficiary);
        }
        uint256 tgeAmount = _getTgeAmount(vestingSchedule);
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        uint256 releaseableAmount = tgeAmount.add(vestedAmount);
        return releaseableAmount.sub(vestingSchedule.released);
    }

    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if (currentTime < vestingSchedule.cliff) {
            return 0;
        } else if (
            currentTime >=
            vestingSchedule.duration.add(vestingSchedule.startTime)
        ) {
            return vestingSchedule.amountTotal.sub(vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingSchedule.cliff);
            uint256 secondsPerSlice = vestingSchedule.slicePeriodInDays;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedAmountPerSlice = _calculateReleasableAmount(
                vestingSchedule
            );
            uint256 vestedAmount = vestedAmountPerSlice.mul(vestedSlicePeriods);
            return vestedAmount;
        }
    }

    function _calculateReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal pure returns (uint256) {
        uint256 totalAmount = vestingSchedule.amountTotal;
        uint256 releasedPercent = uint256(vestingSchedule.releasedPercent);
        return totalAmount.mul(releasedPercent).div(10000);
    }

    function _getTgeAmount(
        VestingSchedule memory vestingSchedule
    ) internal pure returns (uint256) {
        uint256 totalAmount = vestingSchedule.amountTotal;
        uint256 _tgePercent = uint256(vestingSchedule.tgePercent);
        return ((totalAmount.mul(_tgePercent)).div(10000));
    }

    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }
}
