# vim: filetype=bash

# Kickstart documentation:
# ------------------------
# https://docs.fedoraproject.org/en-US/fedora/rawhide/install-guide/appendixes/Kickstart_Syntax_Reference/

# =============================================================================

# !!! IMPORTANT NOTICE !!!
#
# All the hashes of the passwords below are actually hashes of password: initialsetup
# This password is being used just for the convenience of easy of installation, and
# IT IS EXPECTED FOR THE USER TO CHANGE THE PASSWORDS AFTER SUCCESSFUL INSTALLATION!

# =============================================================================

# Repositories needed for successful installation - the '--cost' makes sure we install updated packages straight away:
url --mirrorlist="https://mirrors.fedoraproject.org/metalink?repo=fedora-34&arch=x86_64"

repo --name=fedora         --mirrorlist="https://mirrors.fedoraproject.org/metalink?repo=fedora-34&arch=x86_64"
repo --name=fedora-updates --mirrorlist="https://mirrors.fedoraproject.org/metalink?repo=updates-released-f34&arch=x86_64" --cost=0

# =============================================================================

# Use text-only installation method:
text

# Reboot the system after successful installation:
reboot --eject

# Do not run the Setup Agent on first boot (users are configured below):
firstboot --disable

# -----------------------------------------------------------------------------

# System language:
lang en_US.UTF-8

# Keyboard settings:
keyboard --xlayouts='cz' --vckeymap='cz' --switch='grp:win_space_toggle'

# Initial network information:
firewall --enabled --ssh
network --hostname=Normandy-SRX.deekej.io --onboot=yes --bootproto=dhcp --ipv6=auto --device=enp0s31f6 --activate

# System timezone:
timezone Europe/Prague --utc
timesource --ntp-pool=time.cloudflare.com --nts

# System services:
services --enabled="chronyd,sshd"

# Enable SELinux:
selinux --enforcing

# Disable the kdump:
%addon com_redhat_kdump --reserve-mb=auto --disable
%end

# Make sure the GUI is started after booting the Fedora:
xconfig --startxonboot --defaultdesktop=GNOME

# =============================================================================

# Groups/Users configuration:
# ---------------------------

# Additional groups:
group --name=wheel --gid=10
group --name=mock  --gid=135

# Auxiliary user for initial set up (to be deleted once finished):
user --name="setup"  --gecos="Initial Setup" --groups=wheel      --uid=1000   --gid=1000   --iscrypted --password="$6$opyrsUsJd7JsjVyj$lR/BzSO.8aZWgCMzJpX7GmtRXnNCQR2ZskI75mXvgGlZjbOl3Bb1KBMihzCaaIDG8KDh4yg2pvGFprc9i6PVO/"

# Additional users:
user --name="deekej" --gecos="Dee'Kej"       --groups=wheel,mock --uid=117813 --gid=117813 --iscrypted --password="$6$KVtFUm4pKgxdRUMj$xbKzCpLl1SxP8tOuK08WBhsnSxP06MM2aCSbkOYku0eOOQkl2L8m1bHssLGftxoHKRl9ZVGv6m/JkVEsc35SU."

# Root password:
rootpw --iscrypted "$6$U7ns97Pmhrc4gpzn$LGAYwwwBIc6Ulc76tORTaq6fHM1d5xUm2fu.zIG9N0zY3.4T15nq2/MG8yhSfPVeBCDRbJIItvgQNko3UbZ/7/" --lock

# Add initial SSH keys into authorized_keys so we can manage the machine with
# Ansible after the installation:
sshkey --username='setup' "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDQggIK3F1iObhzOHl9NBsX+4UiKZCALrH/HENwiXYBDHhJgRWPJSqscKtrNTmLQ1TYMXjYC6n+Yv8zoWvbgd/nOfN64wNL9zT8WfU/YdGTrz2NaNLzb5KZbdDTyJxXR/OqF7aySu4wbxLAEHkSJ4l7FzZHNfIxN3rR141DuOHJG4kiOQk8PoHUxbySoI5VBmT6CMmXl0A8TwJrwPj18jDaOvoPqK925oJ+EKWpLKug3B08Q33FcodkaWufSTYdjS+1K/csfxPeVfT5ZK2Ct5FKKfxks9wE1vyGPegLrFTZ05iZUruR5g8g1khfDOlSGhP9tMV1PclOJrlQS5Yav0kmxmKJapeKTpEUAf2fuyEtEOda2poQqasKQSHPQj7DnWMo6OVUzJmJVbAFeeXk9aJJ0q+Ar4bnPcUdYvwxHEKZW41SUt8WFMiCzO+oVxw575WsOJDE56f2z6FMfe2Dn3Cjr8FWy1x5WU9PbvtYnXAR1wxySxoZA3c76KBElKgST3EYdwzsGq5VvzrBnB1iTy3otXNzOL2lCcHjRZcL6b2j4Iw9o9rehhEoCr4xY1qAv3uPT4b5pdZqxePxrs5IYkgi/VAI0QRqBogNSzl68TQQmzJQKbXXzWXtYoXsRKl5gQx+CmoKdzYpo7cftJtXsgkPIlab+M7nv5YrenjccjW+bw== admin@deekej.io"

# =============================================================================

# Disk partitioning:
# ------------------

# Make sure to make changes to only the specified drive:
ignoredisk --only-use=nvme0n1

# Delete all partitions from the specified drive and re-create them below:
clearpart  --drives=nvme0n1 --all

# 'zerombr' is required when performing an unattended installation on a system with previously initialized disks:
zerombr

