#!/bin/bash

DIR_LOG1="$(cd "$(dirname "${BASH_SOURCE[0]}")"&&pwd)"
DIR_LOG="$DIR_LOG1/../check_logs"
echo "asd:" $DIR_LOG
if [[ ! -d $DIR_LOG ]]; then
	mkdir -p $DIR_LOG
fi

memsizecheck()
{
	CURRENT_RAMSIZE=$(free -m | grep -i mem | awk '{ print $2 }')
	if [ ! -s $DIR_LOG/memory.log ]; then 
		echo "$CURRENT_RAMSIZE" > $DIR_LOG/memory.log
	fi
	if [ "$CURRENT_RAMSIZE" = "`cat $DIR_LOG/memory.log`" ]; then
		cecho "$DATE >> Memory size detect test pass!" $blue
		cecho "System current detected $CURRENT_RAMSIZE MB is equal to `cat $DIR_LOG/memory.log` MB should be detected\n" $green
	else
		cecho "$DATE >> Memory size detect test fail!!" $red $blink
		cecho "System current detected $CURRENT_RAMSIZE MB is NOT equal to `cat $DIR_LOG/memory.log` MB should be detected\n" $red | tee -a $DIR_LOG/memory_err.log
		echo "$CURRENT_RAMSIZE" > $DIR_LOG/memory_err.log
		free -m > $DIR_LOG/MEM.log
		read -p "! Error detected ! Test paused...!"
		exit
	fi
}

pcidevicecheck()
{

	if [ ! -s $DIR_LOG/pciedevice.log ] ; then 
		#lspci > $DIR_LOG/pciedevice.log
		lspci -vvv |grep -i -E "^0|lnksta:|driver" >$DIR_LOG/pciedevice.log		
	fi
	lspci -vvv |grep -i -E "^0|lnksta:|driver"  > $DIR_LOG/pciedevice_current.log 
	diff $DIR_LOG/pciedevice.log $DIR_LOG/pciedevice_current.log 2>&1 > /dev/null
	_ret=$?
	if [ $_ret = 0 ]; then
		cecho "$DATE >> PCI device detect test pass!" $blue
	else
		cecho "$DATE >> PCI device detect test fail!!" $red $blink
		echo "PCI device detect test fail!!" >> $DIR_LOG/pciedevice_err.log
		#cecho "The device listed below is missing:\n" $white
		#echo "The device listed below is missing:" >> $DIR_LOG/pciedevice_err.log
		diff $DIR_LOG/pciedevice.log $DIR_LOG/pciedevice_current.log | tee -a $DIR_LOG/pciedevice_err.log
		echo 1>>$DIR_LOG/count.log
		do_memsizecheck
		do_cpu_core_num_check
		do_disk_check
		read -p "! Error detected ! Test paused...!"
		exit
	fi
}

cpu_core_num_check()
{
	CORE_NUMS=`cat /proc/cpuinfo | grep "processor" | wc -l`
	if [ ! -s $DIR_LOG/cpuinfo.log ]; then 
		echo "$CORE_NUMS" > $DIR_LOG/cpuinfo.log
	fi
	if [ "$CORE_NUMS" = "`cat $DIR_LOG/cpuinfo.log`" ]; then
		cecho "$DATE >> System's total core numbers is correct!" $blue
		cecho "System now have total $CORE_NUMS cores is equal to `cat $DIR_LOG/cpuinfo.log` cores should be detected\n" $green
	else
		cecho "$DATE >> There are some CPU core missing!!" $red $blink
		cecho "System current have $CORE_NUMS cores is NOT equal to `cat $DIR_LOG/cpuinfo.log` cores should be detected\n" $red | tee -a $DIR_LOG/cpuinfo_err.log
		cat /proc/cpuinfo > $DIR_LOG/CPU.log
		echo "*******************" >>$DIR_LOG/CPU.log
		lscpu >> $DIR_LOG/CPU.log
		read -p "! Error detected ! Test paused...!"
		exit
	fi
}

disk_check()
{
	DISK_NUMS=`fdisk -l |grep -i "Disk /dev/sd" | wc -l`
	if [ ! -s $DIR_LOG/diskinfo.log ]; then 
		echo "$DISK_NUMS" > $DIR_LOG/diskinfo.log
	fi
	if [ "$DISK_NUMS" = "`cat $DIR_LOG/diskinfo.log`" ]; then
		cecho "$DATE >> System's total disk numbers is correct!" $blue
		cecho "System now have total $DISK_NUMS hdds is equal to `cat $DIR_LOG/diskinfo.log` hdds should be detected\n" $green
	else
		cecho "$DATE >> There are some disk missing!!" $red $blink
		cecho "System current have $DISK_NUMS hdds is NOT equal to `cat $DIR_LOG/diskinfo.log` hdds should be detected\n" $red | tee -a $DIR_LOG/diskinfo_err.log
		fdisk -l |grep -i "Disk /dev/sd" > $DIR_LOG/FDISK.log
		read -p "! Error detected ! Test paused...!"
		exit
	fi
}

nvme_check()
{
	NVME_NUMS=`fdisk -l |grep -i "Disk /dev/nvme" | wc -l`
	if [ ! -s $DIR_LOG/nvmeinfo.log ]; then 
		echo "$NVME_NUMS" > $DIR_LOG/nvmeinfo.log
	fi
	if [ "$NVME_NUMS" = "`cat $DIR_LOG/nvmeinfo.log`" ]; then
		cecho "$DATE >> System's total nvme disk numbers is correct!" $blue
		cecho "System now have total $NVME_NUMS NVME_SSDs is equal to `cat $DIR_LOG/nvmeinfo.log` NVME_SSDs should be detected\n" $green
	else
		cecho "$DATE >> There are some nvme disk missing!!" $red $blink
		cecho "System current have $NVME_NUMS NVME_SSDs is NOT equal to `cat $DIR_LOG/nvmeinfo.log` NVME_SSDs should be detected\n" $red | tee -a $DIR_LOG/nvmeinfo_err.log
		fdisk -l |grep -i "Disk /dev/nvme"  > $DIR_LOG/NVME.log
		read -p "! Error detected ! Test paused...!"
		exit
	fi
}

#get_time()
#{
#
#}
