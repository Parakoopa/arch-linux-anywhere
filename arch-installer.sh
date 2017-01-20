#!/bin/bash

set -e

UEFI=false
encrypt=false
encrypt_fde=false

ec() {
        echo -e "\033[0;32m$1\033[m"
}

main() {
        ec '
                                   MMMMMMMMMM  MMMM                             
                               7MM  MMMMMMMMM  MMMMM~                           
                            ~MMMMM  MMMMMMMMM       +MMMMM                      
                           MMMMMMMM  MMMMM     MMMMMMMMMMMMMMMMMMMMMMMN         
                        M  MMMMMMMM  ~M   +MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     
                       MM  MMMMMMM     MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN   
                     MMMM$  MMMMM   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  
                   MMMMM8         MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM8              
                   MMM   +MMMM~   MMMMMMMMMMMMMMMMMMMMMMMMMMM        MMMMMMMM   
               NM      MMMMMMMM:  MMMM  MM MMMMMMMMMMMMMM=     MMMMMMMMMMM      
              MMMMM  MMMMMMMMMMM  MMMM      MMMMMMMMMMM    MMMMMMMMMMMO         
            7MMMMMM  MMMMMMMMMMM  MMMM     MMMMMMMMMM,  ,MMMMMMMMMMM            
             MMMMM  MMMMMMMMMMMM  MMMMMMMMMMMMMMMMM   MMMMMMMMMMMN              
          MM        ,MMMMMMM7       MMMMMMMMMMMMMN   MMMMMMMMMMM                
          MMMM   MMM          +MMM        ?MMMMM   MMMMMMMMMMMMM                
         MMMMM  MMMM  MMMM  MMMMMM  MMMMMM   MMMMMMMMMMMMMMMMMMM                
         MMMM  MMMM ,MMMMM  MMMMMMM  MMMMM7  MMMMMMMMMMMMMMMMMM                 
              MMMM  MMMMMM  MMMMMMM          MMMMMMMMMMMMMMMMMM                 
     MMMMMMMN                        M  +MMM MMMMMMMMMMMMMMMMM                  
    MMMMMMMMM  MMMMMM  MMMMMMMMM  MMMMM  MMM MMMMMMMMMMMMMMMM                   
        $MMMM  MMMMMM  MMMMMMMMM  MMMMMM  MM  MMMMMMMMMMMMMM$                   
   7MMM+            $  MMMMMMMMM  MMMMMM      MMMMMMMMMMMMMM                    
  MMMMMMMM= ?MMMO                             MMMMMMMMMMMMM                     
MMMMMMMMMMM  MMMMMMM  OMMMMM       MM  MMMMMM  MMMMMMMMMMMM                     
MMMMMMMMMMM  MMMMMMM  MMMMMM  MMMMMMM  MMMMM     MMMMMM                         
  MMMMMMMMM  MMMMMMM  MMMMMM  MMMMMMM                                           
   DMMMM      MMMMMN  MMMMMM? =MMMMMM                                           
                      MMMMMMM  M                                                
                                                                                '

        ec "Welcome to the automatic setup of Arch Kokako."
        ec ""
        ec "Load german keys? (yz/n)"
        read yn
        case "$yn" in
            z|Z|y|Y|yes|Yes|yY|Yy|yy|YY)
                loadkeys de
        esac

        ec "Do you want to partition using UEFI? (y/N)"
        read yn
        case "$yn" in
            y|Y|yes|Yes|yY|Yy|yy|YY)
                UEFI=true
        esac

        ec "Do you want encryption? (Y/n/f) [f = full disk encryption]"
        read yn
        case "$yn" in
			n|N|no|No|nN|Nn|nn|NN)
                ;;
            f|F)
                encrypt=true
                encrypt_fde=true
                ;;
            *)
                encrypt=true
        esac

        ec ""
        ec "Before we begin, we need you to partition your new harddrive."
        ec "Please partition your harddrive. You need..."
        if "$UEFI" ; then
            ec "   ... a UEFI Boot partition (/boot/efi) [512MB] [TYPE: EF]"
        fi
        ec "   ... a Boot partition (/boot) [100MB] [TYPE: 83]"
        ec "   ... a Main partition (Will be used via LVM) [TYPE: 8E]"
        ec ""
        ec "Do you want to continue? (y/N)"
        read yn

        case "$yn" in
            y|Y|yes|Yes|yY|Yy|yy|YY)
                partitionStart
            ;;
            *)
                ec "Installation aborted."
        esac
}

