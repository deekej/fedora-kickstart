# vim: filetype=bash
#
# ----------------------------------------
# Dee'Kej's custom Anaconda Kickstart file
# ----------------------------------------
# Variables that needs to be replaced in the kickstart file before it can be used:
# * ${HOSTNAME}                 - network hostname of the PC
# * ${NETWORK_DEV}              - network device name to be used for connecting to the Internet
# * ${DRIVE}                    - disk drive to be used for the installation of Fedora OS
#
# * ${GRUB2_PASSWD_HASH}        - hash of GRUB2 password to be used
# * ${LUKS2_PASSWD_PLAINTXT}    - plaintext LUKS2 disk encryption password to be used
# * ${INSTALL_SSH_PASSWD_HASH}  - hash of SSH password to be used for monitoring during installation
#
# * ${ROOT_PASSWD_HASH}         - hash of root password
# * ${USER_PASSWD_HASH}         - hash of default user password
#
# * ${USERNAME}                 - username of the default user to be used
# * ${FULL_NAME}                - display name of the default user to be used
# * ${USER_UID}                 - UID to be used for the default user
# * ${USER_GID}                 - GID to be used for the default user

# =============================================================================

# We include the Fedora Workstation Live DVD kickstart file to make sure
# everything is setup the same way we expect for Fedora. Then we just overwrite
# some of the options that doesn't suit us, etc...

#%include fedora-live-workstation.ks

# =============================================================================

# Use graphical install
graphical

# Do not stall the installation when unsupported harware is detected:
unsupported_hardware

# Start the rescue (RW) mode in case anything goes wrong:
rescue

# Reboot the system after successful installation:
reboot

# Use hard drive installation media:
#harddrive --dir=None --partition=/dev/mapper/live-base

# System language:
lang en_US.UTF-8

# Keyboard settings:
keyboard --xlayouts='cz' --vckeymap='cz' --switch='grp:win_space_toggle'

# Initial network information:
firewall --enabled --ssh
network --hostname=${HOSTNAME} --onboot=yes --bootproto=dhcp --ipv6=auto --device=${NETWORK_DEV} --activate

# System timezone:
timezone Europe/Prague --utc
timesource --ntp-pool=time.cloudflare.com --nts

# System services:
services --enabled="chronyd"

# Make sure to make changes to only the specified drive:
ignoredisk --only-use=${DRIVE}

# Delete all partitions from the specified drive and re-create them below:
clearpart --all --drives=${DRIVE}

# =============================================================================

# Disk partitioning:
# ------------------

bootloader --location="mbr" --boot-drive=${DRIVE} --iscrypted --password="${GRUB2_PASSWD_HASH}" --timeout=4

# NOTE: The --size= parameter is minimum partition size in MiB, and the --grow
#       will expand the last partition to the end of the disk...

# 1) BIOSBOOT
part biosboot                 --ondisk=${DRIVE} --fstype="biosboot" --start=2048 --size=1

# 2) /boot/efi
part /boot/efi                --ondisk=${DRIVE} --fstype="efi" --size=1024 --fsoptions="umask=0077,shortname=winnt,noatime"

# 3) /boot
part  btrfs.01                --ondisk=${DRIVE} --fstype="btrfs" --size=3072
btrfs /boot                   --subvol --name=boot              LABEL=fedora

# 4) The rest of the system:
part  btrfs.02                --ondisk=${DRIVE} --fstype="btrfs" --grow --encrypted --luks-version=luks2 --passphrase="${LUKS2_PASSWD_PLAINTXT}"

btrfs none                    --label=fedora btrfs.01 btrfs.02

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

btrfs /root                   --subvol --name=root              LABEL=fedora
btrfs /home/deekej            --subvol --name=deekej            LABEL=fedora

# NOTE: The folders in /.pcloud will be bind-mounted into their correct locations
#       in the /home/deekej folder. This is just a workaround for full userdir
#       sync between machines via the pCloud app...
btrfs /.pcloud/dejadup        --subvol --name=deekej.dejadup    LABEL=fedora
btrfs /home/deekej/.cache     --subvol --name=deekej.cache      LABEL=fedora
btrfs /home/deekej/.ccache    --subvol --name=deekej.ccache     LABEL=fedora
btrfs /home/deekej/Downloads  --subvol --name=deekej.downloads  LABEL=fedora
btrfs /home/deekej/build      --subvol --name=deekej.build      LABEL=fedora

