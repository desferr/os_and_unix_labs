#!/bin/sh

trap 'rm -rf "${temp_dir}"' EXIT TERM INT QUIT HUP
 
if [ $# -eq 0 ]; then
    echo "Передайте название файла, который необходимо скомпилировать!" >&2
    exit 1000
fi
file="${1}"
if [ ! -f "$file" ]; then
    echo "Не удалось найти файл ${file}!" >&2
    exit 1001
fi
file_name="${file##*/}"
file_path="."
if echo "${file}" | grep -q '/'; then
    file_path="${file%/*}"
fi
grep -q '//Output:' "${file}" > /dev/null 2>&1
error_code=$?
if [ ${error_code} -eq 2 ]; then
    echo "Не удалось найти файл ${file}!" >&2
    exit 1002
fi
if [ ${error_code} -eq 1 ]; then
    echo "Не удалось найти комментарий \"//Output:\"!" >&2
    exit 1003
fi
destination=$(grep '//Output:' "${file}" | cut -d ':' -f 2 | tr -d ' ')
if [ -z "${destination}" ]; then
    echo "Название итогового файла не должно быть пустым!" >&2
    exit 1004
fi
temp_dir=$(mktemp -d)
if [ $? -ne 0 ]; then
    echo "Не удалось создать временную директорию!" >&2
    exit 1005
fi
cp "${file}" "${temp_dir}"
if [ $? -ne 0 ]; then
    echo "Не удалось скопировать файл во временную директорию!" >&2
    exit 1006
fi
g++ "${temp_dir}"/"${file_name}" -o "${file_path}"/"${destination}" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Не удалось скомпилировать файл!" >&2
    exit 1007
fi