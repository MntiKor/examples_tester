#!/bin/bash

repo=$PWD

emsdk_dir=${repo}/emsdk

if [ ! -d ${emsdk_dir} ]
then
	git clone git@github.com:emscripten-core/emsdk.git
	${emsdk_dir}/emsdk install latest
	${emsdk_dir}/emsdk activate latest
	source ${emsdk_dir}/emsdk_env.sh
	embuilder build sdl2
fi

vtk_dir=${repo}/vtk

if [ ! -d ${vtk_dir} ]
then
	git clone git@gitlab.kitware.com:astucky/vtk.git
	mkdir -p vtk/build
	pushd vtk/build
	git checkout hdf5-emscripten-compatibility
	emcmake cmake \
		-S .. \
		-B . \
		-GNinja \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_BUILD_TYPE:STRING=Release \
		-DVTK_ENABLE_LOGGING:BOOL=OFF \
		-DVTK_ENABLE_WRAPPING:BOOL=OFF \
		-DVTK_MODULE_ENABLE_VTK_RenderingContextOpenGL2:STRING=DONT_WANT \
		-DVTK_MODULE_ENABLE_VTK_RenderingLICOpenGL2:STRING=DONT_WANT \
		-DVTK_MODULE_ENABLE_VTK_RenderingCellGrid:STRING=NO \
		-DVTK_MODULE_ENABLE_VTK_sqlite:STRING=NO -DCMAKE_INSTALL_PREFIX=/install
	cmake --build .
	popd
fi

source ${emsdk_dir}/emsdk_env.sh
mkdir build
for topic in sources/*
do
	for example in topic/*
	do
		build_dir=build/$(basename ${topic})/$(basename $(example))
		mkdir -p ${build_dir}
		pushd ${build_dir}

		emcmake cmake -GNinja -DEMSCRIPTEN:Bool=true -DVTK_DIR=${vtk_dir}/build ${example}

		if [ $? -ne 0 ]
		then
			echo $(basename ${example}) >> ${repo}/doesntcompile.txt
		else
			cmake --build .
			if [ $? -ne 0 ]
			then
				echo $(basename ${example}) >> ${repo}/doesntcompile.txt
			fi
		fi

		popd
	done
done
