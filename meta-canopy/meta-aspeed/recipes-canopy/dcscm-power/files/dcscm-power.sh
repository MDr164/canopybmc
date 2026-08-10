#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# dcscm-power.sh - minimal host power control for the Canopy AST2700 DC-SCM demo.
#
# Drives the two demo power GPIOs directly, with no x86-power-control daemon.
# Intended for early bring-up / bench testing of the wiring only.
#
#   PS_ON   = line "PS_PWR_ON"        (GPIOU1 / DC-SCI B47) active-high.
#             Held HIGH the whole time the host is meant to be on; enables PSU.
#   PWR_BTN = line "FP_PWR_BTN_OUT_N" (GPIOT0 / DC-SCI B43) active-low.
#             Pulsed LOW to "press" the host power button.
#
# Lines are resolved by name from the dcscm-demo device tree gpio-line-names,
# so no gpiochip/offset numbers are hardcoded here.
#
# Usage:
#   dcscm-power on       # assert PS_ON (held) + pulse power button -> boot
#   dcscm-power off      # release PS_ON            -> main power cut (hard off)
#   dcscm-power press    # pulse the power button only (e.g. soft on/off)
#   dcscm-power status   # show PS_ON hold state + resolved chip/line
#
# Requires libgpiod v1 CLI tools (gpioinfo, gpioset) from libgpiod-tools.
set -u

PS_ON_NAME="PS_PWR_ON"
PWR_BTN_NAME="FP_PWR_BTN_OUT_N"
PULSE_MS="${PULSE_MS:-200}"       # power-button pulse width (override via env)
SETTLE_S="${SETTLE_S:-1}"         # delay between PS_ON assert and button pulse
PIDFILE="/run/dcscm-pson.pid"

need_tools() {
	for t in gpioinfo gpioset; do
		if ! command -v "$t" >/dev/null 2>&1; then
			echo "dcscm-power: '$t' not found; add libgpiod-tools to the image" >&2
			exit 1
		fi
	done
}

# resolve NAME -> "gpiochipN offset" (prints nothing + returns 1 if not found)
resolve() {
	_r=$(gpioinfo 2>/dev/null | awk -v n="\"$1\"" '
		/^gpiochip/ { chip = $1; next }
		index($0, n) {
			for (i = 1; i <= NF; i++)
				if ($i == "line") { o = $(i + 1); sub(/:/, "", o); print chip, o; found = 1; exit }
		}
		END { if (!found) exit 1 }')
	[ -n "$_r" ] || return 1
	printf '%s\n' "$_r"
}

pson_held() {
	[ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null
}

pulse_button() {
	_btn=$(resolve "$PWR_BTN_NAME") || {
		echo "dcscm-power: line '$PWR_BTN_NAME' not found (dcscm-demo DT applied?)" >&2
		exit 1
	}
	# active-low: drive 0 for PULSE_MS then release
	# word-splitting of "$_btn" into <chip> <offset> is intentional
	# shellcheck disable=SC2086
	gpioset --mode=time --usec=$((PULSE_MS * 1000)) $_btn=0
}

cmd_on() {
	_line=$(resolve "$PS_ON_NAME") || {
		echo "dcscm-power: line '$PS_ON_NAME' not found (dcscm-demo DT applied?)" >&2
		exit 1
	}
	if pson_held; then
		echo "PS_ON already asserted (pid $(cat "$PIDFILE"))"
	else
		# hold PS_ON high until released; nohup so it survives an ssh logout
		# shellcheck disable=SC2086
		nohup gpioset --mode=signal $_line=1 >/dev/null 2>&1 &
		echo $! >"$PIDFILE"
		echo "PS_ON asserted (held high, pid $!)"
		sleep "$SETTLE_S"
	fi
	pulse_button
	echo "power button pulsed ${PULSE_MS}ms -> host ON"
}

cmd_off() {
	if pson_held; then
		kill "$(cat "$PIDFILE")" 2>/dev/null
	fi
	rm -f "$PIDFILE"
	echo "PS_ON released -> host OFF (main power cut)"
}

cmd_press() {
	pulse_button
	echo "power button pulsed ${PULSE_MS}ms"
}

cmd_status() {
	if pson_held; then
		echo "PS_ON  : ASSERTED (held, pid $(cat "$PIDFILE"))"
	else
		echo "PS_ON  : released"
	fi
	if _p=$(resolve "$PS_ON_NAME"); then echo "PS_ON  line   : $_p"; else echo "PS_ON  line   : NOT FOUND"; fi
	if _b=$(resolve "$PWR_BTN_NAME"); then echo "PWR_BTN line  : $_b"; else echo "PWR_BTN line  : NOT FOUND"; fi
}

need_tools
case "${1:-}" in
	on)     cmd_on ;;
	off)    cmd_off ;;
	press)  cmd_press ;;
	status) cmd_status ;;
	*)      echo "usage: ${0##*/} {on|off|press|status}" >&2; exit 1 ;;
esac