partitionStart() {
        reset
        lsblk
        ec ""
        ec "These are your block devices."
        ec "Please choose the block device you want to partition."
        ec "Do you need more details? (y/N)"
        read yn
        case "$yn" in
            y|Y|yes|Yes|yY|Yy|yy|YY)
                fdisk -l | less
            ;;
        esac
        ec "Plese enter which block device you want to partition."
        read blckDev
        ec "Starting fdisk for partitioning..."
        reset
        if "$UEFI" ; then
            ec "   ... a UEFI Boot partition (/boot/efi) [512MB] [TYPE: EF]"
        fi
        ec "   ... a Boot partition (/boot) [100MB] [TYPE: 83]"
        ec "   ... a Main partition (Will be used via LVM) [TYPE: 8E]"
        ec ""
        fdisk $blckDev

        ec "Do you want to partition more devices? (y/N)"
        read yn
        case "$yn" in
            y|Y|yes|Yes|yY|Yy|yy|YY)
                partitionStart
            ;;
            *)
                ec "Partitioning completed."
                partitionEnd
        esac
        
}

partitionEnd() {
        reset
        lsblk
        if "$UEFI" ; then
            ec ""
            ec "Which will be your /boot/efi partition?"
            read bootEfi
        fi
        ec ""
        ec "Which will be your /boot partition?"
        read boot
        ec ""
        ec "Which will be your main partition?"
        read main

        reset
        lsblk
        ec ""
        if "$UEFI" ; then
            ec "/boot/efi:  "$bootEfi
        fi
        ec "/boot:      "$boot
        ec "main:       "$main
        ec ""
        ec "Is this correct? (y/N)"
        read yn
        case "$yn" in
            y|Y|yes|Yes|yY|Yy|yy|YY)
                if "$UEFI" ; then
                    ec "Formatting /boot/efi as FAT32..."
                    mkfs.fat -F32 $bootEfi
                fi
                if "$encrypt"; then
                    if "$encrypt_fde"; then
                        # Boot unlocked by passphrase and both unlocked by keyfile in encrypted boot
                        ec "Generating keyfile"
                        dd bs=512 count=4 if=/dev/urandom of=/tmp/keyfile iflag=fullblock
                    fi
                    ec "Formatting main LUKS encrypted..."
                    cryptsetup luksFormat $main
                    if "$encrypt_fde"; then
                        cryptsetup luksAddKey $main /tmp/keyfile
                    fi
                    cryptsetup open --type luks $main lvm
                    lvmTarget="/dev/mapper/lvm"
                else
                    lvmTarget=$main
                fi
                ec "Configuring LVM volume..."
                pvcreate $lvmTarget
                vgcreate MainVol $lvmTarget
                ec "-> Size for swap in GB? (8 recommended)"
                read swapSize
                lvcreate -L "${swapSize}"G MainVol -n swap
                ec "-> Size for / in GB? (30 recommended)"
                read rootSize
                lvcreate -L "${rootSize}"G MainVol -n root
                ec "-> /home get's rest of space"
                lvcreate -l 100%FREE MainVol -n home
                ec "Formatting ${rootSize}GB / as EXT4"
                mkfs.ext4 /dev/mapper/MainVol-root
                ec "Formatting ${swapSize}GB swap as EXT4"
                mkswap /dev/mapper/MainVol-swap
                ec "Formatting /home as EXT4"
                mkfs.ext4 /dev/mapper/MainVol-home
                ec "Mounting..."
                mount /dev/mapper/MainVol-root /mnt
                mkdir /mnt/home
                mount /dev/mapper/MainVol-home /mnt/home
                swapon /dev/mapper/MainVol-swap

                bootTarget=$boot
                if "$encrypt"; then
                    if "$encrypt_fde"; then
                        ec "Configuring LUKS on /boot"
                        cryptsetup luksFormat $boot
                        cryptsetup luksAddKey $boot /tmp/keyfile
                        cryptsetup open $boot cryptboot
                        bootTarget=/dev/mapper/cryptboot
                    fi
                fi
                ec "Formatting /boot as EXT2"
                mkfs.ext2 $bootTarget
                ec "Mounting /boot and /boot/efi..."
                mkdir /mnt/boot
                mount $bootTarget /mnt/boot

                if "$encrypt"; then
                    if "$encrypt_fde"; then
                        cp /tmp/keyfile /mnt/crypto_keyfile.bin #Copy Keyfile
                        chmod 000 /mnt/crypto_keyfile.bin
                        rm /tmp/keyfile
                    fi
                fi

                if "$UEFI" ; then
                    mkdir /mnt/boot/efi
                    mount $bootEfi /mnt/boot/efi
                fi
                ec ""
                ec "Done!"
                ec ""
                ec "NEW BLOCK LIST:"                
                ec ""
                lsblk
                ec ""
                ec "You can now mount or format your own partitions. Type exit to continue."
                bash
                beginInstall
            ;;
            *)
                partitionEnd
            ;;
        esac
}

