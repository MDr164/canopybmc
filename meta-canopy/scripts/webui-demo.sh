#!/usr/bin/env bash
#
# webui-demo.sh - build & run the Canopy WebUI locally in demo UI mode.
#
# Clones the exact webui-vue revision that the Canopy image pins, overlays the
# Canopy branding + demo UI mode sources (the same files shipped in
# meta-canopy/recipes-phosphor/webui/webui-vue), and starts the vite dev server.
# In demo mode the UI serves hardcoded Redfish data from a mock axios adapter
# and auto-authenticates, so the dashboard renders with no BMC/FRU/host.
#
# Usage:
#   meta-canopy/scripts/webui-demo.sh [--build] [--workdir DIR]
#
#   (no args)   clone/overlay, npm install, and run the dev server (default)
#   --build     produce a static production build in <workdir>/dist instead
#   --workdir   working directory for the checkout (default: build/webui-demo)
#
# Requires: node, npm, git, network access (for the clone + npm install).
set -euo pipefail

REPO_URL="https://github.com/openbmc/webui-vue.git"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OVERLAYS="${ROOT}/meta-canopy/recipes-phosphor/webui/webui-vue"
RECIPE="${ROOT}/openbmc/meta-phosphor/recipes-phosphor/webui/webui-vue_git.bb"

MODE="dev"
WORKDIR="${ROOT}/build/webui-demo"
while [ $# -gt 0 ]; do
	case "$1" in
		--build) MODE="build" ;;
		--workdir) shift; WORKDIR="$1" ;;
		*) echo "usage: ${0##*/} [--build] [--workdir DIR]" >&2; exit 1 ;;
	esac
	shift
done

# Pin to the same SRCREV as the image so the preview matches what ships.
SRCREV="$(sed -nE 's/^SRCREV[[:space:]]*=[[:space:]]*"([0-9a-f]+)".*/\1/p' "${RECIPE}" 2>/dev/null || true)"
[ -n "${SRCREV}" ] || { echo "webui-demo: could not read SRCREV from ${RECIPE}" >&2; exit 1; }

echo "webui-demo: webui-vue @ ${SRCREV}"
echo "webui-demo: workdir ${WORKDIR}"

if [ ! -d "${WORKDIR}/.git" ]; then
	mkdir -p "$(dirname "${WORKDIR}")"
	git clone --quiet "${REPO_URL}" "${WORKDIR}"
fi
git -C "${WORKDIR}" fetch --quiet origin || true
git -C "${WORKDIR}" checkout --quiet "${SRCREV}"
git -C "${WORKDIR}" clean -qfd src/env/demo || true

# --- Canopy branding overlays (mirror the recipe's do_configure:prepend) ---
install -Dm0644 "${OVERLAYS}/dot-env.canopy" "${WORKDIR}/.env.production"
install -Dm0644 "${OVERLAYS}/_canopy.scss" "${WORKDIR}/src/env/assets/styles/_canopy.scss"
install -Dm0644 "${OVERLAYS}/login-company-logo.svg" "${WORKDIR}/src/assets/images/login-company-logo.svg"
install -Dm0644 "${OVERLAYS}/logo-header.svg" "${WORKDIR}/src/assets/images/logo-header.svg"
install -Dm0644 "${OVERLAYS}/built-on-openbmc-logo.svg" "${WORKDIR}/src/assets/images/built-on-openbmc-logo.svg"
install -Dm0644 "${OVERLAYS}/favicon.ico" "${WORKDIR}/public/favicon.ico"

# --- Demo UI mode sources + Settings toggle page + app hooks ---
install -Dm0644 "${OVERLAYS}/demo/config.js" "${WORKDIR}/src/env/demo/config.js"
install -Dm0644 "${OVERLAYS}/demo/demoData.js" "${WORKDIR}/src/env/demo/demoData.js"
install -Dm0644 "${OVERLAYS}/demo/mockAdapter.js" "${WORKDIR}/src/env/demo/mockAdapter.js"
install -Dm0644 "${OVERLAYS}/demo/initDemoMode.js" "${WORKDIR}/src/env/demo/initDemoMode.js"
install -Dm0644 "${OVERLAYS}/demo-views/Settings/DemoMode/DemoMode.vue" "${WORKDIR}/src/views/Settings/DemoMode/DemoMode.vue"
install -Dm0644 "${OVERLAYS}/demo-views/Settings/DemoMode/index.js" "${WORKDIR}/src/views/Settings/DemoMode/index.js"
git -C "${WORKDIR}" apply --3way "${OVERLAYS}/0002-webui-add-canopy-demo-ui-mode-hooks.patch" 2>/dev/null \
	|| git -C "${WORKDIR}" apply "${OVERLAYS}/0002-webui-add-canopy-demo-ui-mode-hooks.patch"

# Dev-server env: Canopy branding + demo mode + plain HTTP (no BMC proxy needed).
cat >"${WORKDIR}/.env.development" <<'EOF'
NODE_ENV=development
VITE_ENV_NAME=canopy
VITE_COMPANY_NAME=Canopy
VITE_GUI_NAME="Open. Stable. Ready."
CUSTOM_STYLES=true
VITE_DEMO_MODE=true
DEV_HTTPS=false
EOF
# Production build also needs the demo flag.
grep -q '^VITE_DEMO_MODE=' "${WORKDIR}/.env.production" || echo "VITE_DEMO_MODE=true" >>"${WORKDIR}/.env.production"

if [ ! -d "${WORKDIR}/node_modules" ]; then
	( cd "${WORKDIR}" && npm install --no-audit --no-fund --loglevel warn )
fi

if [ "${MODE}" = "build" ]; then
	( cd "${WORKDIR}" && npm run build )
	echo "webui-demo: static build in ${WORKDIR}/dist (serve with any static server)"
else
	echo "webui-demo: starting dev server on http://127.0.0.1:5173/"
	( cd "${WORKDIR}" && npm run dev -- --host 127.0.0.1 --port 5173 )
fi
