# Canopy AST2700 DC-SCM demo kernel customization.
#
# Adds the "dcscm-demo" device tree, which #includes the in-tree ASPEED
# ast2700-dcscm.dts and layers Canopy demo tweaks on top. Scoped to the
# dcscm-demo machine so other ASPEED machines are unaffected.

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:dcscm-demo = " file://dcscm-demo.dts"

do_configure:append:dcscm-demo() {
    # Drop the demo DTS next to the base DCSCM DTS so the #include resolves.
    cp ${UNPACKDIR}/dcscm-demo.dts ${S}/arch/arm64/boot/dts/aspeed/
}
