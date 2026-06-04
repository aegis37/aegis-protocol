# Deployment

## Frontend

Hosted on Netlify: https://aegis-dkp.netlify.app

### Deploy Updates

```bash
git push origin main  # Auto-deploys
```

## Smart Contracts

Deploy to Base Sepolia (testnet) first:

```bash
npm install
npx hardhat run scripts/deploy.js --network baseSepolia
```

See `/contracts` for contract details.
