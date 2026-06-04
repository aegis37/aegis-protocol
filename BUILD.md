# AEGIS — Build Plan

> Ordered build phases (P0 → P6) with verifiable gates.

## Status

| Phase | Package(s) | State | Gate |
|-------|-----------|-------|------|
| P0 Scaffold | — | ✅ | Monorepo structure, SPEC, BUILD, README |
| P1 Crypto | — | 🔜 | — |
| P2 Circuits | — | 🔜 | — |
| P3 Contracts | — | 🔜 | — |
| P4 Relayer/Route | — | 🔜 | — |
| P5 SDK | — | 🔜 | — |
| P6 Harden | — | 🔜 | — |

---

## P0 — Scaffold

- [x] Create SPEC.md (design spec)
- [x] Create BUILD.md (build plan)
- [x] Landing page + console UI (index.html)
- [x] README with project overview
- [ ] Set up pnpm monorepo workspace
- [ ] Push to GitHub

**Gate:** Project builds, README renders on GitHub.

---

## P1 — Crypto Foundations

- [ ] Poseidon hash implementation
- [ ] Note structure (commitment, nullifier derivation)
- [ ] Incremental Merkle tree
- [ ] Key pair generation (BabyJubJub)
- [ ] Shared secret / encryption
- [ ] Meta-address derivation

**Gate:** 15+ unit tests, golden fixtures frozen.

---

## P2 — ZK Circuits

- [ ] Transaction circuit (join-split: 1×1, 2×1, 1×2, 2×2)
- [ ] Dev trusted setup (Phase 1 + Phase 2)
- [ ] Proving harness
- [ ] Verification harness
- [ ] Solidity verifier generation

**Gate:** 5+ circuit tests, real Groth16 proofs, verifier passes on anvil.

---

## P3 — Smart Contracts

- [ ] `AegisShield.sol` — Core protected pool
  - [ ] `deposit(amount, commitment)`
  - [ ] `shieldedTransfer(nullifier, newCommitment, proof)`
  - [ ] `withdraw(nullifier, proof, recipient, amount)`
  - [ ] Nullifier map tracking
  - [ ] Merkle tree on-chain
- [ ] `AegisPool.sol` — Liquidity management
  - [ ] `depositLiquidity(amount)`
  - [ ] `withdrawLiquidity(amount)`
  - [ ] Utilization tracking
- [ ] Foundry tests (deposit → transfer → unshield E2E)
- [ ] Deployment scripts (Base Sepolia + Base Mainnet)

**Gate:** 20+ Foundry tests, full E2E passing on anvil.

---

## P4 — Relayer / Route

- [ ] Indexer (event listener + state tracking)
- [ ] Transaction builder
- [ ] Proving service integration
- [ ] Relayer API (HTTP)
- [ ] Persistence (SQLite/Postgres)

**Gate:** On-chain event → relayer index → API response works end-to-end.

---

## P5 — SDK

- [ ] `shield(amount, token)` — Deposit assets into shielded pool
- [ ] `send(amount, recipient)` — Private send to another shielded account
- [ ] `unshield(amount, recipient)` — Withdraw to public address
- [ ] `balance()` — Check shielded balance
- [ ] Agent tool adapter (OpenAI function calling format)
- [ ] Unit tests + E2E

**Gate:** Live anvil E2E: Alice shields → sends to Bob → Bob unshields.

---

## P6 — Production Hardening

- [ ] Real trusted setup (multi-party ceremony)
- [ ] Fuzz testing (contracts + circuits)
- [ ] Access control audit
- [ ] Gas optimization
- [ ] Independent security audit
- [ ] Mainnet deployment
- [ ] Public documentation

**Gate:** Audit report filed, mainnet contracts verified.

---

## Development Quick Start

```bash
# Prerequisites
pnpm install
pnpm build && pnpm typecheck && pnpm test

# Smart contracts (Foundry)
cd packages/contracts && forge build && forge test

# Circuits (needs circom 2.x)
cd packages/circuits && ./scripts/build.sh && ./scripts/prove.sh
```

---

*Last updated: June 2026*
