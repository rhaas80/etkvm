#!/bin/bash

exec 2>${0%.*}.err

for i in `sudo VBoxControl sharedfolder list | awk '/^[0-9]/{sub("^[0-9]* *- *","");print}'
` ; do
  sudo mkdir -p /media/sf_$i
  sudo mount -t vboxsf -o uid=et $i /media/sf_$i
done

# output errors if there were any
if [ "x$1" != "x--quiet" ] && [ -s ${0%.*}.err ] ; then
  xmessage "Could not mount shared folder.
`cat ${0%.*}.err`"
fi

# remove empty error file when done
if [ -r ${0%.*}.err ] && ! [ -s $HOME/Desktop/MountAllShares.err ] ; then
  rm ${0%.*}.err
fi
