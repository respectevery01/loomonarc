// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface ITokenMessengerV2 {
    function depositForBurnWithHook(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller,
        uint256 maxFee,
        uint32 minFinalityThreshold,
        bytes calldata hookData
    ) external;
}

/// @title LoomRouter — non-custodial EVM->Arc USDC bridge router with 1% protocol fee.
/// @notice User approves USDC to this router, then calls bridge(). Within the same
///         transaction the fee goes to treasury and the remainder is burned via
///         Circle's official CCTP v2 Forwarding Service. Funds never rest here.
contract LoomRouter {
    address public immutable treasury;
    address public immutable usdc;
    address public immutable tokenMessenger;
    uint32  public immutable destinationDomain;
    uint256 public immutable feeBps;      // 100 = 1%
    uint256 public constant MIN_AMOUNT = 0.5e6; // 0.5 USDC (6dp)

    bytes public constant FORWARD_HOOK = hex"636374702d666f72776172640000000000000000000000000000000000000000";
    uint32 public constant FINALITY_THRESHOLD = 1000; // fast transfer

    event Bridged(address indexed user, uint256 amountIn, uint256 feeTaken, uint256 burned, bytes32 mintRecipient);

    error BadAmount();
    error FeeTooHigh();
    error BadRecipient();

    constructor(address _treasury, address _usdc, address _tokenMessenger, uint32 _destinationDomain, uint256 _feeBps) {
        treasury = _treasury;
        usdc = _usdc;
        tokenMessenger = _tokenMessenger;
        destinationDomain = _destinationDomain;
        feeBps = _feeBps;
    }

    /// @param amount total USDC pulled from caller (includes the 1% fee)
    /// @param mintRecipient bytes32 recipient on Arc (same EVM address, left-padded)
    /// @param maxFee max CCTP forwarding fee in USDC base units, fetched from Circle's fee API
    function bridge(uint256 amount, bytes32 mintRecipient, uint256 maxFee) external {
        if (amount < MIN_AMOUNT) revert BadAmount();
        if (maxFee > amount / 10) revert FeeTooHigh(); // hard cap 10%: Circle's real fee is ~0.2%
        if (mintRecipient == bytes32(0) || bytes12(mintRecipient) != bytes12(0)) revert BadRecipient();

        uint256 fee = (amount * feeBps) / 10_000;
        uint256 burn = amount - fee;

        IERC20(usdc).transferFrom(msg.sender, treasury, fee);
        IERC20(usdc).transferFrom(msg.sender, address(this), burn);
        IERC20(usdc).approve(tokenMessenger, burn);
        ITokenMessengerV2(tokenMessenger).depositForBurnWithHook(
            burn, destinationDomain, mintRecipient, usdc, bytes32(0), maxFee, FINALITY_THRESHOLD, FORWARD_HOOK
        );

        emit Bridged(msg.sender, amount, fee, burn, mintRecipient);
    }
}
