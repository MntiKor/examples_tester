#!/bin/bash

if [ $# != 3 ]
then
	echo "Usage: ./GenerateExamplesWASM.sh <vtk_source_dir> <source_dir> <target_dir>"
	exit 1
fi

vtk_source_dir=$1
source_dir=$2
target_dir=$3

shopt -s extglob
for topic in ${source_dir}/*/
do
	topic_name=$(basename ${topic})
	for f in ${topic}/*.cxx
	do
		find_packages=$(python WhatModulesVTK.py ${vtk_source_dir} ${f})
		name=$(basename ${f} .cxx)
		echo ${name} >> results/logs.txt
		target_path=${target_dir}/${topic_name}/${name}
		mkdir -p ${target_path}
		cp ${f} ${target_path}
		for addon_file in ${topic}/${name}.!(md)
		do
			cp ${addon_file} ${target_path}
		done
		cp CMakeLists.txt.template ${target_path}/CMakeLists.txt
		cp index.html.template ${target_path}/index.html
		sed -i "s/XXX/${name}/g" ${target_path}/index.html
		sed -i "s/XXX/${name}/g" ${target_path}/CMakeLists.txt
		perl -pi -e "s/ZZZ/${find_packages}/g" ${target_path}/CMakeLists.txt
	done
done
cp entrypoint.sh ${target_dir}
docker run --rm -v ${target_dir}:/work -it --entrypoint /bin/bash kitware/vtk-wasm /work/entrypoint.sh