# Initialization of bootloader:
bootloader --location="mbr" --boot-drive=nvme0n1 --iscrypted --timeout=4 --password="grub.pbkdf2.sha512.10000.78B751A071DF90DE820C20DAAFCFD02A.200C4FA88A65CDA050CF85DCE19EC64ED40B8AC148C311119659779AD700896DAC1D487B66D2C048164F4404DD0C9D7B53A0C129E148DAE294DCA34B23D49323"

# -----------------------------------------------------------------------------

# NOTE: The --size parameter is minimum partition size in MiB,
#       and the --grow will expand the last partition to the end of the disk...

# 1) /boot/efi - needed for UEFI-enabled hardware
part /boot/efi                --fstype="efi"   --size=1024

# NOTE: The usage of BTRFS for /boot will cause an error during the installation,
#       and the system will become unbootable - because of BZ#1954149. This can
#       be fixed after the installation is complete via the Fedora LiveDVD:
#       * fix the UUID= of the /boot partition in the /etc/fstab
#       * setting up a chroot to the installed Fedora & regenerating GRUB2
#         - see: https://gist.github.com/Tamal/73e65bfb0e883e438310c5fe81c5de14

# 2) /boot (as subvolume allows easier snapshoting with snapper):
part  btrfs.boot              --fstype="btrfs" --size=3072
btrfs none                    --label=boot                      btrfs.boot
btrfs /boot                   --subvol --name=boot              LABEL=boot

# NOTE: So far anaconda does not support passing encrypted passphrase to LUKS.
#       Therefore we are using 'initialsetup' plaintext password, and it is
#       expected from the end-user to update the encryption password after the
#       installation... This is more convenient than encrypting after install.

# 3) Rest of the system - BTRFS:
part  btrfs.system            --fstype="btrfs" --grow --encrypted --luks-version=luks2 --passphrase="initialsetup"
btrfs none                    --label=fedora                    btrfs.system

btrfs /                       --subvol --name=@                 LABEL=fedora
btrfs /opt                    --subvol --name=opt               LABEL=fedora
btrfs /srv                    --subvol --name=srv               LABEL=fedora

btrfs /usr/local              --subvol --name=usr.local         LABEL=fedora
btrfs /var/cache              --subvol --name=var.cache         LABEL=fedora
btrfs /var/crash              --subvol --name=var.crash         LABEL=fedora
btrfs /var/lib/libvirt/images --subvol --name=var.libvirt       LABEL=fedora
btrfs /var/log                --subvol --name=var.log           LABEL=fedora
btrfs /var/opt                --subvol --name=var.opt           LABEL=fedora
btrfs /var/spool              --subvol --name=var.spool         LABEL=fedora
btrfs /var                    --subvol --name=var               LABEL=fedora
btrfs /var/tmp                --subvol --name=var.tmp           LABEL=fedora

btrfs /tmp                    --subvol --name=tmp               LABEL=fedora
btrfs /.swap                  --subvol --name=.swap             LABEL=fedora

# NOTE: The /root folder subvolume is still not supported by anaconda.
#btrfs /root                   --subvol --name=root              LABEL=fedora
btrfs /home/deekej            --subvol --name=deekej            LABEL=fedora

btrfs /home/deekej/dejadup    --subvol --name=deekej.dejadup    LABEL=fedora
btrfs /home/deekej/.cache     --subvol --name=deekej.cache      LABEL=fedora
btrfs /home/deekej/.ccache    --subvol --name=deekej.ccache     LABEL=fedora
btrfs /home/deekej/Downloads  --subvol --name=deekej.downloads  LABEL=fedora
btrfs /home/deekej/build      --subvol --name=deekej.build      LABEL=fedora

btrfs /home/deekej/Dropbox    --subvol --name=deekej.dropbox    LABEL=fedora
btrfs /home/deekej/Music      --subvol --name=deekej.music      LABEL=fedora
btrfs /home/deekej/devel      --subvol --name=deekej.devel      LABEL=fedora
btrfs /home/deekej/Documents  --subvol --name=deekej.documents  LABEL=fedora
btrfs /home/deekej/Pictures   --subvol --name=deekej.pictures   LABEL=fedora
btrfs /home/deekej/Videos     --subvol --name=deekej.videos     LABEL=fedora

# =============================================================================

# Initial packages to be automatically installed / removed:
%packages

# Package groups needed for the Fedora Workstation-like setup:
@anaconda-tools
@base-x
@critical-path-base
@critical-path-gnome
@core
@firefox
@fonts
@gnome-desktop
@hardware-support
@java
@multimedia
@networkmanager-submodules
@printing
@standard
@workstation-product
@x86-baremetal-tools

# Additional groups needed for my day-to-day work, etc.
@admin-tools
@buildsys-build
@c-development --optional
@container-management
@development-libs
@fedora-packager --nodefaults
@vagrant
@virtualization

# Packages to be removed from the installed package groups:
-cheese
-cvs
-fedora-bookmarks
-frei0r-plugins
-gavl
-gedit
-gnome-video-effects
-kdelibs
-libnatpmp
-libxfce4ui
-libxfce4util
-parole
-rhythmbox
-thunderbird
-totem
-transmission
-transmission-cli
-transmission-common
-transmission-gtk
-wine
-xfconf
-cheese
-cvs
-fedora-bookmarks
-frei0r-plugins
-gavl
-gedit
-gnome-video-effects
-kdelibs
-libnatpmp
-libxfce4ui
-libxfce4util
-parole
-rhythmbox
-thunderbird
-totem
-transmission
-transmission-cli
-transmission-common
-transmission-gtk
-wine
-xfconf

# Additional packages needed for unattended initial setup:
git
snapper
ansible
etckeeper
perl-version
systemd-container

# Additional packages needed for manual recovery after installation if needed:
vim
terminator
%end
