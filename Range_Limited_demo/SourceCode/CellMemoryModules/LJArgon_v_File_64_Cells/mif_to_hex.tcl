global quartus



if { 0 == [llength (args)] } {

    post_message "Usage: quartus_sh -t [info script] <file name pattern>"

} else {

    set file_pattern [lindex (args) 0]

    foreach mif_name [glob *.mif] {

    

        # Rename to .hex

        set rootname [file rootname ]

        set hex_name .hex

        

        if { [catch { qexec "[file join (binpath) mif2hex] 
             " } res] } {

            post_message -type error 

            break

        } else {

            post_message "Converted  to "

        }

    }

}
