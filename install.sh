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
allinone="false"
multinodes="false"
hostpath=""
VERSION="ksv-v1.0.4-CE"
ratio=3

# Parse the command line and set variables to control logic
parseCommandLine() {
	# Special case that nothing was provided on the command line so print usage
	# - include this if it is desired to print usage by default
	if [ "$#" -eq 0 ]; then
		printUsage
		exit 0
	fi
	# Indicate specification for single character options
	# - 1 colon after an option indicates that an argument is required
	# - 2 colons after an option indicates that an argument is optional, must use -o=argument syntax
	optstring="hamv"
	# Indicate specification for long options
	# - 1 colon after an option indicates that an argument is required
	# - 2 colons after an option indicates that an argument is optional, must use --option=argument syntax
	optstringLong="help,hostpath:,ratio:,version"
	# Parse the options using getopt command
	# - the -- is a separator between getopt options and parameters to be parsed
	# - output is simple space-delimited command line
	# - error message will be printed if unrecognized option or missing parameter but status will be 0
	# - if an optional argument is not specified, output will include empty string ''
	GETOPT_OUT=$(getopt --options $optstring --longoptions $optstringLong -- "$@")
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo ""
		printUsage
		exit 1
	fi
	# The following constructs the command by concatenating arguments
	# - the $1, $2, etc. variables are set as if typed on the command line
	# - special cases like --option=value and missing optional arguments are generically handled
	#   as separate parameters so shift can be done below
	eval set -- "$GETOPT_OUT"
	# Loop over the options
	# - the error handling will catch cases were argument is missing
	# - shift over the known number of options/arguments
	while true; do
		#echo "Command line option is $opt"
		case "$1" in
			-h|--help) # -h or --help  Print usage
				printUsage
				exit 0
				;;
			-a)
			  if [[ ${multinodes} == "false" ]]; then
				  allinone="true"
				fi
				shift
				;;
			--hostpath)
				hostpath=$2
				shift 2
				;;
			--ratio)
				ratio=$2
				re="^[1-6]$"
				if [[ $ratio =~ $re ]]; then :
				  else
				  echo "The value of --ratio must be an integer ranging from 1 to 5."
				  exit 1
				fi
				shift 2
				;;
			-m)
			  if [[ ${allinone} == "false" ]]; then
			    multinodes="true"
			  fi
			  shift
				;;
			-v|--version) # -v or --version  Print the version
				printVersion
				exit 0
				;;
			--) # No more arguments
				shift
				break
				;;
			*) # Unknown option - will never get here because getopt catches up front
				echo ""
				echo "Invalid option $1." >&2
				printUsage
				exit 1
				;;
		esac
	done
	# Get a list of all command line options that do not correspond to dash options.
	# - These are "non-option" arguments.
	# - For example, one or more file or folder names that need to be processed.
	# - If multiple values, they will be delimited by spaces.
	# - Command line * will result in expansion to matching files and folders.
	shift $((OPTIND-1))
	additionalOpts=$*
}

function printUsage() {
    echo "Usage:"
    echo
    echo "./install.sh [FLAG]"
    echo
    echo "Description:"
    echo "  -a                     : AllinOne Mode"
    echo "  --hostpath             : Specify the csi-hostpath data directory"
    echo "  -m                     : MultiNodes Mode"
    echo "  --ratio                : cpu allocation ratio [1~6] (default: 3)"
    echo "  -h                     : usage message"
    echo "  --help"
    exit
}

