SUMMARY = "Canopy demo-mode toggle: fake inventory, sensors and console replay"
DESCRIPTION = "Demo aid for the AST2700 DC-SCM demo target, which has no FRU \
EEPROM, no reliable host power-on, and no real sensors. 'canopy-demo on' \
publishes fake-but-plausible system/chassis inventory and a handful of live \
sensors on D-Bus (so the WebUI dashboard and Redfish look useful) and replays a \
pre-recorded host boot log onto the SOL console (so the WebUI serial/KVM window \
looks alive). Never installed on production images."

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit meson pkgconfig systemd

DEPENDS = " \
    sdbusplus \
    boost \
    systemd \
    "

# socat backs the console replay PTY; obmc-console serves it to the WebUI.
RDEPENDS:${PN} += "socat obmc-console"

SRC_URI = " \
    file://meson.build \
    file://main.cpp \
    file://canopy-demo \
    file://canopy-demo-bootlog \
    file://bootlog.txt \
    file://canopy-demo.target \
    file://canopy-demo-mock.service \
    file://canopy-demo-console.service \
    file://canopy-demo.tmpfiles \
    "

S = "${UNPACKDIR}"

do_install:append() {
    # Toggle CLI and boot-log replay helper.
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/canopy-demo ${D}${bindir}/canopy-demo
    install -m 0755 ${UNPACKDIR}/canopy-demo-bootlog ${D}${bindir}/canopy-demo-bootlog

    # Pre-recorded boot log.
    install -d ${D}${datadir}/canopy-demo
    install -m 0644 ${UNPACKDIR}/bootlog.txt ${D}${datadir}/canopy-demo/bootlog.txt

    # systemd units + target.
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/canopy-demo.target ${D}${systemd_system_unitdir}/
    install -m 0644 ${UNPACKDIR}/canopy-demo-mock.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${UNPACKDIR}/canopy-demo-console.service ${D}${systemd_system_unitdir}/

    # tmpfiles entry that creates the enable flag at boot -> demo mode on by
    # default (the units are ConditionPathExists-gated on it).
    install -d ${D}${sysconfdir}/tmpfiles.d
    install -m 0644 ${UNPACKDIR}/canopy-demo.tmpfiles ${D}${sysconfdir}/tmpfiles.d/canopy-demo.conf
}

FILES:${PN} += " \
    ${bindir}/canopy-demo \
    ${bindir}/canopy-demo-bootlog \
    ${datadir}/canopy-demo \
    ${sysconfdir}/tmpfiles.d/canopy-demo.conf \
    ${systemd_system_unitdir} \
    "

# Demo mode is ON by default on the demo image: the units are enabled and the
# enable flag is created at boot (see canopy-demo.tmpfiles). 'canopy-demo off'
# disables the units and removes the flag to turn it off (persists across boot).
SYSTEMD_SERVICE:${PN} = " \
    canopy-demo.target \
    canopy-demo-mock.service \
    canopy-demo-console.service \
    "
SYSTEMD_AUTO_ENABLE = "enable"
