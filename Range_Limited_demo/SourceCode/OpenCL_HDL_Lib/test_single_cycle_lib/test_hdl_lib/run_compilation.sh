# Compile library
cd ..
source gen_library.sh
cd test_hdl_lib
echo "Library generated!"

# Compile host
make
echo "Host file compiled!"

# Compile for kernel image
aoc -l ../RL_LJ_Evaluation.aoclib -L .. device/LJ.cl -o bin/LJ.aocx