function prerequisites(){

    clear

    cat << eof
$(echo -e "\033[1;36mPrerequisites:\033[0m")

1. OS requirements：

   ubuntu18.04 / ubuntu20.04 (at least 4 CPUs and 8GB RAM and 100GB Disk)

2. Check whether the server supports virtualization.

   Execute the following command on the server. If there is no output, the current server doesn't support virtualization.

  $(echo -e "\033[3m $ grep -E '(svm|vmx)' /proc/cpuinfo \033[0m")

3. Disk requirements

eof

   if [[ ${allinone} == "true" ]]; then
    cat << eof
   In order to keep the system running stably, it is suggested that:

     Mount a separate disk for '/var/lib/csi-hostpath-data'

   or

     Use '--hostpath' to specify a directory where the disk has been mounted separately

eof
   fi


   if [[ ${multinodes} == "true" ]]; then
    cat << eof
   In order to configure the Ceph storage cluster, at least one of these local storage options are required:

     Raw devices (no partitions or formatted filesystems)
     Raw partitions (no formatted filesystem)

   You can confirm whether your partitions or devices are formatted filesystems with the following command.

    $(echo -e "\033[3m $ lsblk -f \033[0m")

     NAME                  FSTYPE      LABEL UUID                                     MOUNTPOINT
     vda
     └─vda1                LVM2_member       >eSO50t-GkUV-YKTH-WsGq-hNJY-eKNf-3i07IB
      ├─ubuntu--vg-root    ext4              c2366f76-6e21-4f10-a8f3-6776212e2fe4     /
      └─ubuntu--vg-swap_1  swap              9492a3dc-ad75-47cd-9596-678e8cf17ff9     [SWAP]
     vdb

   If the 'FSTYPE' field is not empty, there is a filesystem on top of the corresponding device. In this case, you can use vdb for Ceph and can’t use vda and its partitions.

eof
   fi

    read -p "Please ensure that your environment has met the above requirements  (yes/no) " ans
    while [[ "x"$ans != "xyes" && "x"$ans != "xno" ]]; do
        read -p "Please ensure that your environment has met the above requirements  (yes/no) " ans
    done

    if [[ "x"$ans == "xno" ]]; then
        echo "Please reprepare the machines meeting the above requirements, then restart the installation !"
        exit
    fi
}

function result_cmd(){
   commandline='ksv logs'
   cat << eof
$(echo -e "\033[1;36mNOTE:\033[0m")
Verify the installation logs and result:
   $commandline
eof
}

function result_notes(){
    timeout=0
    info='The ks-installer is running'
    while [ $timeout -le 1200 ]
    do
      clear
      echo -e "\033[1;36m$info\033[0m"
      ${BinDir}/kubectl exec -n kubesphere-system $(${BinDir}/kubectl get pod -n kubesphere-system -l app=ks-install -o jsonpath='{.items[0].metadata.name}') -- ls /kubesphere/playbooks/kubesphere_running &> /dev/null
      if [[ $? -eq 0 ]]; then
         ${BinDir}/kubectl exec -n kubesphere-system $(${BinDir}/kubectl get pod -n kubesphere-system -l app=ks-install -o jsonpath='{.items[0].metadata.name}') -- cat /kubesphere/playbooks/kubesphere_running
         break
      else
         i=0
         b=''
         while [ $i -le 10 ]
         do
          printf "Please wait for the installation to complete %s\r" $b;
          sleep 1
          ((timeout=timeout+1))
          ((i=i+2))
          b+='.'
         done
      fi
    done
    echo
    result_cmd
}

function sync_bin() {
    mkdir -p ${BinDir}
    cp ${CurrentDIR}/bin/ksv ${BinDir}
    cp ${CurrentDIR}/bin/virtctl ${BinDir}
}

if [[ `whoami` != 'root' ]]; then
    notice_user="Current user is `whoami`. Please use root!"
    echo -e "\033[1;36m$notice_user\033[0m"
    exit
fi

parseCommandLine "$@"
prerequisites

