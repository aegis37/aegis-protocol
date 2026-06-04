# AEGIS — Specification

> Programmable privacy infrastructure for Base. Shielded pools · ZK proofs · Agent-compatible by design.

**Status:** `v0.1 / draft`
**Chain:** Base (L2, OP-Stack)
**Audience:** Developers and autonomous agents that need on-chain privacy.

---

## 1. Problem & Vision

Blockchain transactions are public by default. Any wallet, contract interaction, or asset transfer that a person or an agent makes on Base is visible to everyone — front-runners, MEV bots, competitors, and on-chain analysts. A fresh EOA per transaction breaks the moment funds move between addresses, linking all activity together.

**AEGIS solves this** by providing a universal privacy layer: shield your assets (ETH/ERC-20), transact privately via zero-knowledge proofs, and unshield when you need to interact with public DeFi — all through a simple, agent-friendly interface.

**Vision:** Every transaction on Base flows through AEGIS by default, making privacy the standard, not the exception.

---

## 2. Core Concepts

### 2.1 Shielded Assets

Users deposit public assets (ETH, USDC, etc.) into the AEGIS shielded pool. In return, the pool issues a _note_ — a secret commitment that represents ownership of the shielded balance. Only the note holder can prove ownership (via ZK proof) and spend it.

- **Shield:** `deposit(asset, amount, commitment)` → creates a note
- **Send (private):** `shieldedTransfer(nullifier, newCommitment, proof)` → transfers ownership
- **Unshield:** `withdraw(nullifier, proof, recipient)` → withdraws to public address

### 2.2 Zero-Knowledge Proofs

All shielded transactions use Groth16 ZK-SNARKs over BLS12-381 (circom) to prove:

- The sender owns the note being spent
- The new commitment is correctly formed
- The total value flow is balanced (no inflation)
- No double-spend (via nullifier)

The proving system allows verification in ~10ms on-chain.

### 2.3 Merkle Tree

All note commitments live in an incremental Merkle tree. When sending a shielded transfer, the prover references the Merkle root at the time the note was created, proving the note exists in the tree without revealing which one.

### 2.4 Nullifiers

Each spent note produces a unique nullifier. The smart contract tracks all nullifiers to prevent double-spending. Nullifiers are computationally binding to their note — given only a nullifier, no one can link it back to the original commitment.

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Agent / User                       │
├────────────────────────┬────────────────────────────┤
│   AEGIS SDK            │   Web Console (index.html) │
│   (shield/send/        │   Connect Wallet           │
│    unshield/balance)    │   Shield Assets            │
└───────────┬────────────┴────────┬───────────────────┘
            │                     │
            ▼                     ▼
