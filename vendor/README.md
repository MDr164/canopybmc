# Vendored layers

Third-party Yocto layers required by Canopy targets that are **not** carried in
the `openbmc` submodule. Kept here to keep Canopy self-contained.

| Path | How it's tracked | Used by |
|------|------------------|---------|
| `meta-aspeed-sdk/` | **vendored copy** (see below) | `dcscm-demo` (ASPEED AST2700 BSP) |
| `meta-zephyr/` | **git submodule** | `dcscm-demo` (Zephyr bootMCU / SSP / TSP) |

## meta-aspeed-sdk (vendored)

Copied — not submoduled — because the ASPEED SDK ships as an in-tree
subdirectory of the `AspeedTech-BMC/openbmc` monorepo fork, not as a standalone
pinned repo (the same reason meta-ami vendors it).

- Source: `git@github.com:AspeedTech-BMC/openbmc.git`
- Branch: `aspeed-master`
- Commit: `59db970dc4ed772070580a18b4c6774029d32110`
- Subtree: `meta-aspeed-sdk/`

### Trim

The following sublayers are intentionally **excluded** — Canopy's `dcscm-demo`
target is non-PFR, single-SoC (AST2700), and non-vendor:

- `meta-aspeed-pfr/` (Intel/Cerberus PFR)
- `meta-ast2500-sdk/`, `meta-ast2600-sdk/` (other SoCs)
- `meta-vendor/` (AMD SP7 etc.)

### Refresh

To (re)create the vendored copy from a checkout of the fork at the pinned
commit (e.g. the `reference/aspeed-openbmc` clone):

```bash
rsync -a --delete \
  --exclude='meta-aspeed-pfr' \
  --exclude='meta-ast2500-sdk' \
  --exclude='meta-ast2600-sdk' \
  --exclude='meta-vendor' \
  reference/aspeed-openbmc/meta-aspeed-sdk/ vendor/meta-aspeed-sdk/
```

## meta-zephyr (submodule)

Generic **upstream** layer — ASPEED ships an unmodified snapshot, so it stays a
submodule (upstream `wrynose`) rather than a vendored copy. It only provides the
Zephyr *build machinery* (`zephyr.bbclass`, `zephyr-image.inc`,
`zephyr-kernel-src-*.inc`).

Requirement: the branch/commit must be `wrynose`-compatible and still ship
`recipes-kernel/zephyr-kernel/zephyr-kernel-src-3.7.0.inc`, because the AST2700
SoC include pins `PREFERRED_VERSION_zephyr-kernel = "3.7.0"` and the ASPEED
coprocessor recipes pull `zephyr-image.inc` -> `zephyr-kernel-src-3.7.0.inc`.

Not provided by meta-zephyr (so its version here doesn't matter for these):

- The Zephyr **SDK toolchain 0.16.9** comes from the vendored `meta-aspeed-sdk`
  (`.../recipes-devtools/zephyr-sdk/zephyr-sdk_0.16.9.bb`).
- The coprocessor firmware **source** is ASPEED's Zephyr fork, fetched by
  `meta-aspeed-sdk` recipes at build time (not a layer/submodule):
  - `github.com/AspeedTech-BMC/zephyr` @ `aspeed-main-v3.7.0`
  - `github.com/AspeedTech-BMC/aspeed-zephyr-project` @ `aspeed-master`
