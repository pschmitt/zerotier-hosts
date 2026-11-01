# Agent guidance

This repository contains a ZeroTier-related host inventory and helper script.

## Development

- Treat node names, addresses, network identifiers, and relationships as sensitive. Do not copy them into this guide, examples, or tool summaries.
- Review only the specific inventory entries required for a task; use synthetic data for examples.
- Check changed shell scripts with their declared interpreter and `shellcheck` where applicable. Do not change a live network as part of validation.
- Load the `shell` skill before changing shell code.

## CI

- Before changing GitHub Actions, inspect the current guidance in `pschmitt/ci-workflows`. Use `@main` in every `uses:` reference to a shared workflow or action.
