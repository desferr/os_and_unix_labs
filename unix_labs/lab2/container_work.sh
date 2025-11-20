#!/bin/bash
counter=1
exec 3>"/src/shared/.lockfile" 

while true; do
	file_name=""
	flock -x 3
	i=1
	while [ ${i} -le 999 ]; do
		file_path="/src/shared/$(printf %03d ${i})"
		if [ ! -e "${file_path}" ]; then
			touch "${file_path}"
			echo "${HOSTNAME} ${counter}" > "${file_path}"
			file_name="${file_path}"
			counter=$((counter + 1))
			break
		fi
		i=$((i + 1))
	done
	flock -u 3
	if [ -n "${file_name}" ]; then
		sleep 1
		rm "${file_name}"
		sleep 1
	else
		sleep 2
	fi
done
