#!/usr/bin/env bash

# This is the merged master script after each individual component was tested
# TODO LIST
# Google Drive Client usage - https://github.com/astrada/google-drive-ocamlfuse
# Server setup script
# To ever learn VIM ? -> https://www.cs.oberlin.edu/~kuperman/help/vim/indenting.html auto indent is nice
# Future self -> if the audio sounds "god awful", please make sure to only keep max volume at 100%, THEN crank it up via headphones, it distorts the hell out of the bass

function atom_cpp_development_environment() {
  echo "[+] Installing Atom and other handy text editors..."
  sudo apt-get install git -y
  link="https://atom.io/download/deb"
  echo "[+] Downloading Atom Deb...."
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
}

function track_pad() {
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
}

function battery_settings() {
  sudo add-apt-repository -y ppa:linrunner/tlp
  sudo apt-get update
  sudo apt-get install tlp tlp-rdw -y
}

function disabling_graphics() {
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
}

function clean_desktop() {
  sudo apt-get remove hexchat hexchat-common tomboy gstreamer1.0-packagekit transmission-gtk transmission-common thunderbird thunderbird-gnome-support thunderbird-locale-en thunderbird-locale-en-us xplayer xplayer-common xplayer-dbg xplayer-plugins rhythmbox rhythmbox-data rhythmbox-plugin-tray-icon rhythmbox-plugins gir1.2-rb-3.0:amd64 -y
 if [ ! -d ~/scripts/ ]; then
   git --version > /dev/null 2>&1 || sudo apt-get install git -y
   cd ~
   git clone https://github.com/JaredDyreson/scripts.git
 fi
 echo "PATH=$PATH$( find "$HOME/scripts" -type d -not -path '*/\.*' -printf ":%p" )" >> ~/.bashrc
 source ~/.bashrc
 startup_application "Disable Caps Lock" "setxkbmap -option ctrl:nocaps"
 mkdir -p ~/Pictures/Wallpapers
 if [ -d /media/"$USER"/External ]; then
   cp -ar /media/"$USER"/External/Dell\ XPS\ Files/VenomWallpaper.png ~/Pictures/Wallpapers
   gsettings set org.cinnamon.desktop.background picture-uri 'file:///home/'$USER'/Pictures/Wallpapers/VenomWallpaper.png'
 fi
 sudo add-apt-repository ppa:daniruiz/flat-remix -y
 sudo apt-get update
 sudo apt-get install flat-remix flat-remix-gtk -y
 gsettings set org.cinnamon.desktop.wm.preferences theme 'Mint-Y-Dark'
 gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark'
 gsettings set org.cinnamon.desktop.interface cursor-theme 'DMZ-Black'
 gsettings set org.cinnamon.desktop.interface icon-theme 'Flat-Remix'
 gsettings set org.cinnamon.desktop.interface clock-show-date true
 gsettings set org.cinnamon.desktop.interface clock-use-24h true

 dconf help > /dev/null || sudo apt-get install dconf-cli -y
 wget --quiet -O xt http://git.io/v3Dlm && chmod +x xt && ./xt && rm xt

 if [ -f /media/"$USER"/External/Dell\ XPS\ Files/keybindings ]; then
   cp -ar /media/"$USER"/External/Dell\ XPS\ Files/keybindings keys
   dconf load /org/cinnamon/desktop/keybindings < keys
   rm keys
 fi
 sudo apt-get update
 sudo apt-get install vim gedit -y
 sudo apt-get upgrade -y
 sudo apt-get install gphoto2 shutter fdupes ffmpeg vlc ffmpegthumbnailer   -y
}

function python_env() {
  pip --version > /dev/null 2>&1 || sudo apt-get install python-pip -y
  pip3 --version > /dev/null 2>&1 || sudo apt-get install python3-pip -y
  # leave this for the CPSC-223P class, not really a Python dev
  sudo -H pip2 install python-magic
  sudo -H pip3 install python-magic
  sudo -H pip3 install exifread > /dev/null 2>&1 || sudo -H pip3 install setuptools && sudo -H pip3 install exifread
}

function mips_env() {
  # code for most of this -> https://stackoverflow.com/questions/31966951/linux-binutils-using-as-to-assemble-mips
  # reddit post -> https://www.reddit.com/r/csuf/comments/6utk87/cpsc_240_computer_organization_and_assembly/
  # YouTube Playlist -> https://www.youtube.com/playlist?list=PL5b07qlmA3P6zUdDf-o97ddfpvPFuNa5A

  # I actually don't know if this class actually teaches MIPS, I am leaving this until the semester starts
  sudo apt-get update && sudo apt-get install spim
  git --version > /dev/null 2>&1 || sudo apt-get install git -y
  if [ ! -d CPSC_240 ]; then
    git clone https://github.com/JaredDyreson/CPSC_240.git
  fi
  sudo apt-get install build-essential -y
  # wget -q http://git.qemu-project.org/?p=dtc.git;a=snapshot;h=1760e7ca03894689118646e229ca9487158cd0e8;sf=tgz
  git clone git://git.qemu-project.org/qemu.git
  tar -xzvf dtc-1760e7c.tar.gz
  cd dtc-1760e7c
  cp * ../qemu/dtc
  cp -r Documentation/ ../qemu/dtc
  cp -r libfdt/ ../qemu/dtc
  cp -r scripts/ ../qemu/dtc
  cp -r tests/ ../qemu/dtc
  cd ..
  cd qemu/dtc
  make
  cd ..
  ./configure
  make
  make install
  cd ..
  wget http://ftp.de.debian.org/debian/dists/squeeze/main/installer-mips/current/images/malta/netboot/initrd.gz
  wget http://ftp.de.debian.org/debian/dists/squeeze/main/installer-mips/current/images/malta/netboot/vmlinux-2.6.32-5-4kc-malta
  qemu-img create -f qcow2 debian_mips.qcow2 2G
  qemu-system-mips -hda debian_mips.qcow2 -kernel vmlinux-2.6.32-5-4kc-malta -initrd initrd.gz -append "root=/dev/ram console=ttyS0" -nographic
  ssh --version > /dev/null 2>&1 || sudo apt-get install ssh -y

}

function tranfer_files() {
  if [ -d /media/"$USER"/External ]; then
    cp -ar /media/"$USER"/External/Dell\ XPS\ Files/Documents ~/Documents/

  fi
}
dialog --version > /dev/null 2>&1 || sudo apt-get install dialog -y
cmd=(dialog --separate-output --checklist "Select options:" 22 76 16)
options=(1 "Atom Development Environment" off    # any option can be set to default to "on"
         2 "Battery Settings" off
         3 "Configure Graphics" off
         4 "Configure Desktop" off
         5 "Trackpad" off
         6 "CPSC-223P: Python" off
         7 "CPSC-240: Assembly" off
         8 "Transfer Files" off)
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        1)
          atom_cpp_development_environment
          ;;
        2)
          battery_settings
          ;;
        3)
	        disabling_graphics
          ;;
        4)
          clean_desktop
          ;;
        5)
          track_pad
	        ;;
        6)
	        python_env
	        ;;
	      7)
	        echo "CPSC-240"
	        ;;
    esac
done
