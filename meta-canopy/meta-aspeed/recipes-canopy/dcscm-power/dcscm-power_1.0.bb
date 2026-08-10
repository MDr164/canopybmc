SUMMARY = "Minimal host power control helper for the AST2700 DC-SCM demo"
DESCRIPTION = "Bring-up helper that toggles the two demo power GPIOs directly \
(PS_ON hold-high + PWR_BTN pulse-low) with no x86-power-control daemon. Resolves \
the lines by name from the dcscm-demo device tree gpio-line-names. Intended for \
bench testing of the power wiring."

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://dcscm-power.sh"

S = "${UNPACKDIR}"

# gpioinfo/gpioset come from libgpiod-tools.
RDEPENDS:${PN} = "libgpiod-tools"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/dcscm-power.sh ${D}${bindir}/dcscm-power
}

FILES:${PN} = "${bindir}/dcscm-power"
