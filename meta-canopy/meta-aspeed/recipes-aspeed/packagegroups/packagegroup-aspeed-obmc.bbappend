# Canopy dcscm-demo fix-up for the vendored ASPEED system packagegroup.
#
# The ASPEED "inband" group lists every IPMI transport, but phosphor-ipmi-bt and
# phosphor-ipmi-ssif both PROVIDE virtual/obmc-host-ipmi-hw and get deselected
# because this machine prefers phosphor-ipmi-kcs (see dcscm-demo.conf). That
# makes them unbuildable-by-name and breaks the packagegroup (and the image).
#
# Trim the inband list to the transports that actually build here. phosphor-
# ipmi-ipmb does not provide that virtual, so it is kept.
RDEPENDS:${PN}-inband = "phosphor-ipmi-kcs phosphor-ipmi-ipmb"
