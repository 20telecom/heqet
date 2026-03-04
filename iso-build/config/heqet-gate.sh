#!/bin/sh
# Heqet Installation Gate - runs before any install actions

INSTALLED_MARKER="/opt/in1click/.installed"
for disk in /dev/sda1 /dev/vda1 /dev/nvme0n1p1; do
    if mount "$disk" /mnt 2>/dev/null; then
        if [ -f "/mnt${INSTALLED_MARKER}" ]; then
            umount /mnt
            echo ""
            echo "============================================"
            echo "  Installed system detected."
            echo "  Rebooting in 10 seconds..."
            echo "  Press any key to reinstall anyway."
            echo "============================================"
            if read -t 10 -n 1 2>/dev/null; then
                echo "Reinstall requested. Continuing..."
            else
                echo "Rebooting to installed system..."
                reboot -f
            fi
        fi
        umount /mnt 2>/dev/null
        break
    fi
done


# Pin to tty1 so output/input are visible early
if [ -c /dev/tty1 ]; then
    exec < /dev/tty1 > /dev/tty1 2>&1
    if command -v chvt >/dev/null 2>&1; then
        chvt 1 2>/dev/null || true
    fi
fi

# Clear screen; ignore errors if not a TTY
clear 2>/dev/null || true

# Minimal color palette + accent (auto-disables if not a tty)
if [ -t 1 ]; then
    RED="\033[1;31m"; GREEN="\033[1;32m"; CYAN="\033[1;36m"; MAG="\033[1;35m"; GRAY="\033[2;37m"; RESET="\033[0m"; PASS_STYLE="\033[1;37m"
else
    RED=""; GREEN=""; CYAN=""; MAG=""; GRAY=""; RESET=""; PASS_STYLE=""
fi

printf "\n"
printf "  +---------------------------------------------------------+\n"
printf "  |    Heqet 1.2.0  -  FreePBX 17  -  Zero-Touch Install    |\n"
printf "  +---------------------------------------------------------+\n"
# Gold/Yellow color
GOLD='\033[38;5;178m'
CYAN='\033[38;5;51m'
BWHITE='\033[1;37m'
NC='\033[0m' # No Color

printf "\n"
printf "${BWHITE}                 Egyptian Eyes by 20tele.com${NC}\n"
printf "\n"
printf "${GOLD}                                 ////${NC}\n"
printf "${GOLD}               ////             ////       ////${NC}\n"
printf "${GOLD}              ////        ${CYAN}@@@@@@@@@@${GOLD}        ////${NC}\n"
printf "${GOLD}             ////        ${CYAN}@@@@@@@@@@@@${GOLD}        ////${NC}\n"
printf "${GOLD}            ////        ${CYAN}@@@@@@@@@@@@@@${GOLD}        ////${NC}\n"
printf "${GOLD}            ////        ${CYAN}@@@@@@@@@@@@@@${GOLD}        ////${NC}\n"
printf "${GOLD}             ////        ${CYAN}@@@@@@@@@@@@${GOLD}        ////${NC}\n"
printf "${GOLD}              ////        ${CYAN}@@@@@@@@@@${GOLD}       ////${NC}\n"
printf "${GOLD}               ////       ////           ////${NC}\n"
printf "${GOLD}                         ////${NC}\n"
printf "\n"
printf "${BWHITE}                    Seeing is Believing${NC}\n"
printf "\n"
printf "  +---------------------------------------------------------+\n"
printf "  |    You are installing FreePBX 17 with the Heqet ISO     |\n"
printf "  +---------------------------------------------------------+\n"
printf "\n"
printf "\033[1;31m       WARNING: This will WIPE EVERYTHING on the server\033[0m\n"
printf "  "
i=10
while [ "$i" -ge 1 ]; do
    if [ "$i" -eq 10 ]; then
        printf "%s" "$i"
    else
        printf "\r  %2s" "$i"
    fi
    sleep 1
    i=$((i - 1))
done
printf "\r    \r\n"
printf "  Generating root password for you...\n"
set +x

if ! command -v busybox >/dev/null 2>&1; then
    printf "  ${RED}Missing busybox in installer environment.${RESET}\n"
    printf "  Unable to generate a secure password. Aborting.\n\n"
    sleep 5
    reboot
    exit 1
fi

PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)

printf "\n"
# Cycle password through colours so the user notices it on the console
for _colour in \
    '\033[1;31m' \
    '\033[1;32m' \
    '\033[1;33m' \
    '\033[1;34m' \
    '\033[1;35m' \
    '\033[1;36m' \
    '\033[1;37m'; do
    printf "\r  The root password: ${_colour}%s${RESET}  " "$PASSWORD"
    sleep 1
done
printf "\r  The root password: ${PASS_STYLE}%s${RESET}  \n" "$PASSWORD"
printf "\n  Store this password securely and select a locale\n"
printf "%s" "$PASSWORD" > /tmp/heqet-pw
unset PASSWORD

while true; do
    printf "    1) en_US\n"
    printf "    2) en_GB\n"
    printf "    0) Abort\n"
    printf "  Choose one to proceed with the installation [0]: "
    read -r region_choice
    printf "${RESET}"

    case "$region_choice" in
        ""|0)
            clear 2>/dev/null || true
            printf "\n  ${RED}■ Installation aborted ■${RESET}\n\n"
            printf "  Rebooting in 5 seconds...\n\n"
            sleep 5
            reboot
            exit 1
            ;;
        1)
            locale_value="en_US.UTF-8"
            keymap_value="us"
            break
            ;;
        2)
            locale_value="en_GB.UTF-8"
            keymap_value="gb"
            break
            ;;
        *)
            printf "  ${RED}Invalid choice. Try again.${RESET}\n\n"
            ;;
    esac
done

# Write locale and keymap to temp files for late_command to apply
printf "%s" "$locale_value" > /tmp/heqet-locale
printf "%s" "$keymap_value" > /tmp/heqet-keymap

# Try to set in debconf too (debconf-set is native to d-i, try it first)
(
if command -v debconf-set >/dev/null 2>&1; then
    debconf-set debian-installer/locale "$locale_value" >/dev/null 2>&1 || true
    debconf-set keyboard-configuration/xkb-keymap "$keymap_value" >/dev/null 2>&1 || true
elif command -v debconf-set-selections >/dev/null 2>&1; then
    printf "debian-installer/locale string %s\n" "$locale_value" | debconf-set-selections >/dev/null 2>&1 || true
    printf "keyboard-configuration/xkb-keymap select %s\n" "$keymap_value" | debconf-set-selections >/dev/null 2>&1 || true
else
    printf "  ${RED}✗ Missing debconf tools; locale will be applied post-install.${RESET}\n"
fi
) </dev/null

clear 2>/dev/null || true
printf "\n  ${GREEN}     ■ Confirmation received ■${RESET}\n\n"
printf "  Starting automated installation...\n\n"
printf "  Please wait while we perform magic\n\n"
exit 0
