# dell-xps-15-9560-ubuntu
Tracking missing features, drivers, workarounds and hacks for the Dell New XPS 15 9560 on Ubuntu Linux

# Issues

The Linux Kernel 4.10+ does not play nice with the graphics drivers from Nvidia (nvidia-384) as it does not allow the user to boot into the login screen. Using the default kernel in Linux Mint 18.2 Soyna (4.8.0-58-generic) is recommended

Shutting down does not work as it will hang with an underscore in the top left-hand corner. Manual shutdown is required. Shutdown is possible when booted in recovery mode from the GRUB loader which does not require/utilize the installed graphics card and driver. This indicates there is an issue with the graphics card driver 384 from Nvidia.
After some more investigating it turns out that disabling the grpahics card entirely does the trick nicely. Although it does raise CPU usage, it allows the user to shutdown properly. Replacing the line GRUB_CMDLINE_LINUX_DEFAULT="quiet splash" with GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nomodeset" in /etc/default/grub and running sudo update grub fixes the issue. 
