#!/data/data/com.termux/files/usr/bin/bash
# NovaOS for Android: an XFCE desktop with NovaOS's look, in Arch Linux ARM under proot.
# Android itself is not modified. Needs Termux and Termux:X11, both from their official sources.
#   curl -fsSLo setup-phone.sh https://raw.githubusercontent.com/bbancoooooooooool/novaos-repo/main/setup-phone.sh && bash setup-phone.sh
set -e
REPO=https://raw.githubusercontent.com/bbancoooooooooool/novaos-repo/main/x86_64
BRANDING=novaos-branding-2026.11-1-any.pkg.tar.zst

if [ "$(uname -m)" != "aarch64" ]; then
  echo "This setup needs a 64-bit ARM phone (aarch64). This phone is: $(uname -m)" >&2
  exit 1
fi
if [ -z "$PREFIX" ] || [ ! -x "$PREFIX/bin/pkg" ]; then
  echo "Run this inside the Termux app." >&2
  exit 1
fi

echo "==> Installing Termux packages"
export DEBIAN_FRONTEND=noninteractive
pkg update -y -o Dpkg::Options::=--force-confold
pkg install -y x11-repo
pkg install -y proot-distro termux-x11-nightly pulseaudio curl

echo "==> Downloading Arch Linux ARM (about 200 MB; 4 GB free is recommended for everything)"
proot-distro login archlinux -- true 2>/dev/null || proot-distro install archlinux

echo "==> Setting up the NovaOS desktop inside it (this takes a while)"
cat > "$TMPDIR/novaos-inner.sh" <<INNER
set -e
# proot cannot use pacman's download sandbox
grep -q '^DisableSandbox' /etc/pacman.conf || sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf
pacman -Syu --noconfirm --needed xfce4 xfce4-terminal dbus sudo git python nodejs npm noto-fonts ttf-dejavu libarchive curl
# Looks and browser are nice to have: a missing package must not stop the setup
for p in materia-gtk-theme papirus-icon-theme inter-font firefox; do
  pacman -S --noconfirm --needed "\$p" || echo "Skipped \$p"
done
id nova >/dev/null 2>&1 || useradd -m -s /bin/bash nova
echo 'nova ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/nova

# Wallpaper and logo from the published NovaOS branding package
curl -fsSL "$REPO/$BRANDING" -o /tmp/branding.pkg
bsdtar -xf /tmp/branding.pkg -C / usr/share/backgrounds/novaos usr/share/pixmaps/novaos.png
rm -f /tmp/branding.pkg

H=/home/nova/.config
mkdir -p "\$H/xfce4/xfconf/xfce-perchannel-xml" "\$H/autostart"
cat > "\$H/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Materia-dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Inter 10"/>
  </property>
</channel>
XML
cat > "\$H/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Materia-dark"/>
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
XML
cat > /usr/local/bin/novaos-phone-wallpaper <<'SH'
#!/bin/sh
WP=/usr/share/backgrounds/novaos/default.png
sleep 5
xfconf-query -c xfce4-desktop -n -t string -p /backdrop/screen0/monitorscreen/workspace0/last-image -s "\$WP"
for prop in \$(xfconf-query -c xfce4-desktop -l | grep '/last-image\$'); do
  xfconf-query -c xfce4-desktop -p "\$prop" -s "\$WP"
done
SH
chmod 755 /usr/local/bin/novaos-phone-wallpaper
printf '[Desktop Entry]\nType=Application\nName=NovaOS wallpaper\nExec=novaos-phone-wallpaper\nNoDisplay=true\n' > "\$H/autostart/novaos-wallpaper.desktop"
chown -R nova:nova /home/nova
INNER
# --shared-tmp makes Termux's temp folder appear as /tmp inside
proot-distro login archlinux --shared-tmp -- bash /tmp/novaos-inner.sh
rm -f "$TMPDIR/novaos-inner.sh"

echo "==> Creating the 'novaos' command"
cat > "$PREFIX/bin/novaos" <<'START'
#!/data/data/com.termux/files/usr/bin/bash
# Start the NovaOS desktop; open the Termux:X11 app to see it.
pulseaudio --start --exit-idle-time=-1 --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" 2>/dev/null
termux-x11 :0 >/dev/null 2>&1 &
sleep 3
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
exec proot-distro login archlinux --user nova --shared-tmp -- \
  env DISPLAY=:0 PULSE_SERVER=127.0.0.1 dbus-launch --exit-with-session startxfce4
START
chmod 755 "$PREFIX/bin/novaos"

echo
echo "Done. Start the desktop any time by typing: novaos"
