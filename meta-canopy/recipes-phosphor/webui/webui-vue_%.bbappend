# Canopy WebUI customization
# Installs canopy settings as .env.production so vite can pick it up.
# With the migration from vue-cli to vite, the "NODE_ENV" variable got
# deprecated in vite and should not be used anymore. Now, the "mode"
# that's being used for evaluation is not the node env, but the environment
# (e.g. IBM, Intel), which breaks gzip compression.
# Therefore, we must copy the dotenv file to .env.production to get a working
# theme.

# Activates --mode canopy which loads .env.canopy and _canopy.scss
# for Canopy branding (purple theme, Canopy logos, Inter font).
#
# All customization files are overlaid into the upstream webui-vue
# source tree at build time via do_configure:prepend, so the
# upstream repo stays untouched.
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-firmware-add-update-target-dropdown-to-form.patch \
    "

# Canopy demo UI mode.
#
# When CANOPY_WEBUI_DEMO = "1", the built WebUI serves hardcoded Redfish data
# from a mock axios adapter (src/env/demo) and auto-authenticates, so the
# dashboard shows a plausible Canopy server with no BMC/FRU/host at all. It also
# gains a "Settings > Demo mode" toggle to turn it off/on at runtime (the choice
# persists in the browser and reloads the UI). Demo mode is ON by default in the
# image env (VITE_DEMO_MODE=true, set in do_configure:append below).
#
# Leave "0" for real images: then the hooks/demo sources are not overlaid at all,
# so production builds and behaviour are byte-for-byte unaffected. The dcscm-demo
# machine sets this to "1" (see conf/machine/dcscm-demo.conf).
#
# The same sources drive the local dev preview (meta-canopy/scripts/webui-demo.sh).
CANOPY_WEBUI_DEMO ?= "0"
SRC_URI:append = " ${@' file://0002-webui-add-canopy-demo-ui-mode-hooks.patch' if d.getVar('CANOPY_WEBUI_DEMO') == '1' else ''}"

# Resolve the overlay directory at parse time
CANOPY_WEBUI_OVERLAYS := "${THISDIR}/${BPN}"

do_configure:prepend() {
    # Overlay Canopy customization files into the source tree
    install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/dot-env.canopy ${S}/.env.production

    install -d ${S}/src/env/assets/styles
    install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/_canopy.scss ${S}/src/env/assets/styles/_canopy.scss

    install -d ${S}/src/assets/images
    install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/login-company-logo.svg ${S}/src/assets/images/login-company-logo.svg
    install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/logo-header.svg ${S}/src/assets/images/logo-header.svg
    install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/built-on-openbmc-logo.svg ${S}/src/assets/images/built-on-openbmc-logo.svg

    install -d ${S}/public
    install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/favicon.ico ${S}/public/favicon.ico
}

# Overlay the demo UI mode sources and switch demo mode ON by default, only when
# enabled. The 0002 patch (added to SRC_URI above) wires src/env/demo and the
# Settings > Demo mode page into the app; the appended VITE_DEMO_MODE makes it
# the default (the Settings toggle can still turn it off per browser).
do_configure:append() {
    if [ "${CANOPY_WEBUI_DEMO}" = "1" ]; then
        install -d ${S}/src/env/demo
        install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/demo/config.js ${S}/src/env/demo/config.js
        install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/demo/demoData.js ${S}/src/env/demo/demoData.js
        install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/demo/mockAdapter.js ${S}/src/env/demo/mockAdapter.js
        install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/demo/initDemoMode.js ${S}/src/env/demo/initDemoMode.js

        install -d ${S}/src/views/Settings/DemoMode
        install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/demo-views/Settings/DemoMode/DemoMode.vue ${S}/src/views/Settings/DemoMode/DemoMode.vue
        install -m 0644 ${CANOPY_WEBUI_OVERLAYS}/demo-views/Settings/DemoMode/index.js ${S}/src/views/Settings/DemoMode/index.js

        # Demo mode on by default (Settings > Demo mode can still toggle it off).
        echo "VITE_DEMO_MODE=true" >> ${S}/.env.production
    fi
}
