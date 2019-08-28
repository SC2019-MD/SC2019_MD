# Compile host
make
echo "Host file compiled!"

# Compile for kernel image
aoc device/LJ.cl -o bin/LJ.aocx
