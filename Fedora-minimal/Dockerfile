FROM fedora

MAINTAINER Jose A. Rivera <jarrpa@redhat.com>

LABEL architecture="x86_64" \
      name="gluster-fedora-minimal" \
      version="3.10" \
      vendor="Red Hat, Inc" \
      summary="GlusterFS service (Fedora + Gluster 3.10)" \
      io.k8s.display-name="GlusterFS 3.10 on Fedora" \
      io.k8s.description="The gluster-fedora-minimal image is an image running GlusterFS, a distributed and scalable network filesystem. Using common, off-the-shelf hardware you can create large, distributed storage solutions for media streaming, data analysis, and other data- and bandwidth-intensive tasks." \
      description="The gluster-fedora-minimal image is an image running GlusterFS, a distributed and scalable network filesystem. Using common, off-the-shelf hardware you can create large, distributed storage solutions for media streaming, data analysis, and other data- and bandwidth-intensive tasks." \
      io.openshift.tags="gluster,glusterfs,gluster-fedora"

ENV container docker

COPY gluster-setup.sh systemctl-mock.sh /

RUN dnf --setopt=tsflags=nodocs -y upgrade && \
    dnf --setopt=tsflags=nodocs -y install glusterfs glusterfs-server glusterfs-geo-replication procps-ng xfsprogs && \
    dnf clean all && \
    mkdir -p /etc/glusterfs_bkp /var/lib/glusterd_bkp /var/log/glusterfs_bkp && \
    cp -r /etc/glusterfs/* /etc/glusterfs_bkp && \
    cp -r /var/lib/glusterd/* /var/lib/glusterd_bkp && \
    sed -i.save -e "s#udev_sync = 1#udev_sync = 0#" -e "s#udev_rules = 1#udev_rules = 0#" -e "s#use_lvmetad = 1#use_lvmetad = 0#" /etc/lvm/lvm.conf && \
    mv /gluster-setup.sh /usr/sbin/gluster-setup.sh && mv /systemctl-mock.sh /bin/systemctl && \
    chmod 500 /usr/sbin/gluster-setup.sh && chmod 655 /bin/systemctl

VOLUME [ "/sys/fs/cgroup" ]

EXPOSE 111 24007 49152 49153 49154 49156 49157 49158 49159 49160 49161 49162 49163

CMD ["/usr/sbin/gluster-setup.sh"]

