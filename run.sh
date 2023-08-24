#!/bin/bash

# check user root
if [ $UID -ne 0 ]; then
	echo -e "\033[31;40;5mPlease run $0 with root user!\033[0m" 
	exit
fi
# set test path
set_test_path()
{
os_name=`grep "^ID=" /etc/os-release |cut -d = -f 2-`
dir=`realpath ./`
echo $dir
cp ./new_run.sh ./.new_run.sh
sed -i -e "s#@MAIN_DIR@#$dir#g" ./new_run.sh
}

set_autologin()
{
	# set root autologin
	if [[ -f /etc/lightdm/lightdm.conf ]]; then
		sed -i -e "s/.*autologin-user=.*/autologin-user=root/g" /etc/lightdm/lightdm.conf
	else
		echo  -e "\033[31;40mPlease make sure /etc/lightdm/lightdm.conf is existed!!!\033[0m"
		exit
	fi
	# enable root login
	if [[ "$os_name" == "Loongnix" ]]; then
		sed -i -r -e "s/^(auth.*user != root.*)/#\1/g" /etc/pam.d/lightdm-autologin
	fi

	# set autostart 
	if [[ -d /etc/xdg/autostart/ ]]; then
		cp $dir/scripts/auto_run.desktop /etc/xdg/autostart/
		sed -i -e "s#@EXEC@#$dir/new_run.sh#g" /etc/xdg/autostart/auto_run.desktop
	else
		echo "\033[31;40mPlease make sure /etc/xdg/autostart/ is existed !!!\033[0m"
		exit
	fi
	echo -n -e '\033[35mThe system will start after 10s !!!\033[0m' 
	sleep 10
	/usr/sbin/reboot
}

# check spec2006 directory is exists
check_spec_dir()
{
	SPEC2006_DIR=`realpath $(ls -d */ |grep cpu2006)`
	echo SPEC_DIR:$SPEC2006_DIR
	if [[ -d $SPEC_DIR ]]; then
		echo -e "\033[31mThe spec2006 dir is not found, Make sure the dir exists!!\033[0m "
		exit
	fi
}

# check stressapptest directory is exists
check_stress_dir()
{
	STRESS_DIR=`realpath $(ls -d */ |grep stressapptest)`
	echo STRESS_DIR:$STRESS_DIR
	if [[ -d $STRESS_DIR ]]; then
		cecho "\033[31mThe stressapptest dir is not found, Make sure the dir exists!!\033[0m "
		exit
	fi
}

# check reboot directory is exists
check_reboot_dir()
{
	REBOOT_DIR=`realpath $(ls -d */ |grep reboot)`
	echo REBOOT_DIR:$REBOOT_DIR
	if [[ -d $REBOOT_DIR ]]; then
		cecho "\033[31mThe reboot dir is not found, Make sure the dir exists!!\033[0m "
		exit
	fi
}

# check s3 directory is exists
check_s3_dir()
{
	S3_DIR=`realpath $(ls -d */ |grep s3)`
	echo S3_DIR:$S3_DIR
	if [[ -d $S3_DIR ]]; then
		cecho "\033[31mThe s3 dir is not found, Make sure the dir exists!!\033[0m "
		exit
	fi
}
set_spec2006_test()
{
	echo -n -e '\033[35mDo you want to run Spec2006 test" [Y/N]:\033[0m' 
	while read choice; do
		case $choice in
			"y"|"Y" )
				#check_spec_dir
				echo "Spec2006 Y"
				echo "Spec2006	" >> $dir/test-file_spec
				break
				;;
			"n"|"N" )
				echo "Spec2006 N"
				break
				;;
			* )
				echo -e "\033[31mInvalid input, please re-enter!\033[0m "
				echo -ne "\033[35mInput your choice [Y/N]:\033[0m"
				continue
				;;
		esac
	done
}

set_stress_test()
{
	echo -n -e '\033[35mDo you want to run Stress test" [Y/N]:\033[0m' 
	while read choice; do
		case $choice in
			"y"|"Y" )
				#check_stress_dir
				echo "Stress Y"
				echo -ne "\033[36m###Please Set Stress Test Lpas###\033[0m\n"
				echo -ne "\033[35mEnter Laps:"
				while read  testlaps;
				do
					if [[ -z $testlaps ]]; then
						echo -ne "\033[35mEnter Laps:"
						continue
					fi
					expr $testlaps + 1 &> /dev/null
					if [[ $? == 0 ]]; then
						echo "Stress	"$testlaps >> $dir/test-file_stress
						break
					else
						echo -e "\033[31mThe entered number is invalid, Please enter the correct number!\033[0m"
						echo -ne "\033[35mEnter Laps:"
						continue
					fi
				done
				break
				;;
			"n"|"N" )
				echo "Stress N"
				break
				;;
			* )
				echo -e "\033[31mInvalid input, please re-enter!\033[0m "
				echo -ne "\033[35mInput your choice [Y/N]:\033[0m"
				continue
				;;
		esac
	done
}