btrfs /.pcloud/Dropbox        --subvol --name=deekej.dropbox    LABEL=fedora
btrfs /.pcloud/Music          --subvol --name=deekej.music      LABEL=fedora
btrfs /home/deekej/devel      --subvol --name=deekej.devel      LABEL=fedora
btrfs /home/deekej/Documents  --subvol --name=deekej.documents  LABEL=fedora
btrfs /home/deekej/Pictures   --subvol --name=deekej.pictures   LABEL=fedora
btrfs /home/deekej/Videos     --subvol --name=deekej.videos     LABEL=fedora

# =============================================================================

# Users configuration:
# --------------------

%anaconda
pwpolicy root --minlen=10 --minquality=65    --strict --notempty --nochanges
pwpolicy user --minlen=10 --minquality=65 --notstrict --notempty --nochanges
pwpolicy luks --minlen=10 --minquality=70 --notstrict --notempty --nochanges
%end

# Additional groups:
group --name=wheel --gid=10
group --name=mock  --gid=135

# Root password:
rootpw --iscrypted "${ROOT_PASSWD_HASH}" --lock

# Auxiliary user for initial set up (to be deleted once finished):
user --name="setup" --gecos="Initial Setup User" --groups=wheel --uid=1000 --gid=1000 --iscrypted --password="${USER_PASSWD_HASH}"

# Additional users:
user --name="${USERNAME}" --gecos="${FULL_NAME}" --groups=wheel,mock --uid=${USER_UID} --gid=${USER_GID} --iscrypted --password="${USER_PASSWD_HASH}"

# Add initial SSH keys into authorized_keys so we can manage the machine with
# Ansible after the installation:
sshkey --username='setup' "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCbBIim2vhMlqFDOPJrar32XIn/C018qLuR7rYw+UlewmMxIlfYxyD6wjfOa/9F4xDx+CAiAvC71liAVqyLwl4s0I9gz61m8YlFUI1vZxlLf/ug8G+lhqLXpVxdVeWctp+bO5LszR4uACC4nW7/bgK3VuexuikWUsD5fBMiMOu7S3s7X9W+N4Z9gptYAygKPOblpT0Qqifwrt+7t9Re0pk40Cq9y5Ytkkyb27Jq6w1KsxvC58yD0d069Bm5NGFRvawgLSNelnduwG806H58xnCE5jX7noAvGitRQ7ldZCf4vKNu+RAxw82Sd/gKAPHj6CFlWX4lnY/m91FBkDG/9d/Ll3nUv5sDMjmFhRJTW1py5Wo7Ep/+D0McSR88rld7Ea3Q1I7261SD8xus8kyH5K40hv1GmrBis7pLdMGisZW2P+mS6b3gTpuraCW419nqS1EayPtE0x17ojoaRxj3PBfzULhLYTGZ/R1yRfQ3AQssWXp6VaOV4QbuofcTyAyMVpfbI8DlXYaTSXYNsO+dnDOuSY9IPn1FzQDFkzwacCZ19cV2Z3WFY5VVAHnhzOjf4dO2qpVUknBGgcKlJLzE+CMQb+UeW740khMEuejodp7kxGx5dW6WKMm6v4I92D1eugELuOPIZ3aQYY2DvoqGL+E8d9fXIoblMFzhL1kDR2s0cw== [personal] automation"

# Disallow/allow accessing the installation from SSH as a root / setup user (respectively):
sshpw  --username=root --lock
sshpw  --username=setup --iscrypted "${INSTALL_SSH_PASSWD_HASH}"

# Do not run the Setup Agent on first boot (users are already configured):
firstboot --disable

# =============================================================================

# System configuration:
# ---------------------

# Enable SELinux:
selinux --enforcing

# Disable the kdump:
%addon com_redhat_kdump --reserve-mb=auto --disable
%end

# Initial packages to be automatically installed / removed:
%packages

git
snapper
ansible
etckeeper
perl-version

-cheese
-cvs
-frei0r-plugins
-gavl
-gedit
-gnome-terminal
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

%end
