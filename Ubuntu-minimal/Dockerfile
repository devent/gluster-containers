FROM gcr.io/google_containers/ubuntu-slim:0.14

MAINTAINER Jose A. Rivera <jarrpa@redhat.com>

LABEL architecture="x86_64" \
      name="gluster-ubuntu-minimal" \
      version="3.12" \
      vendor="Red Hat, Inc" \
      summary="GlusterFS service (Ubuntu Slim + Gluster 3.12)" \
      io.k8s.display-name="GlusteriFS 3.12 on Ubuntu Slim" \
      io.k8s.description="The gluster-ubuntu-minimal image is an image running GlusterFS, a distributed and scalable network filesystem. Using common, off-the-shelf hardware you can create large, distributed storage solutions for media streaming, data analysis, and other data- and bandwidth-intensive tasks." \
      description="The gluster-ubuntu-minimal image is an image running GlusterFS, a distributed and scalable network filesystem. Using common, off-the-shelf hardware you can create large, distributed storage solutions for media streaming, data analysis, and other data- and bandwidth-intensive tasks." \
      io.openshift.tags="gluster,glusterfs,gluster-ubuntu"

ENV container docker

COPY gluster-setup.sh systemctl-mock.sh /

RUN echo "deb http://ppa.launchpad.net/gluster/glusterfs-3.12/ubuntu xenial main\ndeb-src http://ppa.launchpad.net/gluster/glusterfs-3.12/ubuntu xenial main" > /etc/apt/sources.list.d/gluster.list && \
    apt-get -y update && \
    apt-get -y --allow-unauthenticated install glusterfs-server lvm2 thin-provisioning-tools procps xfsprogs && apt-get -y autoremove && apt-get -y clean && \
    gunzip /usr/share/copyrights.tar.gz && tar -rf /usr/share/copyrights.tar /usr/share/doc/*/copyright && gzip /usr/share/copyrights.tar && \
    rm -rf \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/info \
        /usr/share/locale \
        /var/lib/apt/lists/* \
        /var/log/* \
        /var/cache/debconf/* \
        /usr/share/common-licenses* \
        ~/.bashrc \
        /etc/systemd \
        /lib/lsb \
        /lib/udev \
        /usr/lib/x86_64-linux-gnu/gconv/IBM* \
        /usr/lib/x86_64-linux-gnu/gconv/EBC* && \
    mkdir -p /usr/share/man/man1 /usr/share/man/man2 \
        /usr/share/man/man3 /usr/share/man/man4 \
        /usr/share/man/man5 /usr/share/man/man6 \
        /usr/share/man/man7 /usr/share/man/man8 && \
    mkdir -p /etc/glusterfs_bkp /var/lib/glusterd_bkp /var/log/glusterfs_bkp && \
    cp -r /etc/glusterfs/* /etc/glusterfs_bkp && \
    cp -r /var/lib/glusterd/* /var/lib/glusterd_bkp && \
    mv /gluster-setup.sh /usr/sbin/gluster-setup.sh && mv /systemctl-mock.sh /bin/systemctl && \
    chmod 500 /usr/sbin/gluster-setup.sh && chmod 655 /bin/systemctl && \
    sed -i.save -e "s#udev_sync = 1#udev_sync = 0#" -e "s#udev_rules = 1#udev_rules = 0#" -e "s#use_lvmetad = 1#use_lvmetad = 0#" /etc/lvm/lvm.conf

VOLUME [ "/sys/fs/cgroup" ]

EXPOSE 111 24007 49152 49153 49154 49156 49157 49158 49159 49160 49161 49162 49163

CMD ["/usr/sbin/gluster-setup.sh"]

