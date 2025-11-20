#!/bin/sh -e

trap_function () {
	exit_code=$?
	trap - EXIT HUP TERM QUIT INT
	if [ -e "${volume_path}/.lockfile" ]; then
		rm "${volume_path}/.lockfile"
	fi
	if [ -n "${containers_amount}" ]; then
		i=1
		while [ ${i} -le ${containers_amount} ]; do
			docker stop "container${i}" > /dev/null 2>&1 || true
			docker rm "container${i}" > /dev/null 2>&1 || true
			echo "Контейнер container${i} успешно удалён!"
			i=$((i+1))	
		done
		docker rmi "con_cnt_image:latest" > /dev/null 2>&1
		echo "Образ успешно удалён!"
	fi
	exit ${exit_code}
}

trap trap_function EXIT HUP TERM QUIT INT

if [ ! \( $# -eq 2 -o $# -eq 3 \) ]; then
	echo "Некорректное количество аргументов!" >&2
	exit 10
fi

create_volume=0
if [ $# -eq 3 ]; then
	if [ "$1" = "-c" ]; then
		create_volume=1
	else
		echo "Некорректные аргументы!" >&2
		exit 11
	fi
fi

if [ ${create_volume} -eq 0 ]; then
	volume_path="$1"
	if [ ! -e "${volume_path}" ]; then
        	echo "Тома ${volume_path} не существует!" >&2
        	exit 12
	fi
	containers_amount="$2"
else
	volume_path="$2"
	mkdir -p "${volume_path}"
	containers_amount="$3"
fi
if ! [ "${containers_amount}" -eq "${containers_amount}" ] > /dev/null 2>&1 || [ "${containers_amount}" -le 0 ]; then
	echo "Количество контейнеров указано некорректно!" >&2
	exit 13
fi
touch "${volume_path}/.lockfile"
docker build -t con_cnt_image .
i=1
while [ ${i} -le ${containers_amount} ]; do
	docker run --name "container${i}" -d -v "${volume_path}:/src/shared" con_cnt_image:latest > /dev/null 2>&1
	echo "Контейнер container${i} успешно запущен!"
	i=$((i+1))
done

echo "Успешно запущено ${containers_amount} контейнеров!"
echo "Разделяемый том: ${volume_path}"

while true; do
	sleep 300
done