set_reboot_test()
{
	echo -n -e '\033[35mDo you want to run Reboot test" [Y/N]:\033[0m' 
	while read choice; do
		case $choice in
			"y"|"Y" )
				#check_reboot_dir
				echo "Reboot Y"
				echo -ne "\033[36m###Please Set Reboot Test Times###\033[0m\n"
				echo -ne "\033[35mEnter Times:"
				while read  testtimes;
				do
					if [[ -z $testtimes ]]; then
						echo -ne "\033[35mEnter Times:"
						continue
					fi
					expr $testtimes + 1 &> /dev/null
					if [[ $? == 0 ]]; then
						echo "Reboot	"$testtimes >> $dir/test-file_reboot
						break
					else
						echo -e "\033[31mThe entered number is invalid, Please enter the correct number!\033[0m"
						echo -ne "\033[35mEnter Times:"
						continue
					fi
				done
				break
				;;
			"n"|"N" )
				echo "Reboot N"
				break
				;;
			* )
				echo -e "\033[31mInvalid input, please re-enter!\033[0m "
				echo -ne "\033[35mInput your choice [Y/N]:\033[0m"
				continue
				;;
		esac
	done
}

set_s3_test()
{
	echo -n -e '\033[35mDo you want to run S3 test" [Y/N]:\033[0m' 
	while read choice; do
		case $choice in
			"y"|"Y" )
				#check_s3_dir
				echo "S3 Y"
				echo -ne "\033[36m###Please Set S3 Test Times###\033[0m\n"
				echo -ne "\033[35mEnter Times:"
				while read  testtimes;
				do
					if [[ -z $testtimes ]]; then
						echo -ne "\033[35mEnter Times:"
						continue
					fi
					expr $testtimes + 1 &> /dev/null
					if [[ $? == 0 ]]; then
						echo "S3	"$testtimes >> $dir/test-file_s3
						break
					else
						echo -e "\033[31mThe entered number is invalid, Please enter the correct number!\033[0m"
						echo -ne "\033[35mEnter Times:"
						continue
					fi
				done
				break
				;;
			"n"|"N" )
				echo "S3 N"
				break
				;;
			* )
				echo -e "\033[31mInvalid input, please re-enter!\033[0m "
				echo -ne "\033[35mInput your choice [Y/N]:\033[0m"
				continue
				;;
		esac
	done
}

