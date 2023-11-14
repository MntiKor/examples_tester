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
else
	source ${emsdk_dir}/emsdk_env.sh
fi

vtk_dir=${repo}/vtk

if [ ! -d ${vtk_dir} ]
then
	git clone --depth 1 https://gitlab.kitware.com/vtk/vtk.git
	mkdir -p vtk/build
	pushd vtk/build
	emcmake cmake \
		-S .. \
		-B . \
		-GNinja \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_BUILD_TYPE:STRING=Release \
		-DVTK_ENABLE_LOGGING:BOOL=OFF \
		-DVTK_ENABLE_WRAPPING:BOOL=OFF \
		-DVTK_MODULE_ENABLE_VTK_cli11:STRING=YES \
		-DVTK_MODULE_ENABLE_VTK_RenderingLICOpenGL2:STRING=DONT_WANT \
		-DVTK_MODULE_ENABLE_VTK_RenderingCellGrid:STRING=NO \
		-DVTK_BUILD_TESTING=ON \
		-DCMAKE_INSTALL_PREFIX=/install
	cmake --build .
	popd
fi
mkdir build
mkdir pregen
for topic in sources/*
do
	topic_name=$(basename ${topic})
	./GenerateExamplesWASM.sh ${vtk_dir} ${topic} pregen/${topic_name}
done

python3 GenerateSuperCMake.py
emcmake cmake -GNinja -DEMSCRIPTEN:Bool=true -DVTK_DIR=${vtk_dir}/build -DDEBUGINFO=NONE -S pregen -B build
cmake --build build

for topic in build/*
do
	for example in ${topic}/*
	do
		example_name=$(basename ${example})
		gzip ${example}/${example_name}.wasm
		aws s3api put-object \
			--bucket vtk-wasm-examples \
			--key ${example_name}/${example_name}.wasm \
			--body ${example}/${example_name}.wasm.gz \
			--content-encoding gzip \
			--acl public-read \
			--content-type application/wasm
		gzip ${example}/${example_name}.js
		aws s3api put-object \
			--bucket vtk-wasm-examples \
			--key ${example_name}/${example_name}.js \
			--body ${example}/${example_name}.js.gz \
			--content-encoding gzip \
			--acl public-read
		gzip ${example}/index.html
		aws s3api put-object \
			--bucket vtk-wasm-examples \
			--key ${example_name}/index.html \
			--body ${example}/index.html.gz \
			--content-encoding gzip \
			--acl public-read
	done
done
