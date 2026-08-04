# Canopy dcscm-demo image trim.
#
# The vendored ASPEED SDK image bbappend
# (vendor/meta-aspeed-sdk/recipes-core/images/obmc-phosphor-image.bbappend)
# injects OSS test-tool and Intel PMCI/MCTP packagegroups into the image. For
# the minimal branded demo these are unwanted, and some fail to build against
# Canopy's newer toolchain (e.g. libmctp-intel's tests trip -Werror=array-bounds
# on the current GCC). MCTP is out of scope for the demo.
#
# Drop those packagegroups. IMAGE_INSTALL:remove is applied after the SDK's
# IMAGE_INSTALL:append, so it wins. The essential aspeed-g7 image class and the
# aspeed packagegroups from that SDK bbappend are kept.
IMAGE_INSTALL:remove = " \
    packagegroup-oss-apps \
    packagegroup-oss-libs \
    packagegroup-oss-intel-pmci \
    packagegroup-oss-extended \
    "
