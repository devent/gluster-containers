FROM fedora

MAINTAINER Humble Chirammal <hchiramm@redhat.com> ; Mohamed Ashiq <mliyazud@redhat.com>

LABEL architecture="x86_64"
LABEL com.redhat.component="rhgs-server-docker"
LABEL name="gluster/gluster-fedora"
LABEL version="3.3.0"
LABEL vendor="Red Hat, Inc"
LABEL summary="This image has a running glusterfs service (Fedora 23 + GlusterFS 3.10)"
LABEL io.k8s.display-name="GlusterFS 3.10 on Fedora 26"
LABEL io.k8s.description="GlusterFS is a software-only, scale-out storage solution that provides flexible and agile unstructured data storage."
LABEL description="GlusterFS is a software-only, scale-out storage solution that provides flexible and agile unstructured data storage."
LABEL io.openshift.tags="gluster,glusterfs,gluster-fedora"

ENV container docker

VOLUME [ "/sys/fs/cgroup/" ]

ADD gluster-setup.sh /usr/sbin/gluster-setup.sh
ADD gluster-brickmultiplex.service /etc/systemd/system/gluster-brickmultiplex.service
ADD gluster-brickmultiplex.sh /usr/sbin/gluster-brickmultiplex.sh
ADD gluster-setup.service /etc/systemd/system/gluster-setup.service

RUN dnf --nogpgcheck -y update && \
sed -i "s/LANG/\#LANG/g" /etc/locale.conf && \
dnf --setopt=tsflags=nodocs -y install 'dnf-command(copr)' && dnf -y copr enable jarrpa/gluster-block && \
dnf -y install --nogpgcheck systemd-udev ntp glusterfs-server gluster-block target-restore dbus-python nfs-utils attr iputils iproute glusterfs-geo-replication openssh-server openssh-clients cronie tar rsync sos sudo xfsprogs && \
dnf clean all && \
sed -i '/Port 22/c\Port 2222' /etc/ssh/sshd_config && \
sed -i 's/Requires\=rpcbind\.service//g' /usr/lib/systemd/system/glusterd.service && \
sed -i 's/rpcbind\.service/gluster-setup\.service/g' /usr/lib/systemd/system/glusterd.service && \
sed -i 's/rpcbind\.service//g' /usr/lib/systemd/system/gluster-blockd.service && \
sed -i.save -e "s#udev_sync = 1#udev_sync = 0#" -e "s#udev_rules = 1#udev_rules = 0#" -e "s#use_lvmetad = 1#use_lvmetad = 0#" /etc/lvm/lvm.conf && \
mkdir -p /etc/glusterfs_bkp /var/lib/glusterd_bkp /var/log/glusterfs_bkp && \
cp -r /etc/glusterfs/* /etc/glusterfs_bkp && \
cp -r /var/lib/glusterd/* /var/lib/glusterd_bkp && \
cp -r /var/log/glusterfs/* /var/log/glusterfs_bkp && \
chmod 644 /etc/systemd/system/gluster-setup.service && \
chmod 500 /usr/sbin/gluster-setup.sh && \
ln -s /usr/sbin/gluster-setup.sh /usr/sbin/setup.sh && \
chmod 644 /etc/systemd/system/gluster-brickmultiplex.service && \
chmod 500 /usr/sbin/gluster-brickmultiplex.sh && \
systemctl mask getty.target && \
systemctl disable systemd-udev-trigger.service && \
systemctl disable systemd-udevd.service && \
systemctl disable nfs-server.service && \
systemctl enable rpcbind.service && \
systemctl enable sshd.service && \
systemctl enable ntpd.service && \
systemctl enable gluster-setup.service && \
systemctl enable gluster-block-target.service && \
systemctl enable gluster-blockd.service && \
systemctl enable gluster-brickmultiplex.service && \
systemctl enable glusterd.service


EXPOSE 2222 111 245 443 24006 24007 2049 8080 6010 6011 6012 38465 38466 38468 38469 49152 49153 49154 49156 49157 49158 49159 49160 49161 49162

CMD ["/usr/sbin/init"]
