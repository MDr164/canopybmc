FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Canopy demo console. Only wire this up for the demo machine so other targets
# that consume this bbappend are unaffected.
OBMC_CONSOLE_TTYS:dcscm-demo = "ttyDEMO"

SRC_URI:append:dcscm-demo = " \
    file://server.ttyDEMO.conf \
    file://10-canopy-demo.conf \
    "

do_install:append:dcscm-demo() {
    # Gate the recipe-generated obmc-console@ttyDEMO.service on canopy-demo mode.
    install -d ${D}${systemd_system_unitdir}/obmc-console@ttyDEMO.service.d
    install -m 0644 ${UNPACKDIR}/10-canopy-demo.conf \
        ${D}${systemd_system_unitdir}/obmc-console@ttyDEMO.service.d/10-canopy-demo.conf
}

FILES:${PN}:append:dcscm-demo = " ${systemd_system_unitdir}/obmc-console@ttyDEMO.service.d"
