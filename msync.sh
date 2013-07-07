#!/bin/bash
# sync master directory's update to slave directory.

syncmaster=
syncslave=
paramok=0
# create if not exsit slave directory.
cnflg=0
# first sync
first=0
# sync after update.
dosync=0
# do add file sync only
doadd=0

# $1: mode, mode=2 normal help.
function __show_usage() {
	if [ "$1" == "2" ]; then
		echo -e "NAME"
		echo -e "    msync - sync files from master to slave directory."
	fi
		echo -e "USAGE:"
		echo -e "    ./msync.sh [[-m directory] [-s directory]|-c|-h]"
	if [ "$1" == "2" ]; then
		echo -e "OPTIONS"
		echo -e "    -m: spesfic master directory."
		echo -e "    -s: spesfic slave directory."
		echo -e "    -c: create slave directory if not exsit."
		echo -e "    -S: do sync after update."
		echo -e "    -A: do add/update file/directory operate."
		echo -e "    -h: show this message."
	fi
}

# m: master directory.
# s: slave directory.
while getopts "m:s:chAS" arg
do
  case "$arg" in
   "m") 
		if [ -d $OPTARG ]; then 
			syncmaster=`echo $OPTARG | sed -e 's/\/$//'`;
			paramok=`expr $paramok + 1`;
		else
			echo "Wrong paramete sync-master directory.abort!!!";exit 1;
		fi  ;;
   "s") 
   		syncslave=`echo $OPTARG | sed -e 's/\/$//'`;
		paramok=`expr $paramok + 1`; ;;
   "c") cnflag=1; ;;
   "S") dosync=1; ;;
   "A") doadd=1;  ;;
   "h") __show_usage 2;exit 0; ;;
   *) ;;
  esac
done

# create slave directory if not exsit.
if [ "$cnflag" == "1" ]; then
	if [ ! -e $syncslave ]; then
		mkdir -p $syncslave;
		first=1;
	fi
fi

if [ ! -d $syncslave ]; then
	echo "Wrong paramete sync-slave directory.abort!!!";exit 1;
fi

#echo $paramok
if [ $paramok -eq 2 ]; then
	echo "parasing.....";
else
	__show_usage 1;exit 1;
fi

# sync create/modify file/directory.
# $1: master directory.
# $2: slave directory.
function __sync_cf_cd() {
	# update file and directory status from master.
	# OPS: add, modify file/directory in master.
	for f in `ls -A $1`; do
		if [ -d $1/$f ]; then
			if [ ! -d $2/$f ]; then
				echo -e "\033[49;32;5m[CD]\033[0m $2/$f/";
				mkdir $2/$f;
			else 
				rm $2/$f 2>/dev/null;true;
			fi
			__sync_cf_cd $1/$f $2/$f;
		else
			if [ ! -e $2/$f ]; then
				echo -e "\033[49;32;5m[CF]\033[0m $2/$f";
				cp $1/$f $2/$f 2>/dev/null;
			else
				md51=`md5sum $1/$f | awk '{print $1}'`;
				md52=`md5sum $2/$f | awk '{print $1}'`;
				if [ "$md51" != "$md52" ]; then
					echo -e "\033[49;33;5m[UF]\033[0m $2/$f";
				fi
				cp -u $1/$f $2/$f 2>/dev/null;
			fi
		fi
	done
}

# sync delete file/directory.
# $1: master directory.
# $2: slave directory.
function __sync_df_dd() {
	# delete un-exsit file and directory from slave directory.
	# OPS: delete file/directory in master.
	for f in `ls -A $2`; do
		if [ -d $2/$f ]; then
			if [ -d $1/$f ]; then
				__sync_df_dd $1/$f $2/$f;
			else
				echo -e "\033[49;31;5m[DD]\033[0m $2/$f";
				rm -rf $2/$f 2>/dev/null;true;
			fi
		else
			if [ ! -f $1/$f ]; then
				echo -e "\033[49;31;5m[DF]\033[0m $2/$f";
				rm -rf $2/$f 2>/dev/null;true;
			fi
		fi
	done
}

# $1 : master directory
# $2 : slave directory
function __sync_all() {
	__sync_cf_cd $1 $2;
	if [ $doadd -ne 1 ]; then
		if [ $first -ne 1 ]; then
			__sync_df_dd $1 $2;
		fi
	fi
}

#echo $syncmaster $syncslave
__sync_all $syncmaster $syncslave

# do sync after update.
if [ "$dosync" == "1" ]; then
	sync
fi

exit 0
