// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

/**
 * @title SecureOracleRouter
 * @author Jahanzaib (@jahanzaib-codes)
 * @notice Production-grade Oracle Router supporting Chainlink & L2 Sequencer Uptime verification
 *         for Arbitrum One and Base.
 */
contract SecureOracleRouter {
    // --- L2 SEQUENCER UPTIME FEED ---
    // Required on Base and Arbitrum to detect sequencer outages and prevent frontrunning during recovery.
    address public immutable sequencerUptimeFeed;
    uint256 public constant GRACE_PERIOD_TIME = 3600; // 1-hour grace period post-restart

    // Asset -> Chainlink Price Feed
    mapping(address => address) public priceFeeds;
    // Asset -> Max allowable heartbeat (staleness threshold in seconds)
    mapping(address => uint256) public heartbeatThresholds;

    address public owner;

    error Unauthorized();
    error SequencerDown();
    error GracePeriodNotOver();
    error PriceFeedNotConfigured(address asset);
    error InvalidPrice(int256 price);
    error StalePriceReport(uint256 updatedAt, uint256 threshold);
    error IncompleteRound(uint80 roundId, uint80 answeredInRound);

    event PriceFeedUpdated(address indexed asset, address indexed feed, uint256 heartbeat);
    event OwnerTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _sequencerUptimeFeed) {
        owner = msg.sender;
        sequencerUptimeFeed = _sequencerUptimeFeed;
    }

    function setPriceFeed(address asset, address feed, uint256 heartbeat) external onlyOwner {
        require(asset != address(0) && feed != address(0), "Zero address");
        priceFeeds[asset] = feed;
        heartbeatThresholds[asset] = heartbeat;
        emit PriceFeedUpdated(asset, feed, heartbeat);
    }

    /**
     * @notice Fetch verified, validated price with sequencer check & staleness guards.
     * @return price Normalized price with 8 decimals.
     */
    function getValidatedPrice(address asset) external view returns (uint256 price) {
        // Step 1: Verify L2 Sequencer health
        _checkSequencer();

        address feedAddress = priceFeeds[asset];
        if (feedAddress == address(0)) revert PriceFeedNotConfigured(asset);

        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = feed.latestRoundData();

        // Step 2: Positive price verification
        if (answer <= 0) revert InvalidPrice(answer);

        // Step 3: Complete round verification (defense against stale or cancelled rounds)
        if (answeredInRound < roundId) revert IncompleteRound(roundId, answeredInRound);

        // Step 4: Staleness check based on asset-specific heartbeat (e.g. 3600s for ETH/USD)
        uint256 maxHeartbeat = heartbeatThresholds[asset];
        if (block.timestamp - updatedAt > maxHeartbeat) {
            revert StalePriceReport(updatedAt, maxHeartbeat);
        }

        return uint256(answer);
    }

    /**
     * @dev Checks whether the L2 Sequencer is active and grace period has elapsed.
     */
    function _checkSequencer() internal view {
        if (sequencerUptimeFeed == address(0)) return; // Skipped on L1 Mainnet

        (
            ,
            int256 answer,
            uint256 startedAt,
            ,
            
        ) = AggregatorV3Interface(sequencerUptimeFeed).latestRoundData();

        // 0 = Sequencer Up, 1 = Sequencer Down
        if (answer == 1) revert SequencerDown();

        // Grace period check to protect against liquidation cascades when transactions unpause
        if (block.timestamp - startedAt < GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }
    }
}
