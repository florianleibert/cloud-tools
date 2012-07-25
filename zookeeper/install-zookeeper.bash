#!/bin/bash
set -o errexit -o nounset -o pipefail

source /etc/environment

v=3.3.4
repo=http://apache.mirrors.lucidnetworks.net/zookeeper/
d="zookeeper-$v"

root_dir=/srv
dir="$root_dir"/zookeeper
versioned_dir="$root_dir"/"$d"
data_dir="$versioned_dir"/data
service_dir="$versioned_dir"/service

function install {
  rm -fr "$versioned_dir"
  ( cd /tmp
    rm -fr $dir
    rm -fr $data_dir
    curl -O -L "$repo/$d/$d.tar.gz"
    tar xzf "$d.tar.gz"
    mv "$d" "$root_dir"
    ln -s "$versioned_dir" "$dir"
    mkdir -p $data_dir
    ( cd $dir
      mkdir -p "$data_dir"
      chown -R nobody:nogroup "$dir"
      chmod g+rwsX "$data_dir"
      mkdir -p "$data_dir"/txlog
      # This sets the id of this zk instance
      echo $zk > "$data_dir"/myid
    )
    # Add runit directories for custom configurations
    git clone https://github.com/florianleibert/cloud-tools
    rsync -av ./cloud-tools/zookeeper/ "$versioned_dir"
  )
}

function initialize_service {
  # If an environment variable called "start" is set, start the service.
  if [ -n "${start+set}" ]
  then
    echo
    echo -e "\033[32m*** Zookeeper is starting... ***\033[0m"
    rm -f /etc/service/zookeeper
    ln -sf /opt/zookeeper/service/zookeeper /etc/service/zookeeper
    #Give it enough time for runit to find it
    sleep 10
    sv -v u zookeeper 2> /dev/null || echo -e "\033[31m*** Unable to start Zookeeper. ***\033[0m"
  fi
}

function all {
  #shut down zookeeper if it's running, but don't worry if it's not
  sv -v d zookeeper 2> /dev/null || echo
  install
  initialize_service
}

if [[ $# -eq 0 ]]
then
  all
else
  "$@"
fi