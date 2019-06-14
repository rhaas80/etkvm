#!/bin/sh

# finish setup inside of started system
cp /cdrom/postseed /target/etc/init.d/
chroot /target update-rc.d postseed defaults

# installing packages from backports is tricky since its deps are not
# automatically pulled from backports when one uses preseed
#chroot /target apt-get install -y -t jessie-backports jupyter-notebook python-notebook

# enable file sharing to windows clients, disable passwords
sed -i '/^\[homes\]/{:loop;n;/^ *read only *=/s/yes/no/;s/^ *valid users/   public = yes\n;&/;/^\[/!b loop}' /target/etc/samba/smb.conf
# prepare for host-only network
echo -e 'auto eth1\niface eth1 inet dhcp' >>/target/etc/network/interfaces

# prepare to make enlarging the partition possible
# we need to remove the dummy partition we created to make partman happy
# there must a be reboot between this and an attempt to resize the FS
sed -i '/delme/d' /target/etc/fstab
umount /dev/sda2
rmdir /target/home/et/delme

chroot /target /bin/bash <<"EOF"
/sbin/sfdisk /dev/sda --dump | \
awk '/sda1/{start=$4;size=$6} /sda2/{$1="/dev/sda1";$4=start;$6=($6+size)",";print} {next}' | \
/sbin/sfdisk --force /dev/sda
EOF

# don't ask for passwd for et user to become root
sed -i '/^%sudo/s!ALL$!NOPASSWD: ALL!' /target/etc/sudoers

# Boot into et user desktop (and stay there)
sed -i 's!NODM_ENABLED=false!NODM_ENABLED=true!;s!NODM_USER=root!NODM_USER=et!' /target/etc/default/nodm

# set up user $HOME directory
for i in /cdrom/*.tar ; do
  tar -xf $i -C /target/home/et/
done

chroot /target chown -R et:et /home/et
