![Verify Truth Ledger](https://github.com/LHMisme420/vata-protocol-v2/actions/workflows/verify-ledger.yml/badge.svg)



## Truth Settlement Layer (TSL)

VATA is a blockchain-native system for economically settling contested factual claims.

- Truth Ledger (Genesis): `truth-ledger/ledger.md`
- Each entry includes a portable proof bundle (claim.json + receipts)

Ethereum settles value. VATA settles truth.


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

## Open Challenge

Any individual may submit a bonded claim.

If you believe a claim in the Truth Ledger is incorrect, you may post a bonded challenge referencing the Claim ID.

Truth is not declared.
Truth is economically settled.
### Roadmap

VATA claims and challenges will execute on Optimism and Arbitrum for scalable dispute activity, with periodic anchoring and final economic settlement on Ethereum L1.


```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```### Roadmap