# save stress old result
save_stress_result()
{
	grep Stress ./test-file |grep -v "#" 2>&1 >/dev/null
	if [[ $? -eq 0 ]]; then
		STRESS_DIR=`realpath $(ls -d */ |grep stressapptest)`
		MM=`date +%Y%m%d%H`
		mkdir -pv ${STRESS_DIR}/old/${MM}
		mv -v ${STRESS_DIR}/logs/* ${STRESS_DIR}/old/${MM} 2>&1 >/dev/null
		unset MM
	fi
}

# save spec2006 old result
save_spec2006_result()
{
	grep Spec2006 ./test-file |grep -v "#" 2>&1 >/dev/null
	if [[ $? -eq 0 ]]; then
		SPEC2007_DIR=`realpath $(ls -d */ |grep cpu2006)`
		MM=`date +%Y%m%d%H`
		mkdir -pv ${SPEC2006_DIR}/old/${MM}
		mv -v ${SPEC2006_DIR}/result/* ${SPEC2006_DIR}/old/${MM}
		unset MM
	fi
}

# save reboot old result
save_reboot_result()
{
	grep Reboot ./test-file |grep -v "#" 2>&1 >/dev/null
	if [[ $? -eq 0 ]]; then
		REBOOT_DIR=`realpath $(ls -d */ |grep reboot)`
		rm -rfv $REBOOT_DIR/*
	fi
}

# save s3 old result
save_s3_result()
{
	grep S3 ./test-file |grep -v "#" 2>&1 >/dev/null
	if [[ $? -eq 0 ]]; then
		S3_DIR=`realpath $(ls -d */ |grep s3)`
		rm -rfv $S3_DIR/*
	fi
}

init_env()
{
	#set test mode data
	set_test_path
	set_spec2006_test
	set_stress_test
	set_reboot_test
	set_s3_test

	#del old logs
	rm -rfv $dir/test-file
	rm -rfv $dir/logs

	#set test order
	temp_str[0]=" "
	echo -ne "\033[36m ##Please set your test order ########\033[0m\n"
	if [[ -f $dir/test-file_spec ]]; then
		i=1
		temp_str[i]="Spec2006"
		echo -ne "\033[36m ##       $i. Spec2006		########\033[0m\n"
	fi
	if [[ -f $dir/test-file_stress ]]; then
		i=$(($i+1))
		temp_str[i]="Stress"
		echo -ne "\033[36m ##       $i. Stress		########\033[0m\n"
	fi
	if [[ -f $dir/test-file_reboot ]]; then
		i=$(($i+1))
		temp_str[i]="Reboot"
		echo -ne "\033[36m ##       $i. Reboot		########\033[0m\n"
	fi
	if [[ -f $dir/test-file_s3 ]]; then
		i=$(($i+1))
		temp_str[i]="S3"
		echo -ne "\033[36m ##       $i. S3		########\033[0m\n"
	fi
	echo "temp_str:" ${temp_str[1]}
	echo "temp_str_len:" ${#temp_str[@]}
	if [[ ${#temp_str[@]} -le 1 ]]; then
			echo -e "\033[31mNo test case was selected! Exit!\033[0m "
			exit 0
	fi
	echo -e "\033[36m ##usage:1,2,3,4 means Spec2006,stress,reboot,S3\033[0m"
	echo -ne '\033[35mEnter the test order you want:\033[0m' 
	while read str;do
		#del blankspace
		str=${str// /} 
		#check that the input string is valid
		#check the string is < 4,or is ","
		for((i=1;i<=${#str};i++)); do
			str_c=`echo $str |cut -b $i`
			if [[ "1"x != "$str_c"x ]] && [[ "2"x != "$str_c"x ]] && [[ "3"x != "$str_c"x ]] && [[ "4"x != "$str_c"x ]] && [[ ","x != "$str_c"x ]]; then
				echo "str_c:" $i $str_c
				touch .invalid
				continue
			fi
		done
		if [[ -f .invalid ]]; then
			echo -e "\033[31mInvalid input, please re-enter!\033[0m "
			echo -ne '\033[35mEnter the test order you want:\033[0m' 
			rm -rf .invalid
			continue
		fi

		#split string and check string length and non-0
		OLD_IFS="$IFS"
		IFS=","
		testorder=($str)
		IFS="$OLD_IFS"
		echo "testorder:" ${testorder[@]}
		if [[ ${#testorder[@]} -eq 0 ]]; then
			echo -n -e '\033[35mEnter the test order you want:\033[0m' 
			continue
		fi
		if [[ ${#testorder[@]}  -gt 4 ]]; then
			echo -e "\033[31mInvalid input, please re-enter!\033[0m "
			echo -ne '\033[35mEnter the test order you want:\033[0m' 
			continue
		fi

		#write test data to test-file
		for i in "${!testorder[@]}"; do
			echo "sss:"  $i ${temp_str[${testorder[i]}]}
			if [[ ${temp_str[${testorder[i]}]} = Spec2006 ]]; then
				cat  $dir/test-file_spec >> $dir/test-file
			fi

			if [[ ${temp_str[${testorder[i]}]} = Stress ]]; then
				cat  $dir/test-file_stress >> $dir/test-file
			fi

			if [[ ${temp_str[${testorder[i]}]} = Reboot ]]; then
				cat  $dir/test-file_reboot >> $dir/test-file
			fi

			if [[ ${temp_str[${testorder[i]}]} = S3 ]]; then
				cat  $dir/test-file_s3 >> $dir/test-file
			fi
		done
		break
	done
	rm -rf $dir/test-file_*
}

# save old result
save_old_result()
{
	save_stress_result
	save_spec2006_result
	save_reboot_result
	save_s3_result
}

#set_autologin
#init_env
# get parameter
usage() {
	echo "Usage:"
	echo "run.sh [-f test-file] [-c ]"
	echo "Description:"
	echo "test-file, use test-file in the current dir"
	echo "-c, custom test case"
	exit -1
}
if [[ -z $1 ]]; then
	usage
fi
while getopts 'f:c h' OPT; do
	case $OPT in 
		f) 
			echo "begin with exited test-file"
			set_test_path	
			rm -rf $dir/logs
			save_old_result
			set_autologin
			break
			;;
		c) 
			init_env
			save_old_result
			set_autologin
			break
			;;
		h) usage 
			;;
		?) usage 
			;;
	esac
done

