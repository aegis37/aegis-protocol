# AEGIS Protocol

**Privacy Infrastructure on Base Chain**

## Overview
AEGIS is a programmable privacy layer for Web3, enabling private transactions and identity shielding on Base L3.

## Core Components

### Smart Contracts (`/contracts`)
- `AegisShield.sol` - Core privacy vault
- `AegisPool.sol` - Shielded transaction pool
- `AegisVerifier.sol` - ZK verification layer

### SDK (`/sdk`)
- TypeScript/Python SDK for integration

### Frontend (`/frontend`)
- Dashboard for privacy management

## Architecture
```
User → AEGIS SDK → AegisPool → Base Chain
                ↓
          ZK Verification
                ↓
         Private Transfer
```

## Resources
- Website: https://aegiszkp.netlify.app/
- Docs: docs.aegis.sh (coming soon)
- Twitter: @Aegiszkp
- GitHub: github.com/aegis37/aegis-protocol