beginInstall() {        
        reset
        
        ec "What should the hostname of the new system be?"
        read newhost
        mkdir /mnt/etc
        echo $newhost > /mnt/etc/hostname

        ec "Fetching Mirrorlist..."
        fetchmirrors

        ec "Installing..."
        ec ""

        pacman -Sy archlinux-keyring --noconfirm
        pacstrap /mnt base base-devel wpa_supplicant
        
        fstab
}

fstab() {        
        ec "Configuring fstab and crypttab"
        if "$encrypt"; then
            if "$encrypt_fde"; then
                echo "cryptboot  $boot      /crypto_keyfile.bin       luks " >> /mnt/etc/crypttab
            fi
            echo "lvm        $main      none                      luks " >> /mnt/etc/crypttab
        fi
        genfstab -p /mnt > /mnt/etc/fstab

        ec "fstab generated... editing now possibly: (ENTER)"
        read tmp
        vim /mnt/etc/fstab
        
        basicAndCryptConfig
}

basicAndCryptConfig() {
        echo LANG=de_DE.UTF-8 > /mnt/etc/locale.conf
        echo LC_COLLATE=C >> /mnt/etc/locale.conf
        echo LANGUAGE=de_DE >> /mnt/etc/locale.conf

        echo KEYMAP=de > /mnt/etc/vconsole.conf
        rm /mnt/etc/localtime || true
        arch-chroot /mnt/ ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

        ## Own PPA
        echo "
[para-ppa]
Server = https://parakoopa.de/pkgs
SigLevel = Required TrustedOnly" >> /mnt/etc/pacman.conf

        arch-chroot /mnt/ pacman-key -r 1CDE33BB
        arch-chroot /mnt/ pacman-key --lsign-key 1CDE33BB

        sed -i 's!#de_DE.UTF-8 UTF-8!de_DE.UTF-8 UTF-8!' /mnt/etc/locale.gen
        sed -i 's!#de_DE ISO-8859-1!de_DE ISO-8859-1!' /mnt/etc/locale.gen
        sed -i 's!#de_DE@euro ISO-8859-15!de_DE@euro ISO-8859-15!' /mnt/etc/locale.gen
        
        arch-chroot /mnt/ locale-gen
        arch-chroot /mnt/ pacman -Sy
        ec ""
        ec "Please set the administrator password now."
        arch-chroot /mnt/ passwd

        arch-chroot /mnt/ pacman -S git openssh --noconfirm

        grubThemeAndPlymouth
}

