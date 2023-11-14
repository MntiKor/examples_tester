import shutil
import glob

shutil.copyfile('CMakeLists_global.txt.template', 'pregen/CMakeLists.txt')
with open('pregen/CMakeLists.txt', 'r') as cmake:
    data = cmake.read()

subdirectories = []
for path in glob.glob('pregen/**/CMakeLists.txt', recursive=True):
    subdirectories.append('add_subdirectory(' + path.removeprefix('pregen/').removesuffix('CMakeLists.txt') + ')')
data = data.replace('XXX', '\n'.join(subdirectories))

with open('pregen/CMakeLists.txt', 'w') as cmake:
    cmake.write(data)
