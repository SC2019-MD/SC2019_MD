# Compile library
#cd ..
#source gen_library.sh
#cd test
#echo "Library generated!"

# Compile host
make
echo "Host file compiled!"

# Compile for emulation
aoc -march=emulator device/LJ.cl -o bin/LJ.aocx
echo "Emulation file compiled!"

# Run emulation
env CL_CONTEXT_EMULATOR_DEVICE_INTELFPGA=1 ./bin/host
echo "Emulation done!"