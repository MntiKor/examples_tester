#!/bin/bash

cd /work
for topic in */
do
	for example in ${topic}/*/
	do
		mkdir ${example}/build
		cd ${example}/build
		cmake -GNinja -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -DVTK_DIR=/VTK-install/Release/lib/cmake/vtk -DCMAKE_BUILD_TYPE=Release ..
		if [ $? -ne 0 ]
		then
			echo $(basename ${example}) >> /work/doesntcompile.txt
		else
			cmake --build .
			if [ $? -ne 0 ]
			then
				echo $(basename ${example}) >> /work/doesntcompile.txt
			fi
		fi
		cd /work
	done
done
