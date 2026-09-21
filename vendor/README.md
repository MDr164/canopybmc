# Vendored layers

Layers used by the AST2700 DC-SCM machines that are not part of the `openbmc`
submodule.

## meta-aspeed-sdk

Trimmed copy of the ASPEED OpenBMC SDK.

- Source: https://github.com/AspeedTech-BMC/openbmc
- Commit: `59db970dc4ed772070580a18b4c6774029d32110`
- Subtree: `meta-aspeed-sdk/`
- Excluded: `meta-aspeed-pfr/`, `meta-ast2500-sdk/`, `meta-ast2600-sdk/`, `meta-vendor/`.

## meta-zephyr

Upstream submodule pinned by the repository gitlink. Provides the Zephyr build
machinery; must retain `recipes-kernel/zephyr-kernel/zephyr-kernel-src-3.7.0.inc`.
