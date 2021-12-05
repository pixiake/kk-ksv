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
BinDir="/usr/local/bin"
VERSION="ksv-v1.0.4-CE"

function result_cmd(){
   commandline='ksv logs'
   cat << eof
$(echo -e "\033[1;36mNOTE:\033[0m")
Verify the upgrade logs and result:
   $commandline
eof
}

function sync_bin() {
    mkdir -p ${BinDir}
    cp ${CurrentDIR}/bin/ksv ${BinDir} -f
    cp ${CurrentDIR}/bin/virtctl ${BinDir} -f
}

echo
echo "Importing images ..."
tar -zxf ${CurrentDIR}/dependencies/registry.tar.gz -C /mnt

systemctl restart registry 1>/dev/null 2>/dev/null

sync_bin

echo
echo "Starting the upgrade tool"
${BinDir}/helm del -n kubesphere-system ks-install 1>/dev/null 2>/dev/null
${BinDir}/helm upgrade --install ks-installer ${CurrentDIR}/charts/ks-installer -n kubesphere-system --create-namespace --set registry=dockerhub.kubekey.local:5000 --set image.tag=${VERSION}

sleep 20

result_cmd