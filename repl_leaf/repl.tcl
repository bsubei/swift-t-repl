package provide repl 0.0

package require turbine 0.6.0
namespace import turbine::*

namespace eval repl {

    proc start_repl {} {
	
	puts "Welcome to the extremely basic REPL turbine!"


	# keep taking user input until %END is entered
	set input [gets stdin]
	# store entire input here (concatenate it)
	set allInput ""

	while {[string compare $input "%END"] != 0} {
	    append allInput "$input\n" 
	    set input [gets stdin]	    
	}

	puts "finished!"
	puts "Attempting to run user input script:\n$allInput"

	# write input to swift file and compile it in STC
    	set swiftFilename "tmp.swift"
    	set fileId [open $swiftFilename "w"]
    	puts -nonewline $fileId $allInput
    	close $fileId
	puts "Wrote tmp file to: $swiftFilename. Calling STC on it."
	set ticFilename "tmp.tic"
	exec stc -c -O0 -V $swiftFilename $ticFilename
	# read in tic output
	set fileId [open $ticFilename "r"]
	set ticOutput [read $fileId]
	close $fileId

	# append main function call to script
	append ticOutput "\nswift:main\n"

	# write it to a file for debugging (the r in "tric" stands for REPL)	
	set fileId [open "tmp.tric" "w"]
	puts -nonewline $fileId $ticOutput
	close $fileId

	# now eval the tric code
	eval $cleanTicOutput
    }

}
