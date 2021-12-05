#!/bin/bash

#!/usr/bin/env bash

# Copyright 2018 The KubeSphere Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CurrentDIR=$(cd "$(dirname "$0")" || exit;pwd)

func() {
    echo "Usage:"
    echo
    echo "./uninstall.sh [FLAG]"
    echo
    echo "Description:"
    echo "  -a                     : Delete AllinOne Cluster"
    echo "  -m                     : Delete MultiNodes Cluster"
    echo "  -h                     : usage message"
    exit
}


allinone="false"
multinodes="false"

while getopts 'amh' OPT; do
    case $OPT in
        a) allinone="true";;
        m) multinodes="true";;
        h) func;;
        ?) func;;
        *) func;;
    esac
done

if [[ $1 == "" ]]; then
   func
fi

function confirm_delete_cluster () {
    read -p "Are you sure to delete this cluster? [yes/no]: " ans
    while [[ "x"$ans != "xyes" && "x"$ans != "xno" ]]; do
        read -p "Are you sure to delete this cluster? [yes/no]: " ans
    done

    if [[ "x"$ans == "xno" ]]; then
        exit
    fi
}

if [[ ${allinone} == "true" ]]; then
  confirm_delete_cluster
  ${CurrentDIR}/bin/kk pre-uninstall
  ${CurrentDIR}/bin/kk delete cluster -y
  rm -rf /var/lib/csi-hostpath-data
fi

if [[ ${multinodes} == "true" ]]; then
  confirm_delete_cluster
  ${CurrentDIR}/bin/kk pre-uninstall -f ${CurrentDIR}/config-sample.yaml
  ${CurrentDIR}/bin/kk delete cluster -f ${CurrentDIR}/config-sample.yaml -y
fi
