Before use:
    Change the path value in Line 50: point to the related initialization files in the same folder (Use the ABSOLUTE PATH).
        Files affected:
            lut0_8.v    (c0_8.hex)
            lut1_8.v    (c1_8.hex)
            lut0_14.v   (c0_14.hex)
            lut1_14.v   (c1_14.hex)

To compile:
    source OpenCLCustomLib/gen_library.sh

To test:
    The provide test folder has a simple host and kernel code that calls the custom function.

To change table lookup entry:
    Matlab scripts are provided to generate the needed interpolation indexes.
