#!/bin/bash
#set -x
#date 2023-06-16

# echo color define
black='30;40m'
red='31;40m'
green='32;40m'
yellow='33;40m'
blue='34;40m'
magenta='35;40m'
cyan='36;40m'
white='37;40m'
blink='\E[5;'
bright='\E[1;'

# Color-echo.  Argument $1 = message
cecho () 
{
	local default_msg="No message passed."
	# Doesn't really need to be a local variable.
	message=${1:-$default_msg}  # Defaults to default message.
	attr=${3:-$bright}
	color=${2:-$black}          # Defaults to black, if not specified.

	echo -e "$attr""$color""$message"
	tput sgr0		    #  Reset text attributes to normal
	#+ without clearing screen.
	return
}  

# get mem Manufacturer
MEM_MANUFACTURER=`dmidecode  -t 17 |grep "Manufacturer:"`
if [[ $? != 0 ]]; then
	MEM_MANUFACTURER="mem manufacturer is null"
fi

# set environment
#DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"&&pwd)"
DIR="@MAIN_DIR@"
#echo $DIR
if [[ ! -d $DIR ]]; then
       cecho "The Test Dir is not found, Please check your test path!!" $red $blink	
       exit
fi

cd $DIR

SPEC2006_DIR=`realpath $(ls -d */ |grep cpu2006)`
#echo SPEC2006_DIR:$SPEC2006_DIR

STRESS_DIR=`realpath $(ls -d */ |grep stressapptest)`
#echo STRESS_DIR:$STRESS_DIR

REBOOT_DIR=`realpath $(ls -d */ |grep reboot)`
#echo REBOOT_DIR:$REBOOT_DIR

S3_DIR=`realpath $(ls -d */ |grep s3)`
#echo S3_DIR:$S3_DIR

LOGS="$DIR/logs"
#echo $LOGS
if [[ ! -d $LOGS ]]; then
	mkdir $LOGS
fi

TAG_LOGS="$LOGS/tag_logs"
if [[ ! -d $TAG_LOGS ]]; then
	mkdir $TAG_LOGS
fi

ERR_LOG="$LOGS/err_logs.txt"
if [[ ! -f $ERR_LOG ]]; then
	 touch $ERR_LOG
fi

RUN_LOG="$LOGS/run_log.txt"
if [[ ! -f $RUN_LOG ]]; then
	 touch $RUN_LOG
fi

SPEC_LOG="$LOGS/spec.txt"
if [[ ! -f $SPEC_LOG ]]; then
	touch $SPEC_LOG
fi

STRESS_LOG="$LOGS/spec.txt"
if [[ ! -f $STRESS_LOG ]]; then
	touch $STRESS_LOG
fi

TEST_FILE="$DIR/test-file"
#echo $TEST_FILE
if [[ ! -f $TEST_FILE ]]; then
	cecho "The test item does not exist, Plesase specify the test-file! " $red $blink
	exit
fi

DIR_SCRIPTS="$DIR/scripts"
#echo $DIR_SCRIPTS
if [[ ! -f $DIR_SCRIPTS/hardware_check.sh ]] || [[ ! -f $DIR_SCRIPTS/auto_run.desktop ]]; then
	cecho "The test scripts dir not found, Please check your test scripts!!"
	exit
else
	. $DIR_SCRIPTS/hardware_check.sh
fi

# stop test func
stop_test()
{
	rm -f /etc/xdg/autostart/auto_run.desktop
	sed -i -e "s/^autologin-user=.*/#autologin-user=/g" /etc/lightdm/lightdm.conf
	#if [ "$OS_NAME" ==  '"loongnix-server"' ];then
	#       sed -i -e "s/^autologin-user-timeout=.*/#autologin-user-timeout=0/g" /etc/lightdm/lightdm.conf
	#fi
	if [ "$OS_NAME" ==  "Loongnix" ];then
		sed -i -r -e "s/^#(auth.*user != root.*)/\1/g" /etc/pam.d/lightdm-autologin
	fi
	#sed -i -e "s/^#minimum-uid=500$/minimum-uid=500/g" /etc/lightdm/users.conf
}


