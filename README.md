# dell-xps-15-9560-ubuntu
Tracking missing features, drivers, workarounds and hacks for the Dell New XPS 15 9560 on Ubuntu Linux

# CPP Development Environment
```bash
# Atom
link="https://atom.io/download/deb"
wget --quiet "$link" -O atom.deb
sudo dpkg -i atom.deb
rm atom.deb
declare -a arr=("atom-html-preview" "autocomplete-clang" "autocomplete-ctags" "autocomplete-python"   "busy-signal" "gcc-make-run" "language-x86asm" "linter" "linter-clang" "intentions" "linter-gcc" "linter-ui-default" "pdf-view" "sort-lines")
for package in ${arr[@]}; do
  sudo apm install "$package"
done
if [ -d /media/"$USER"/External ]; then
  sudo cp -ar /media/"$USER"/External/Dell\ XPS\ Files/config.cson ~/.atom/
fi
sudo apt-get install clang++-6.0 -y
sudo chown "$USER" ~/.atom

# CPP Manuals
git clone https://github.com/jeaye/stdman.git
cd stdman
./configure
sudo make install
sudo mandb
rm -rf stdman/
```
# Issues

The Linux Kernel 4.10+ does not play nice with the graphics drivers from Nvidia (nvidia-384) as it does not allow the user to boot into the login screen. Using the default kernel in Linux Mint 18.2 Soyna (4.8.0-58-generic) is recommended

Shutting down does not work as it will hang with an underscore in the top left-hand corner. Manual shutdown is required. Shutdown is possible when booted in recovery mode from the GRUB loader which does not require/utilize the installed graphics card and driver. This indicates there is an issue with the graphics card driver 384 from Nvidia.
After some more investigating it turns out that disabling the grpahics card entirely does the trick nicely. Although it does raise CPU usage, it allows the user to shutdown properly. Replacing the line GRUB_CMDLINE_LINUX_DEFAULT="quiet splash" with GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nomodeset" in /etc/default/grub and running sudo update grub fixes the issue. 

# Trackpad
This script should be able to fix the track pad issues
```bash
  git --help || sudo apt-get install git -y
  sudo apt remove xserver-xorg-input-synaptics-hwe-16.04 -y
  sudo apt-get install xserver-xorg-core-hwe-16.04 -y
  sudo apt install xserver-xorg-input-libinput-hwe-16.04 -y
  cd /tmp
  git clone http://github.com/bulletmark/libinput-gestures
  cd libinput-gestures
  sudo make install
  sudo apt install libinput-tools xdotool -y
  sudo gpasswd -a "$USER" input
  libinput-gestures-setup autostart
```
# Battery
```bash
  sudo add-apt-repository -y ppa:linrunner/tlp
  sudo apt-get update
  sudo apt-get install tlp tlp-rdw -y
```
Get better battery life

# Idea
Webscrape to find the latest kerenel revision from here ---> https://kernel.ubuntu.com/~kernel-ppa/mainline/
Do a search through that folder for these files

```
linux-headers-VERSION-NUMBER_all.deb
linux-headers-VERSION-NUMBER_amd64.deb
linux-image-VERSION-NUMBER_amd64.deb
linux-image-extra-VERSION-NUMBER_amd64.deb   # if available
```
# Turning off the graphics card

```bash
#!/usr/bin/env bash

if [[ $(whoami) != "root" ]]; then
  echo "[-] Please run as root..."
  exit
fi

sudo apt-get install acpi acpi-call-dkms -y
sudo modprobe acpi_call
if [[ $(dmesg | grep acpi_call | wc -l) -gt 0 ]]; then
  echo "[+] Module is successfully attached...."
fi
echo '_SB.PCI0.PEG0.PEGP._OFF' | sudo tee /proc/acpi/call
sudo echo acpi_call > /etc/modules-load.d/acpi_call.conf
cat <<'EOF' >/usr/lib/systemd/user/dgpu-off.service
[Unit]
Description=Power-off dGPU
After=graphical.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo '\\_SB.PCI0.PEG0.PEGP._OFF' > /proc/acpi/call; cat /proc/acpi/call > /tmp/nvidia-off"

[Install]
WantedBy=graphical.target
EOF
systemctl enable /usr/lib/systemd/user/dgpu-off.service
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash modprobe.blacklist=nouveau i915.preliminary_hw_support=1 acpi_rev_override=5"/g' /etc/default/grub
sudo update-grub
reboot

```

