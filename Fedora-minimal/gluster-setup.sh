#!/bin/bash

###
# Description: Script to move the glusterfs initial setup to bind mounted directories of Atomic Host.
# Copyright (c) 2016 Red Hat, Inc. <http://www.redhat.com>
#
# This file is part of GlusterFS.
#
# This file is licensed to you under your choice of the GNU Lesser
# General Public License, version 3 or any later version (LGPLv3 or
# later), or the GNU General Public License, version 2 (GPLv2), in all
# cases as published by the Free Software Foundation.
###

GLUSTERFS_CONF_DIR="/etc/glusterfs"
GLUSTERFS_LOG_DIR="/var/log/glusterfs"
GLUSTERFS_META_DIR="/var/lib/glusterd"
GLUSTERFS_LOG_CONT_DIR="${GLUSTERFS_LOG_DIR}/container"
GLUSTERFS_CUSTOM_FSTAB="/var/lib/heketi/fstab"

: "${GLUSTER_BRICKMULTIPLEX:=yes}"
: "${GLUSTERFS_LOG_LEVEL:=INFO}"
: "${GB_LOGDIR:="${GLUSTERFS_LOG_DIR}/gluster-block"}"
export GB_LODGIR

mkdir -p $GLUSTERFS_LOG_CONT_DIR $GB_LOGDIR