grubThemeAndPlymouth() {
        # Install Plymouth and Themes
        arch-chroot /mnt/ pacman -S docbook-xsl pango ttf-dejavu plymouth-git --noconfirm
        cp -r /opt/kokako-plymouth /mnt/usr/share/plymouth/themes/kokako-plymouth
        arch-chroot /mnt/ plymouth-set-default-theme kokako-plymouth
        sed -i 's!base udev!base udev plymouth!' /mnt/etc/mkinitcpio.conf
        sed -i 's!MODULES="!MODULES="i915 !' /mnt/etc/mkinitcpio.conf
        
        # Install Grub Theme
        mkdir -p /mnt/boot/grub/themes
        cp -r /opt/kokako-grub/theme /mnt/boot/grub/themes/kokako-grub
        bootloaderAndKernel
}

bootloaderAndKernel() {
        if "$UEFI" ; then
            arch-chroot /mnt/ pacman -S grub efibootmgr --noconfirm
        else
            arch-chroot /mnt/ pacman -S grub --noconfirm
        fi
        
        mainUUID=$(blkid "$main" -ovalue -sUUID)


        if "$encrypt"; then
            if "$encrypt_fde"; then
                echo -e "\nGRUB_ENABLE_CRYPTODISK=y" >> /mnt/etc/default/grub
                echo -e '\nFILES="/crypto_keyfile.bin"' >> /mnt/etc/mkinitcpio.conf
            fi
            sed -i 's!quiet! quiet loglevel=3 rd.systemd.show_status=auto rd.udev.log-priority=3 splash cryptdevice=UUID='$mainUUID':lvm!' /mnt/etc/default/grub
            sed -i 's!block!plymouth-encrypt lvm2 block!' /mnt/etc/mkinitcpio.conf
        else
            sed -i 's!quiet! quiet loglevel=3 rd.systemd.show_status=auto rd.udev.log-priority=3 splash!' /mnt/etc/default/grub
            sed -i 's!block!lvm2 block!' /mnt/etc/mkinitcpio.conf
        fi
        echo -e '\nGRUB_THEME="/boot/grub/themes/kokako-grub/theme.txt"' >> /mnt/etc/default/grub

        arch-chroot /mnt/ grub-mkconfig -o /boot/grub/grub.cfg

        if "$UEFI" ; then
            arch-chroot /mnt/ grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=boot --recheck
            cp /mnt/boot/efi/EFI/boot/grubx64.efi /mnt/boot/efi/EFI/boot/bootx64.efi
        else
            ec "Which device should the bootloader be installed to?"
            read $bootloaderDevice
            arch-chroot /mnt/ grub-install $bootloaderDevice
        fi

        # Somehow this might not get created
        cp /etc/os-release /mnt/etc/os-release

        arch-chroot /mnt/ mkinitcpio -p linux

        saltstack
}

saltstack() {
        ec "Installing Saltstack and cloning repository..."

        # install saltstack and git
        arch-chroot /mnt/ pacman -S salt wget --noconfirm
        
        # copy ssh key
        cp -r ./.ssh /mnt/root/.ssh

        # clone saltsack configuration
        arch-chroot /mnt/ git clone gitolite@parakoopa.de:saltstack /srv/salt
        #arch-chroot /mnt/ git config --global user.email parakoopa@live.de
        #arch-chroot /mnt/ git config --global user.name Kokako installer
        # configure master-less minion setup
        rm /mnt/etc/salt/minion || true
        arch-chroot /mnt/ ln -s /srv/salt/config/minion /etc/salt/minion
        # DO NOT: arch-chroot /mnt/ systemctl enable salt-minion - @see https://docs.saltstack.com/en/latest/topics/tutorials/quickstart.html

        # copy and enable install systemd job
        cp /mnt/srv/salt/installer/saltstack-kokako-install.service /mnt/etc/systemd/system/saltstack-kokako-install.service
        arch-chroot /mnt/ systemctl disable getty@tty1.service
        arch-chroot /mnt/ systemctl enable saltstack-kokako-install

        doneAndReboot
}

doneAndReboot() {
        reset
        ec "DONE! Rebooting in 10 seconds. CTRL+C to abort. - Installation will continue after reboot."
        sleep 10
        reboot
        exit
}

main
