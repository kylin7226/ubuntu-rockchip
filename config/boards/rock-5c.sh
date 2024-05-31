# shellcheck shell=bash

export BOARD_NAME="ROCK 5C"
export BOARD_MAKER="Radxa"
export UBOOT_PACKAGE="u-boot-radxa-rk3588"
export UBOOT_RULES_TARGET="rock-5c-rk3588s"

function config_image_hook__rock-5c() {
    local rootfs="$1"
    local overlay="$2"

    # Install panfork
    chroot "${rootfs}" add-apt-repository -y ppa:jjriek/panfork-mesa
    chroot "${rootfs}" apt-get update
    chroot "${rootfs}" apt-get -y install mali-g610-firmware
    chroot "${rootfs}" apt-get -y dist-upgrade

    # Install AIC8800 WiFi and Bluetooth DKMS
    chroot "${rootfs}" apt-get -y install dkms aic8800-firmware aic8800-usb-dkms

    # shellcheck disable=SC2016
    echo 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="88:00:*", NAME="$ENV{ID_NET_SLOT}"' > "${rootfs}/etc/udev/rules.d/99-radxa-aic8800.rules"

    # Fix and configure audio device
    mkdir -p "${rootfs}/usr/lib/scripts"
    cp "${overlay}/usr/lib/scripts/alsa-audio-config" "${rootfs}/usr/lib/scripts/alsa-audio-config"
    cp "${overlay}/usr/lib/systemd/system/alsa-audio-config.service" "${rootfs}/usr/lib/systemd/system/alsa-audio-config.service"
    chroot "${rootfs}" systemctl enable alsa-audio-config

    # Use ttyFIQ0 for serial console output
    sed -i 's/console=ttyS2,1500000/console=ttyFIQ0,1500000n8/g' "${rootfs}/etc/kernel/cmdline"

    return 0
}
