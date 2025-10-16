# 📈 Smart Equity Distribution Protocol

A comprehensive smart contract system for transparent and automated equity distribution with vesting schedules, pool management, and stakeholder governance on the Stacks blockchain.

## ✨ Features

💰 **Equity Pools**: Create and manage equity distribution pools with custom vesting  
⏰ **Vesting Schedules**: Automated time-based equity vesting with cliff periods  
👥 **Stakeholder Management**: Add and track equity stakeholders with full transparency  
🔄 **Distribution Tracking**: Complete audit trail of all equity distributions  
🏛️ **Pool Governance**: Creator-controlled pools with member management  
📊 **Real-time Analytics**: Live statistics on pool utilization and vesting progress  

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet/getting-started) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for interaction

### Installation

```bash
git clone <your-repo>
cd smart-equity-distribution-protocol
clarinet check
```

### Running Tests

```bash
npm install
npm test
```

## 📋 Contract Functions

### 🏗️ Pool Management

#### `create-equity-pool`
Create a new equity distribution pool with vesting parameters.

```clarity
(contract-call? .equity-distribution create-equity-pool "Employee Pool" u100000 u52560 u10512)
```

**Parameters:**
- `name`: Pool name (max 50 characters)
- `amount`: Total equity amount to distribute
- `vesting-period`: Vesting duration in blocks (~1 year = 52,560 blocks)
- `cliff-period`: Cliff period before vesting begins

#### `join-pool`
Join an existing equity pool as a member.

```clarity
(contract-call? .equity-distribution join-pool u1)
```

#### `deactivate-pool`
Deactivate a pool (pool creator only).

```clarity
(contract-call? .equity-distribution deactivate-pool u1)
```

### 👥 Stakeholder Operations

#### `add-stakeholder`
Add a new stakeholder with equity allocation (owner only).

```clarity
(contract-call? .equity-distribution add-stakeholder 'ST1STAKEHOLDER... u50000 u0)
```

#### `distribute-to-stakeholder`
Distribute equity from a pool to a stakeholder.

```clarity
(contract-call? .equity-distribution distribute-to-stakeholder u1 'ST1RECIPIENT... u10000)
```

#### `allocate-to-member`
Allocate equity to a specific pool member (pool creator only).

```clarity
(contract-call? .equity-distribution allocate-to-member u1 'ST1MEMBER... u5000)
```

### 💎 Equity Management

#### `claim-vested-equity`
Claim available vested equity.

```clarity
(contract-call? .equity-distribution claim-vested-equity)
```

#### `transfer-equity`
Transfer claimed equity to another stakeholder.

```clarity
(contract-call? .equity-distribution transfer-equity 'ST1RECIPIENT... u1000)
```

### 📊 Query Functions

#### `get-equity-pool`
Get pool information by ID.

```clarity
(contract-call? .equity-distribution get-equity-pool u1)
```

#### `get-stakeholder`
Get stakeholder details.

```clarity
(contract-call? .equity-distribution get-stakeholder 'ST1USER...)
```

#### `get-vested-amount`
Calculate currently vested amount for a stakeholder.

```clarity
(contract-call? .equity-distribution get-vested-amount 'ST1USER...)
```

#### `get-pool-stats`
Get pool utilization statistics.

```clarity
(contract-call? .equity-distribution get-pool-stats u1)
```

#### `get-total-equity`
Get total equity in the system.

```clarity
(contract-call? .equity-distribution get-total-equity)
```

#### `get-available-equity`
Get remaining undistributed equity.

```clarity
(contract-call? .equity-distribution get-available-equity)
```

### ⚙️ Administration

#### `update-total-equity`
Update total equity cap (owner only).

```clarity
(contract-call? .equity-distribution update-total-equity u2000000)
```

## 📊 Data Structures

### Equity Pool
```clarity
{
  name: (string-ascii 50),
  total-amount: uint,
  distributed-amount: uint,
  creator: principal,
  is-active: bool,
  created-at: uint,
  vesting-period: uint,
  cliff-period: uint
}
```

### Stakeholder
```clarity
{
  total-equity: uint,
  vested-equity: uint,
  claimed-equity: uint,
  last-claim: uint,
  vesting-start: uint,
  is-active: bool
}
```

### Distribution Record
```clarity
{
  pool-id: uint,
  recipient: principal,
  amount: uint,
  vesting-schedule: uint,
  cliff-period: uint,
  start-block: uint,
  claimed-amount: uint,
  is-completed: bool
}
```

## 🔢 Error Codes

- `u100`: Owner-only operation
- `u101`: Resource not found
- `u102`: Unauthorized access
- `u103`: Resource already exists
- `u104`: Invalid input parameters
- `u105`: Distribution completed/pool inactive
- `u106`: Insufficient balance
- `u107`: Not a stakeholder
- `u108`: Vesting period locked

## ⏰ Vesting Mechanics

### Time Calculations
- **1 Block** ≈ 10 minutes (Stacks average)
- **1 Day** ≈ 144 blocks
- **1 Month** ≈ 4,380 blocks  
- **1 Year** ≈ 52,560 blocks

### Vesting Formula
```
vested_amount = (total_equity × blocks_passed) ÷ vesting_period
```

### Cliff Period
Equity begins vesting only after the cliff period expires.

## 🛠️ Development

### Testing

```bash
clarinet test
```

### Console Testing

```bash
clarinet console
```

### Local Development

```bash
clarinet integrate
```

## 📈 Usage Examples

### Creating an Employee Equity Pool

```clarity
;; Create a 4-year vesting pool with 1-year cliff
(contract-call? .equity-distribution create-equity-pool 
  "Employee Equity 2024" 
  u500000 
  u210240  ;; 4 years
  u52560)  ;; 1 year cliff
```

### Setting Up Founder Vesting

```clarity
;; Add founder with immediate vesting start
(contract-call? .equity-distribution add-stakeholder 
  'ST1FOUNDER... 
  u250000 
  stacks-block-height)
```

### Quarterly Distribution

```clarity
;; Distribute equity every quarter
(contract-call? .equity-distribution distribute-to-stakeholder
  u1 
  'ST1EMPLOYEE... 
  u12500)  ;; 25% of annual allocation
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/enhanced-vesting`)
3. Commit your changes (`git commit -m 'Add enhanced vesting features'`)
4. Push to the branch (`git push origin feature/enhanced-vesting`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the MIT License.

## 🔮 Future Enhancements

- 🏆 Governance voting mechanisms
- 📱 Mobile app integration
- 🔔 Automated vesting notifications
- 📈 Advanced analytics dashboard
- 🌉 Cross-chain equity bridging
- 🎯 Performance-based vesting triggers
- 📊 Tax reporting integration

## 🆘 Support

For questions, issues, or contributions:
- 📚 Check the documentation
- 🐛 Report bugs via GitHub issues
- 💬 Join community discussions
- 📧 Contact the development team

---

*"Transparent equity distribution builds stronger teams and sustainable growth."* 🚀✨