# spec2006 test func
start_spec2006_test()
{
	echo ">>>>>>>>>>$test_object<<<<<<<<<" |tee -a $RUN_LOG |tee -a $SPEC_LOG
	echo `date` |tee -a $RUN_LOG |tee -a $SPEC_LOG
	cd  $SPEC2006_DIR

	# begin start test
	ulimit -s unlimited
	ulimit -c unlimited
	source shrc
	relocate
	md5sum ./exe/*
	echo "run spec2006 ref" |tee -a $SPEC_LOG
	runspec -c gcc-2006.cfg -i ref -n 3 -r 4 all 2>&1 |tee -a $SPEC_LOG |tee -a $RUN_LOG 
	grep -q "NR" $SPEC2006_DIR/result/*.txt
	if [[ $? -ne 1 ]]; then
		touch $TAG_LOGS/spec2006_fail
		echo "RUN SPEC2006 FAIL!" |tee -a $SPEC_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/spec_result.txt
		echo "=======================================================" |tee -a $SPEC_LOG |tee -a $RUN_LOG |tee -a $DIR/logs/spec_result.txt
		echo "=======================================================" |tee -a $SPEC_LOG |tee -a $RUN_LOG |tee -a $DIR/logs/spec_result.txt
		echo `date` |tee -a $ERR_LOG |tee -a $RUN_LOG |tee -a $DIR/logs/spec_result.txt
		echo "SPEC2006:FAIL!" |tee -a $ERR_LOG |tee -a $RUN_LOG |tee -a $DIR/logs/spec_result.txt
		mv $DIR/logs/spec_result.txt $DIR/logs/spec_fail.txt
		sed -i "1i $MEM_MANUFACTURER" $DIR/logs/spec_fail.txt
		stop_test
		echo -n -e "\033[35mPlease See details in the $SPEC_LOG\033[0m"
		while true; do
			read
		done
		#sleep 10
		#/usr/sbin/reboot
	else
		touch $TAG_LOGS/spec2006_pass
		echo "RUN SPEC2006 SUCCESS!" |tee -a $SPEC_LOG |tee -a $RUN_LOG |tee -a $DIR/logs/spec_result.txt
		echo "=======================================================" |tee -a $SPEC_LOG |tee -a $RUN_LOG |tee -a $DIR/logs/spec_result.txt
		echo "=======================================================" |tee -a $SPEC_LOG |tee -a $RUN_LOG |tee -a $DIR/logs/spec_result.txt
		mv $DIR/logs/spec_result.txt $DIR/logs/spec_success.txt
		sed -i "1i $MEM_MANUFACTURER" $DIR/logs/spec_success.txt
	fi
	sleep 60
	/usr/sbin/reboot
}

# stress test func
start_stress_test()
{
	echo ">>>>>>>>>>$test_object<<<<<<<<<" |tee -a $STRESS_LOG |tee -a $RUN_LOG 
	echo `date` |tee -a $STRESS_LOG |tee -a $RUN_LOG 
	cd  $STRESS_DIR
	# check count file 
	if [[ ! -r $STRESS_DIR/logs/count ]]; then
		#echo "1" >>$STRESS_DIR/logs/count
		touch $STRESS_DIR/logs/count
	fi
	echo 3 > /proc/sys/vm/drop_caches

	stress_time=`grep Stress $DIR/test-file |grep -v "#" |awk '{print $2}'`
	#echo "stress_time:" $stress_time >> $ERR_LOG
	memory_total=$(free -m | awk 'NR==2' | awk '{print $4}')
	free_memory=$(echo "${memory_total}*0.8"|bc|awk '{print int($0)}') 
	#shijian=1
	shijian=24
	#seconds=$(($shijian*60))
	seconds=$(($shijian*3600))
	loop=$((${free_memory}/1200))
	remain=$((${free_memory}%1200))
	echo "1" >> ${STRESS_DIR}/logs/count
	stress_count=`cat ${STRESS_DIR}/logs/count |wc -l`
	stress_result_log="${STRESS_DIR}/logs/Final_log.txt"
	stress_date=`date +%G-%m-%d-%H-%M`
	mkdir -p ${STRESS_DIR}/logs/${stress_date}/

	cd $STRESS_DIR/src 
	echo -e "\033[31m Start Stressapptest $(date +'%Y-%m-%d %H:%M:%S')\033[0m" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG 
	for (( i=0; i<${loop}; i=i+1 )); do
		echo -e "Start process ${i} \n"
		./stressapptest -M 1200 -s ${seconds} --pause_delay $((${seconds} + 20000)) -l ${STRESS_DIR}/logs/${stress_date}/log-stressapptest-${i}  2>&1 |tee -a $STRESS_LOG |tee -a $RUN_LOG &
		sleep 5
	done
	if [ ${remain} -gt 100 ]; then
		echo -e "Start process ${loop} \n"
		./stressapptest -M ${remain} -s ${seconds} --pause_delay $((${seconds} + 20000)) -l ${STRESS_DIR}/${stress_date}/log-stressapptest-${loop}  2>&1 |tee -a $STRESS_LOG |tee -a $RUN_LOG &
	fi

	while :
	do
		#sleep 3m
		sleep 10m
		if [[ -z "$(ls -A ${STRESS_DIR}/logs/${stress_date})" ]]; then
			touch $TAG_LOGS/stress_fail
			echo -e "+------------ Stressapptest fail -----------+" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG |tee -a $DIR/logs/stress_result.txt
			echo  "+------------ Stressapptest fail -----------+"
			read 	
			stop_test
		fi
		LOGFAIL=$(find ${STRESS_DIR}/logs/${stress_date} -name "log*" | xargs grep "Error" | wc -l)
		if [ ${LOGFAIL} -eq 0 ]; then
			PIDSTRE="$(ps -ef | grep "./stressapptest" | grep -v grep | wc -l)"
			if [ $PIDSTRE -eq 0 ]; then
				endtime=$(date +'%Y-%m-%d %H:%M:%S')
				start_seconds=$(date --date="${starttime}" +%s)
				end_seconds=$(date --date="${endtime}" +%s)
				num=$((end_seconds-start_seconds))
				total_seconds=`expr ${num} / 3600`
				echo -e "+------------ Stressapptest -----------+" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
				echo -e "Test Results   : PASS" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
				echo -e "Start Time     : ${starttime} " |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
				echo -e "End Time       : ${endtime} " |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
				echo -e "Total test tim : "${total_seconds}"h" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
				echo -e "+--------------------------------------+ \n" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
				sleep 10

				if [ ${stress_count} -ge $stress_time ]; then
					rm -rf ${STRESS_DIR}/logs/count
					touch $TAG_LOGS/stress_pass
					mv $DIR/logs/stress_result.txt $DIR/logs/stress_success.txt
					sed -i "1i $MEM_MANUFACTURER" $DIR/logs/stress_success.txt
					#crontab -r
					/usr/sbin/reboot
					exit 0
				else
					#echo -e "$(date +'%Y-%m-%d %H:%M:%S')  Reboot  $count \n" >> ${stress_result_log}
					echo -e "$(date +'%Y-%m-%d %H:%M:%S')  Reboot  $stress_count \n" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
					/usr/sbin/reboot
				fi
			fi
		else
			PIDSTRE2=$(ps -ef | grep "./stressapptest" | grep -v grep | awk -F " " '{print $2}')
			for s in $PIDSTRE2; do
				kill -9 $s
			done
			endtime=$(date +'%Y-%m-%d %H:%M:%S')
			start_seconds=$(date --date="${starttime}" +%s)
			end_seconds=$(date --date="${endtime}" +%s)
			num=$((end_seconds-start_seconds))
			total_seconds=`expr ${num} / 3600`
			echo -e "+------------ Stressapptest -----------+" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
			echo -e "Test Results   : Error " |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
			echo -e "Start Time     : ${starttime} " |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
			echo -e "End Time       : ${endtime} " |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
			echo -e "Total test tim : "${total_seconds}"h" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
			echo -e "+--------------------------------------+ \n" |tee -a ${stress_result_log} $STRESS_LOG |tee -a $RUN_LOG  |tee -a $DIR/logs/stress_result.txt
			sleep 10

			rm -rf ${STRESS_DIR}/logs/count
			touch $TAG_LOGS/stress_fail
			mv $DIR/logs/stress_result.txt $DIR/logs/stress_fail.txt
			sed -i "1i $MEM_MANUFACTURER" $DIR/logs/stress_fail.txt
			stop_test
			echo -n -e "\033[35mPlease See details in the $STRESS_LOG\033[0m" 
			read
			sleep 10
			/usr/sbin/reboot
			exit
		fi
	done
}

# reboot test func
start_reboot_test() {
	echo ">>>>>>>>>>$test_object<<<<<<<<<" |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG 
	echo `date` |tee -a $REBOOT_DIR/reboot.log
	cd  $REBOOT_DIR
	EXECDELAY=10
	# set test count 
	if [[ ! -f $REBOOT_DIR/count ]]; then
		touch $REBOOT_DIR/count
	fi
	reboot_count=`cat $REBOOT_DIR/count |wc -l`
	reboot_time=`grep Reboot $DIR/test-file |grep -v "#" |awk '{print $2}'`

	if [[ $reboot_count -ge $reboot_time ]];then
		touch $TAG_LOGS/reboot_pass
		echo "******************************************************************" |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG  |tee -a $DIR/logs/reboot_result.txt
		echo "      Already Reboot: $reboot_time Times, TEST Done!!! "	|tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG |tee -a $DIR/logs/reboot_result.txt
		echo "******************************************************************" |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG |tee -a $DIR/logs/reboot_result.txt
		mv $DIR/logs/reboot_result.txt $DIR/logs/reboot_success.txt
		sed -i "1i $MEM_MANUFACTURER" $DIR/logs/reboot_success.txt
		#read
		#	exit
		echo "system reboot , wait......" |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG 
		sleep $EXECDELAY
		/usr/sbin/reboot
	fi

	echo "   This System Already Reboot: $reboot_count times.        " |tee -a $DIR/logs/reboot_result.txt
	echo "***********************************************************" |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG  
	echo -e "\n   This System Already Reboot: $reboot_count times.        \n" |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG 
	echo "***********************************************************" |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG 
	echo "************************************************************" |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG   
	echo -n "The system will Reboot in $EXECDELAY secs. Do you want to cancel the action? (y/N) " |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG 
	read -t $EXECDELAY ACTION
	echo
	if [[ "$ACTION" = "y" ]] || [[ "$ACTION" = "Y" ]] ; then
		touch $TAG_LOGS/reboot_stop
		stop_test
		echo "don't close this window, it will autoclose after next boot" |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG 
		while true; do
			read
		done
	else

	#	nvme_check
	echo -e "\n " |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG 
	reboot_num=`cat $REBOOT_DIR/count |wc -l`
	reboot_num=$(($reboot_num + 1))
	timestr=$(date +"%Y/%m/%d-%H:%M")
	echo  "$timestr: reboot count = [$reboot_num]" |tee -a $REBOOT_DIR/count |tee -a $REBOOT_DIR/reboot.log |tee -a $RUN_LOG 
	unset reboot_num
	#echo "system reboot , wait......" |tee -a $REBOOT_DIR/reboot.log
	/usr/sbin/reboot
	fi
}

# s3 test func
start_s3_test() {
	echo ">>>>>>>>>>$test_object<<<<<<<<<" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
	echo `date` |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
	cd  $S3_DIR
	EXECDELAY=30
	# set test count 
	s3_time=`grep S3 $DIR/test-file |grep -v "#" |awk '{print $2}'`
	if [[ ! -f $S3_DIR/count ]]; then
		touch $S3_DIR/count
	fi
	s3_count=`cat $S3_DIR/count |wc -l`

	echo "will do s3 $s3_time times"
	while [ $s3_count -lt $s3_time ]
	do

		echo "   This System Has Done Suspend: $s3_count time.        " |tee -a $DIR/logs/s3_result.txt
		echo "***********************************************************" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
		echo -e "\n   This System Has Done Suspend: $s3_count time.        \n" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG
		echo "***********************************************************" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
		echo "************************************************************" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG   
		echo -n "The system will Suspend in $EXECDELAY secs. Do you want to cancel the action? (y/N) " |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
		read -t $EXECDELAY ACTION
		echo
		if [[ "$ACTION" = "y" ]] || [[ "$ACTION" = "Y" ]] ; then
			touch $TAG_LOGS/S3_stop
			stop_test
			echo "don't close this window, it will autoclose after next boot" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
			while true; do
				read
			done
			exit
		else
			echo -e "\n " |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG
			timestr=$(date +"%Y/%m/%d-%H:%M")
			s3_count=$(($s3_count + 1))
			echo  "$timestr: S3 count = [$s3_count]" |tee -a $S3_DIR/count |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
			echo "***********************************************************" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
			echo -e "\n   This System Is Going To Suspend Test: $s3_count time.        \n" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
			echo "***********************************************************" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG 
			sleep 2

			rtcwake -m mem -s 10
		fi

	done
	touch $TAG_LOGS/S3_pass
	echo "******************************************************************" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG |tee -a $DIR/logs/s3_result.txt
	echo "      Already S3: $s3_time Times, TEST Done!!! "	|tee -a $S3_DIR/s3.log |tee -a $RUN_LOG |tee -a $DIR/logs/s3_result.txt
	echo "******************************************************************" |tee -a $S3_DIR/s3.log |tee -a $RUN_LOG |tee -a $DIR/logs/s3_result.txt
	mv $DIR/logs/s3_result.txt $DIR/logs/s3_success.txt
	sed -i "1i $MEM_MANUFACTURER" $DIR/logs/s3_success.txt
	/usr/sbin/reboot
}

do_hard_check() {
	# memory check
	memsizecheck
}

# setect test item
cd $DIR
do_hard_check 2>&1 |tee -a $RUN_LOG
for test_object in `cat $TEST_FILE |awk '{print $1}'`
do
	case "$test_object" in
		"Spec2006" )
			if [[ ! -f $TAG_LOGS/spec2006_pass ]] && [[ ! -f $TAG_LOGS/spec2006_fail ]];then
				#echo "start spec2006"
				start_spec2006_test
			else
				continue
			fi
			;;
		"Stress" )
			if [[ ! -f $TAG_LOGS/stress_pass ]] && [[ ! -f $TAG_LOGS/stress_fail ]];then
				#echo "start stress"
				start_stress_test
			fi
			echo "test_object:" "$test_object"
			continue
			;;
		"Reboot" )
			if [[ ! -f $TAG_LOGS/reboot_pass ]] && [[ ! -f $TAG_LOGS/reboot_fail ]];then
				#echo "start reboot"
				start_reboot_test
			fi
			echo "test_object:" "$test_object"
			continue
			;;
		"S3" )
			if [[ ! -f $TAG_LOGS/S3_pass ]] && [[ ! -f $TAG_LOGS/S3_stop ]];then
				#echo "start S3"
				start_s3_test
			fi
			echo "test_object:" "$test_object"
			continue
			;;
	esac
done

# all test has done, stop test script
stop_test
#/usr/sbin/reboot