setup() {
  for i in $GLUSTERFS_CONF_DIR $GLUSTERFS_META_DIR
  do
    if ! test "$(ls $i)"
    then
          bkp=$i"_bkp"
          cp -r $bkp/* $i
          if [ $? -eq 1 ]
          then
                echo "Failed to copy $i"
                exit 1
          fi
          ls -R $i > ${GLUSTERFS_LOG_CONT_DIR}/${i//\//_}_ls
    fi
  done

  if [ -s "$GLUSTERFS_CUSTOM_FSTAB" ]; then
        touch $GLUSTERFS_LOG_CONT_DIR/brickattr
        touch $GLUSTERFS_LOG_CONT_DIR/failed_bricks

        sleep 5

        pvscan | tee $GLUSTERFS_LOG_CONT_DIR/pvscan
        vgscan | tee $GLUSTERFS_LOG_CONT_DIR/vgscan
        lvscan | tee $GLUSTERFS_LOG_CONT_DIR/lvscan
        mount -a --fstab $GLUSTERFS_CUSTOM_FSTAB | tee $GLUSTERFS_LOG_CONT_DIR/mountfstab
        if [ $? -eq 1 ]; then
              echo "mount binary not failed" | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
              exit 1
        fi
        echo "Mount command Successful" | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
        sleep 40
        cut -f 2 -d " " $GLUSTERFS_CUSTOM_FSTAB | while read line; do
              if grep -qs "$line" /proc/mounts; then
                   echo "$line mounted." | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
                   if test "ls $line/brick"
                   then
                         echo "$line/brick is present" | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
                         getfattr -d -m . -e hex $line/brick | tee -a $GLUSTERFS_LOG_CONT_DIR/brickattr
                   else
                         echo "$line/brick is not present" | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
                         sleep 1
                   fi
              else
                   grep $line $GLUSTERFS_CUSTOM_FSTAB | tee -a $GLUSTERFS_LOG_CONT_DIR/failed_bricks
                   echo "$line not mounted." | tee -a $GLUSTERFS_LOG_CONT_DIR/mountfstab
                   sleep 0.5
             fi
        done
        if [ $(wc -l $GLUSTERFS_LOG_CONT_DIR/failed_bricks | awk '{print $1}') -gt 1 ]
        then
              vgscan --mknodes | tee $GLUSTERFS_LOG_CONT_DIR/vgscan_mknodes
              sleep 10
              mount -a --fstab $GLUSTERFS_LOG_CONT_DIR/failed_bricks
        fi
  fi
}

destroy() {
  echo -n "Killing processes ... "
  pids=$(pidof gluster-blockd; pidof tcmu-runner; pidof glusterd; pidof rpcbind; jobs -p)
  for pid in $pids; do
    kill $pid 2>/dev/null
    wait $pid 2>/dev/null
  done
  echo "OK"
  exit 1
}

run_glusterd() {
  local rc=1
  local s=0
  local pid=""
  local cmd=( /usr/sbin/glusterd -p /var/run/glusterd.pid --log-level "$GLUSTERFS_LOG_LEVEL" )

  echo -n "Starting glusterd ... "
  ${cmd[*]}

  rc=1
  s=0
  while [ $rc -ne 0 ] && [ $s -lt 30 ]; do
    ((s+=1))
    sleep 1
    gluster v info 1>/dev/null 2>&1
    rc=$?
  done

  if [ $rc -ne 0 ]; then
    echo "FAIL"
    echo "Timeout waiting for glusterd"
    exit 1
  fi

  echo "OK"
  return 0
}

start_glusterd() {
  local mp_opt=""

  run_glusterd

  case "$GLUSTER_BRICKMULTIPLEX" in
    [nN] | [nN][Oo] | [oO][fF][fF] )
      mp_opt="off"
      ;;
    [yY] | [yY][Ee][Ss] | [oO][nN] )
      mp_opt="on"
      ;;
    *) echo "Invalid value '$GLUSTER_BRICKMULTIPLEX' for GLUSTER_BRICKMULTIPLEX"
      ;;
  esac

  gluster --mode=script volume set all cluster.brick-multiplex "$mp_opt" 2>&1 || echo "Enabling brick multiplexing failed"
  gluster --mode=script volume set all cluster.max-bricks-per-process 20 2>&1 || echo "Setting max bricks per process failed"
#  gluster --mode=script volume set all nfs.disable on 2>&1 || echo "Disabling NFS failed"
#  gluster --mode=script volume set all user.smb disable 2>&1 || echo "Disabling SMB failed"

  echo "Killing glusterd ... "
  rc=1
  s=0
  pid="$(pidof glusterd)"
  kill "$pid" 2>&1 1>/dev/null
  while [[ "x$pid" != "x" ]]; do
    if [[ $s -ge 30 ]]; then
      kill -9 "$pid" 2>&1 1>/dev/null
    fi
    ((s+=1))
    sleep 1
    pid="$(pidof glusterd)"
  done
  echo "OK"

  run_glusterd
}

trap destroy EXIT

mount -t configfs configfs /sys/kernel/config

# start rpcbind if it is not started yet
/usr/sbin/rpcinfo 127.0.0.1 >/dev/null 2>&1
if [ $? -ne 0 ]; then
  /usr/sbin/rpcbind -w || exit 1
fi

mkdir -p /run/dbus
/usr/bin/dbus-daemon --system --nofork --nopidfile --nosyslog 2>&1 | while read -r line; do echo "[dbus-daemon...] $line"; done &

touch $GLUSTERFS_LOG_DIR/glusterd.log $GB_LOGDIR/tcmu-runner.log $GB_LOGDIR/gluster-blockd.log

tail -n 0 -f $GLUSTERFS_LOG_DIR/glusterd.log | while read -r line; do echo "[glusterd......] $line"; done &
tail -n 0 -f $GB_LOGDIR/tcmu-runner.log | while read -r line; do echo "[tcmu-runner...] $line"; done &
tail -n 0 -f $GB_LOGDIR/gluster-blockd.log | while read -r line; do echo "[gluster-blockd] $line"; done &

setup 2>&1 | while read -r line; do echo "[setup.........] $line"; done

start_glusterd 2>&1 | tee -a $GLUSTERFS_LOG_CONT_DIR/start_glusterd | while read -r line; do echo "[glusterd......] $line"; done

/usr/bin/tcmu-runner "--tcmu-log-dir=$GB_LOGDIR" --debug 1>/dev/null 2>&1 | while read -r line; do echo "[tcmu-runner...] $line"; done &

/usr/bin/targetctl restore 2>&1 | while read -r line; do echo "[targetctl.....] $line"; done &

/usr/sbin/gluster-blockd --glfs-lru-count "${GB_GLFS_LRU_COUNT:=5}" --log-level $GLUSTERFS_LOG_LEVEL 1>/dev/null 2>&1 &

rc=0
while [ $rc -eq 0 ]; do
  sleep 1
  for svc in glusterd tcmu-runner gluster-blockd; do
    # If service is not running $pid will be null
    pid=$(pidof $svc)
    if [ -z "$pid" ]; then
      echo "$svc has failed"
      rc=1
    fi
  done
done

echo "Exiting"
exit 1
