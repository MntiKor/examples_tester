#!/bin/bash

repo=$PWD

emsdk_dir=${repo}/emsdk

if [ ! -d ${emsdk_dir} ]
then
	git clone https://github.com/emscripten-core/emsdk.git
	${emsdk_dir}/emsdk install latest
	${emsdk_dir}/emsdk activate latest
	source ${emsdk_dir}/emsdk_env.sh
	embuilder build sdl2
fi

vtk_dir=${repo}/vtk

if [ ! -d ${vtk_dir} ]
then
	git clone https://gitlab.kitware.com/astucky/vtk.git
	mkdir -p vtk/build
	pushd vtk/build
	git checkout hdf5-emsctipten-compatibility
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
mkdir pregen
for topic in sources/*
do
	topic_name=$(basename ${topic})
	./GenerateExamplesWASM.sh ${vtk_dir} ${topic} pregen/${topic_name}
	for example in pregen/${topic_name}/*
	do
		example_name=$(basename ${example})
		build_dir=build/${topic_name}/${example_name}
		mkdir -p ${build_dir}

		emcmake cmake -GNinja -DEMSCRIPTEN:Bool=true -DVTK_DIR=${vtk_dir}/build -S ${example} -B ${build_dir}

		if [ $? -ne 0 ]
		then
			echo ${example_name} >> ${repo}/doesntcompile.txt
		else
			cmake --build ${build_dir}
			if [ $? -ne 0 ]
			then
				echo ${example_name} >> ${repo}/doesntcompile.txt
			else
				aws s3api put-object \
					--bucket vtk-wasm-examples \
					--key ${example_name}/${example_name}.wasm \
					--body ${build_dir}/${example_name}.wasm \
					--acl public-read \
					--content-type application/wasm
				aws s3api put-object \
					--bucket vtk-wasm-examples \
					--key ${example_name}/${example_name}.js \
					--body ${build_dir}/${example_name}.js \
					--acl public-read
				aws s3api put-object \
					--bucket vtk-wasm-examples \
					--key ${example_name}/index.html \
					--body ${build_dir}/index.html \
					--acl public-read
			fi
		fi
	done
done