if [[ ${allinone} == "true" ]]; then
  clear
  ${CurrentDIR}/bin/kk pre-check
  if [[ $? -ne 0 ]]; then
    exit 1
  fi
  ${CurrentDIR}/bin/kk init os -s ${CurrentDIR}/dependencies
  systemctl stop registry 1>/dev/null 2>/dev/null
  ${CurrentDIR}/bin/kk init registry

  echo
  echo "Importing images ..."
  tar -zxf ${CurrentDIR}/dependencies/registry.tar.gz -C /mnt

  sync_bin

  ${CurrentDIR}/bin/kk create cluster --with-kubernetes v1.20.7-k3s

  if [[ ${hostpath} != "" ]]; then
    ${BinDir}/helm upgrade --install host-path-csi ${CurrentDIR}/charts/csi-driver-host-path -n kube-system \
    --set snapshot-controller.repository=dockerhub.kubekey.local:5000/csiplugin/snapshot-controller\
    --set attacher.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-attacher \
    --set plugins.healthMonitorAgent.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-external-health-monitor-agent \
    --set plugins.healthMonitorController.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-external-health-monitor-controller \
    --set plugins.nodeDriverRegistrar.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-node-driver-registrar \
    --set plugins.hostPathPlugin.repository=dockerhub.kubekey.local:5000/kubespheredev/hostpathplugin \
    --set plugins.livenessProbe.repository=dockerhub.kubekey.local:5000/kubespheredev/livenessprobe \
    --set provisioner.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-provisioner \
    --set resizer.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-resizer \
    --set snapshotter.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-snapshotter \
    --set testing.repository=dockerhub.kubekey.local:5000/alpine/socat \
    --set plugins.hostPathPlugin.dataDir=${hostpath}
  else
    ${BinDir}/helm upgrade --install host-path-csi ${CurrentDIR}/charts/csi-driver-host-path -n kube-system \
    --set snapshot-controller.repository=dockerhub.kubekey.local:5000/csiplugin/snapshot-controller\
    --set attacher.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-attacher \
    --set plugins.healthMonitorAgent.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-external-health-monitor-agent \
    --set plugins.healthMonitorController.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-external-health-monitor-controller \
    --set plugins.nodeDriverRegistrar.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-node-driver-registrar \
    --set plugins.hostPathPlugin.repository=dockerhub.kubekey.local:5000/kubespheredev/hostpathplugin \
    --set plugins.livenessProbe.repository=dockerhub.kubekey.local:5000/kubespheredev/livenessprobe \
    --set provisioner.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-provisioner \
    --set resizer.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-resizer \
    --set snapshotter.repository=dockerhub.kubekey.local:5000/kubespheredev/csi-snapshotter \
    --set testing.repository=dockerhub.kubekey.local:5000/alpine/socat
  fi

  advancedFlags="--set virtualization.cpuAllocationRatio=${ratio}"

  if [ -f .emulation.tmp ]; then
      advancedFlags="${advancedFlags} --set virtualization.useEmulation=true"
  fi

  ${BinDir}/helm upgrade --install ks-install ${CurrentDIR}/charts/ks-installer -n kubesphere-system --create-namespace --set registry=dockerhub.kubekey.local:5000 --set image.tag=${VERSION} ${advancedFlags}

  if [[ $? -eq 0 ]]; then
    sleep 5
    str="successsful!"
    echo -e "\033[30;47m$str\033[0m"
    result_notes
  fi
fi

if [[ ${multinodes} == "true" ]]; then
  clear
  ${CurrentDIR}/bin/kk pre-check -f ${CurrentDIR}/config-sample.yaml
  if [[ $? -ne 0 ]]; then
    exit 1
  fi
  ${CurrentDIR}/bin/kk init os -s ${CurrentDIR}/dependencies -f ${CurrentDIR}/config-sample.yaml
  systemctl stop registry 1>/dev/null 2>/dev/null
  ${CurrentDIR}/bin/kk init registry -f ${CurrentDIR}/config-sample.yaml

  echo
  echo "Importing images ..."
  tar -zxf ${CurrentDIR}/dependencies/registry.tar.gz -C /mnt

  sync_bin

  if [ -f .emulation.tmp ]; then
     sed -i "/useEmulation/s/\=.*/\=true/g" ${CurrentDIR}/config-sample.yaml
  fi
  sed -i "/cpuAllocationRatio/s/\=.*/\=${ratio}/g" ${CurrentDIR}/config-sample.yaml

  ${CurrentDIR}/bin/kk create cluster -f ${CurrentDIR}/config-sample.yaml
  result_cmd
fi

