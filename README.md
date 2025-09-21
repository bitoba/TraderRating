# TraderRating

A decentralized address reputation system smart contract for trading behavior and performance scoring on the Stacks blockchain. TraderRating provides a comprehensive framework for tracking trader performance, ratings, and reputation metrics to enable trustworthy peer-to-peer trading.

## Overview

TraderRating enables traders to build and maintain their reputation through verifiable on-chain trading history and peer ratings. The system combines multiple metrics including trade success rates, volume history, peer ratings, and activity patterns to calculate comprehensive reputation scores.

## Features

- **Trader Registration**: Decentralized trader profile creation and management
- **Trade Recording**: Immutable on-chain trade history tracking
- **Peer Rating System**: Community-driven rating mechanism with anti-spam protection
- **Reputation Scoring**: Multi-factor reputation calculation algorithm
- **Success Rate Tracking**: Automatic calculation of trade success percentages
- **Volume Analytics**: Trading volume tracking for reputation weighting
- **Rating Statistics**: Detailed breakdown of rating distributions
- **Activity Monitoring**: Track trader activity and engagement levels
- **Profile Management**: Traders can deactivate profiles when needed

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Contract Version**: 1.0.0
- **Clarity Version**: 2
- **Epoch**: 2.5

### Rating System
- **Rating Range**: 1-100 points
- **Star Categories**:
  - 5 stars: 81-100 points
  - 4 stars: 61-80 points
  - 3 stars: 41-60 points
  - 2 stars: 21-40 points
  - 1 star: 1-20 points
- **Minimum Trades Required**: 5 trades to rate others

### Reputation Score Components
- **Success Rate**: 0-40 points (based on successful vs failed trades)
- **Average Rating**: 0-40 points (weighted by peer ratings)
- **Trading Volume**: 0-10 points (capped bonus for high volume)
- **Experience**: 0-10 points (based on total trade count, capped at 100 trades)

## Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js (for testing)
- Stacks CLI (for deployment)

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd TraderRating

# Navigate to contract directory
cd TraderRating_contract

# Install dependencies
npm install

# Run tests
npm test

# Run tests with coverage
npm run test:report
```

## Usage Examples

### Trader Registration
```clarity
;; Register as a new trader
(contract-call? .TraderRating register-trader)
```

### Recording a Trade
```clarity
;; Record a successful trade
(contract-call? .TraderRating record-trade
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE  ;; counterparty
  "trade-001"                                      ;; trade-id
  u10000                                          ;; volume
  true                                            ;; success
  "spot-trade"                                    ;; trade-type
)
```

### Rating a Trader
```clarity
;; Rate another trader
(contract-call? .TraderRating rate-trader
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE  ;; trader to rate
  u85                                             ;; rating (1-100)
  "Excellent trader, fast and reliable"          ;; comment
  (some "trade-001")                             ;; trade reference
)
```

### Querying Trader Information
```clarity
;; Get trader profile
(contract-call? .TraderRating get-trader-profile 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)

;; Get success rate
(contract-call? .TraderRating get-success-rate 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)

;; Check if trader can rate others
(contract-call? .TraderRating can-rate 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

## Contract Functions

### Public Functions

#### `register-trader()`
Registers a new trader profile or confirms existing registration.
- **Returns**: Success message
- **Creates**: Empty trader profile with initial statistics

#### `record-trade(counterparty, trade-id, volume, success, trade-type)`
Records a trade for reputation tracking.
- **Parameters**:
  - `counterparty`: Principal of the other trader
  - `trade-id`: Unique identifier for the trade
  - `volume`: Trade volume in base units
  - `success`: Boolean indicating trade success
  - `trade-type`: String describing trade type
- **Returns**: Success confirmation
- **Updates**: Trader profile statistics and reputation score

#### `rate-trader(rated-trader, rating, comment, trade-reference)`
Submit a rating for another trader.
- **Parameters**:
  - `rated-trader`: Principal being rated
  - `rating`: Rating value (1-100)
  - `comment`: Optional comment (max 256 chars)
  - `trade-reference`: Optional trade ID reference
- **Requirements**: Minimum 5 trades completed, cannot rate self, one rating per trader pair
- **Returns**: Success confirmation

#### `deactivate-profile()`
Deactivates the caller's trader profile.
- **Returns**: Confirmation message
- **Effect**: Sets profile as inactive

### Read-Only Functions

#### `get-trader-profile(trader)`
Returns complete trader profile data including trades, ratings, and reputation.

#### `get-rating-stats(trader)`
Returns detailed rating distribution (1-5 star counts).

#### `get-trader-rating(rater, rated)`
Returns specific rating between two traders.

#### `get-trade-record(trader, trade-id)`
Returns details of a specific trade.

#### `get-success-rate(trader)`
Calculates and returns trader's success rate percentage.

#### `get-contract-stats()`
Returns overall contract statistics (total traders and ratings).

#### `can-rate(trader)`
Checks if trader meets requirements to rate others.

## Deployment Guide

### Local Development (Clarinet)
```bash
# Start local development environment
clarinet integrate

# Deploy to local testnet
clarinet deploy --devnet
```

### Testnet Deployment
```bash
# Configure testnet settings in settings/Testnet.toml
# Deploy to testnet
stx deploy_contract TraderRating contracts/TraderRating.clar --testnet
```

### Mainnet Deployment
```bash
# Configure mainnet settings in settings/Mainnet.toml
# Deploy to mainnet (ensure thorough testing first)
stx deploy_contract TraderRating contracts/TraderRating.clar --mainnet
```

## Security Considerations

### Access Controls
- No admin functions - fully decentralized operation
- Self-rating prevention built-in
- One rating per trader pair enforcement
- Minimum trade requirement for rating eligibility

### Data Integrity
- Immutable trade records once created
- Rating submissions are permanent
- Profile data updates only through authorized functions
- Block height timestamps for all activities

### Anti-Spam Measures
- Minimum 5 trades required before rating others
- Prevention of duplicate ratings between same trader pairs
- Rating bounds enforcement (1-100 range)
- Comment length limits

### Known Limitations
- No rating modification or deletion after submission
- No dispute resolution mechanism built-in
- Volume and trade data relies on honest reporting
- No integration with external trade verification systems

## Error Codes

- `u100`: Unauthorized access
- `u101`: Trader profile not found
- `u102`: Invalid rating value
- `u103`: Rating already exists between traders
- `u104`: Cannot rate yourself
- `u105`: Insufficient trades to rate others

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Run the test suite: `npm test`
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For questions, issues, or contributions, please open an issue in the repository or contact the development team.