# Loom — Arc entry pass

A thin, non-custodial entry page for moving small amounts of USDC onto
[Arc](https://arc.io), Circle's stablecoin-native L1, via the official
[CCTP v2](https://www.circle.com/cross-chain-transfer-protocol) burn-and-mint
channel.

## What it is

- A static page (Astro, no backend, no database, no analytics).
- Preset entry amounts ($1 / $5 / $10 / $25) and route guides
  (Solana → Arc, Ethereum → Arc).
- Hands off to Circle's official [USDC Bridge](https://bridge.usdc.com)
  for execution. Loom never holds, routes, or touches funds.

## What it is not

- Not a bridge. No pooling, no wrapping, no custody, no fee.
- Not affiliated with or endorsed by Circle Internet Group.

## Security model

See [loomonarc.xyz/security](https://loomonarc.xyz/security/). Contract
addresses displayed on the site are taken from the official Arc docs;
re-verify them against [docs.arc.io](https://docs.arc.io) before signing.

## Build

```bash
npm install
npm run build     # outputs static site to dist/
```

Deploy: any static host. Currently served via Cloudflare Pages.

## License

MIT
