# AEGIS — Programmable Privacy Infrastructure

> Privacy layer for Base blockchain. Shielded pools · ZK proofs · Agent-compatible by design.
> Encrypted transfers with zero-knowledge proofs — privacy as infrastructure, not an afterthought.

Full-stack monorepo. Landing page + console UI live at [aegiszkp.netlify.app](https://aegiszkp.netlify.app).

- **[SPEC.md](./SPEC.md)** — design specification (architecture, cryptography, contracts)
- **[BUILD.md](./BUILD.md)** — ordered build plan (P0 → P6, with verifiable gates)

**CA:** `0x04C9733980c1703ED339769AFF6e6EBa80535B07` — [View on BaseScan](https://basescan.org/token/0x04C9733980c1703ED339769AFF6e6EBa80535B07)

---

## Status

| Phase | Package(s) | State | Gate |
|---|---|---|---|
| P0 Scaffold | — | ✅ | Monorepo structure, SPEC, BUILD, README |
| P1 Crypto foundations | `common` | 🔜 | — |
| P2 Circuits | `circuits` | 🔜 | — |
| P3 Contracts | `contracts` | 🔜 | — |
| P4 Relayer / Route | `route` | 🔜 | — |
| P5 SDK | `sdk` | 🔜 | — |
| P6 Harden | — | 🔜 | — |

---

## Packages

| Package | Status | Role |
|---|---|---|
| `packages/contracts` | Draft | `AegisShield.sol` — shielded pool (deposit / transfer / withdraw) · `AegisPool.sol` — liquidity management |
| `packages/common` | WIP | Crypto spine — Poseidon hash, notes, nullifiers, Merkle tree, key derivation |
| `packages/circuits` | WIP | Circom/Groth16 join-split circuits (1×2, 2×2) + proving harness |
| `packages/route` | Planned | Indexer + relayer + HTTP API for agent interaction |
| `packages/sdk` | Planned | `@aegis/sdk` — shield / send / unshield / balance + agent-tool adapter |

---

## Develop

```bash
# Clone
git clone https://github.com/aegis37/aegis-protocol.git
cd aegis-protocol

# Install deps
pnpm install
pnpm build && pnpm typecheck && pnpm test

# Smart contracts (Foundry)
cd packages/contracts && forge build && forge test

# Circuits (needs circom 2.x + snarkjs)
cd packages/circuits && ./scripts/build.sh && ./scripts/prove.sh
```

---

## Remaining external ops (P6)

1. **Trusted setup** — real multi-party ceremony (public transcript), regenerate verifiers
2. **Audit** — independent review of contracts + circuits
3. **Deploy** — Base Sepolia testnet → Base Mainnet
4. **Persistence** — wire Postgres/Railway for the route service

---

## Links

- **Website:** [aegiszkp.netlify.app](https://aegiszkp.netlify.app)
- **X (Twitter):** [@Aegiszkp](https://x.com/Aegiszkp)

---

## License

MIT