┌─────────────────────────────────────────────────────┐
│               Private Relayer / Route                │
│  - Tx construction & simulation                      │
│  - Proof generation (proving service)                │
│  - IPFS note storage (optional)                      │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│              On-Chain (Base L2)                      │
│  ┌──────────────┐  ┌──────────────┐                  │
│  │ AegisShield  │  │ AegisPool    │                  │
│  │ (core logic) │  │ (liquidity)  │                  │
│  └──────────────┘  └──────────────┘                  │
└─────────────────────────────────────────────────────┘
```

### 3.1 Smart Contracts

#### AegisShield.sol

The core shielded pool contract. Handles:

- `deposit(uint256 amount, bytes32 commitment)` — Public deposit into the shielded pool. The user sends tokens and creates a note commitment.
- `shieldedTransfer(bytes32 nullifier, bytes32 newCommitment, bytes calldata proof)` — Private transfer between shielded accounts. Proves ownership of the old note and creates a new one.
- `withdraw(bytes32 nullifier, bytes calldata proof, address recipient, uint256 amount)` — Withdraw from shielded pool to a public address.
- `hasNullifier(bytes32 nullifier)` → `bool` — Check if a nullifier has been spent.

All functions verify Groth16 proofs before executing state transitions.

#### AegisPool.sol

Manages the liquidity pool backing shielded assets. Handles:

- `depositLiquidity(uint256 amount)` — Add liquidity to the pool
- `withdrawLiquidity(uint256 amount)` — Remove liquidity (subject to utilization)
- `getPoolBalance()` → `uint256` — Current pool balance
- `getUtilization()` → `uint256` — Pool utilization rate

### 3.2 ZK Circuits

The `transaction` circuit handles the core join-split semantics:

- **1-to-1:** Shielded transfer from one note to one new note (most common)
- **2-to-1:** Merge two notes into one (consolidation)
- **1-to-2:** Split one note into two (payment with change)
- **2-to-2:** Full join-split (rare, general case)

Circuit constraints: ~150k gates per transaction.

### 3.3 Merkle Tree

- Incremental Merkle tree (Poseidon hash)
- Depth: 32 (supports ~4B notes)
- On-chain: 32× byte32 storage slots (+ solidity poseidon)
- Gas: ~40k per deposit (tree update), ~60k per withdrawal (proof verification + nullifier check)

### 3.4 Proving Service

The proving service handles proof generation off-chain:

1. Receives transaction parameters (inputs, outputs, amounts, Merkle path)
2. Generates witness
3. Proves using Groth16 (phase-2 ceremony)
4. Returns proof bytes for on-chain submission

Target: ~5s proof time for 1-to-1 transactions (consumer GPU).

---

## 4. Security Model

### 4.1 Assumptions

- **Proof soundness:** Groth16 is computationally sound under the KEA assumption (requires trusted setup).
- **Trusted setup ceremony:** Requires multi-party computation (MPC) ceremony for Phase 2 circuit-specific parameters. The more participants, the higher the confidence (1 honest participant → secure).
- **Nullifier integrity:** No one can forge a nullifier that corresponds to a commitment they don't own (collision-resistant hash).
- **Relayer trust model:** The relayer sees transaction metadata (proof + public inputs) but cannot link to the original note owner (sender remains anonymous even to the relayer).

### 4.2 Threat Model

| Threat | Mitigation |
|--------|-----------|
| Double-spending | Nullifier map prevents reusing notes |
| Balance inflation | ZK circuit validates value flow |
| Front-running shield → unshield | Commit-reveal scheme on unshield |
| Linkability attack | Shield pool anonymity set grows with use |
| Forged deposit | Merkle path binding in proof |
| Replay attacks | Unique nullifier per note |

### 4.3 Privacy Guarantees

- **Unlinkability:** A shielded transaction cannot be linked to its sender (assuming adequate anonymity set).
- **Confidential amounts:** Transaction amounts are hidden inside the ZK proof (private outputs).
- **Sender anonymity:** The sender's address is never revealed — only the proof + nullifier are broadcast.
- **Receiver privacy:** The recipient is identified only by a note commitment, not an address.

---

## 5. Compliance

AEGIS is designed to be compliant by construction:

- **No mixing/obfuscation:** Notes are issued 1:1 against deposits — every shielded asset is fully backed.
- **Voluntary disclosure:** Users can optionally reveal proof data to auditors or counterparties without compromising the system.
- **No algorithmic privacy degradation:** AEGIS uses cryptographic guarantees, not heuristic anonymity.
- **AML/KYC gate:** Compliance layer can be added at the unshield step (the relayer can enforce KYC before releasing funds).

---

## 6. Dependencies

| Dependency | Version | Purpose |
|-----------|---------|---------|
| circom | 2.x | Circuit compiler |
| snarkjs | latest | Proving/verification |
| Solidity | 0.8.x | Smart contracts |
| Foundry | latest | Contract testing/deployment |
| Node.js | 18+ | SDK, build tooling |
| pnpm | 9+ | Workspace management |

---

## 7. Glossary

| Term | Definition |
|------|-----------|
| Commitment | Hash of a note. Stored in the Merkle tree to represent ownership of shielded assets. |
| Nullifier | Unique value derived from a spent commitment. Prevents double-spending. |
| Note | A secret data structure representing ownership of a specific amount of shielded assets. |
| Merkle Tree | Incremental hash tree storing all commitments. |
| Shield | Deposit public assets into the shielded pool. |
| Unshield | Withdraw shielded assets to a public address. |
| Join-Split | A ZK circuit operation: consume N notes, produce M notes, ensuring value is conserved. |
| Groth16 | A zero-knowledge proving system with constant-size proofs (~128 bytes) and fast verification. |
| Relayer | Off-chain service that constructs transactions and optionally generates proofs. |

---

## 8. Future Roadmap

| Phase | What |
|-------|------|
| **P0** | Project scaffold, README, SPEC, BUILD |
| **P1** | Crypto foundations (Poseidon, Merkle tree, notes, nullifiers) |
| **P2** | ZK circuits (join-split, proving/verifying) |
| **P3** | Smart contracts (shield, unshield, pool) |
| **P4** | Proving service & relayer |
| **P5** | SDK (agent-friendly API) |
| **P6** | Production hardening, audit, mainnet deploy |

---

*Specification v0.1 — subject to change as the protocol evolves.*
