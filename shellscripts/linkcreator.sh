#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
   echo "Not running as root"
   echo "Exit? y/n"
   read ANSW
   if [[ $ANSW = y ]]; then
   	exit
   fi
fi

# Check for argument presence
    argument_lists=( "$@" )
    for i in "${argument_lists[@]}"; do
      if [[ $i = "-" ]] ; then
        GUI="yes"
      elif [[ $i = "-lamp" ]]; then
        LAMP="yes"
      fi
    done
if [[ $1 = "" ]]; then
   echo "Symlink creator"
   echo "Usage: $0 [source] [destination]	Create forced symlinks"
   echo "	$0 --dry				Dry run NOT WORKS"
   exit
fi   
SRC=`readlink -e $1`
DEST=`readlink -e $2`

cd $SRC
if [[ $1 = "--dry" ]]; then
   find $SRC -type f -exec echo " {} $DEST{}" \;
else
   echo "Dry run? y/n"
   read DRY
   echo "Smybolic or hard link? -fs/-f"
   read LN_TYPE
   if [[ $DRY = "y" ]]; then
     find -type f -exec echo " $SRC/{} $DEST/{}" \;
   elif [[ $DRY = "n" ]]; then
     find -type f -exec ln $LN_TYPE "$SRC"/{} "$DEST"/{} \;
   fi
fi

