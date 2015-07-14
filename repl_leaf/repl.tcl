package provide repl 0.0

package require turbine 0.6.0
namespace import turbine::*

namespace eval repl {

    proc start_repl {} {
	
	puts "Welcome to the extremely basic REPL turbine!"


	# keep taking user input until %END is entered
	set input [gets stdin]
	puts "user input: $input"
	# store entire input here (concatenate it)
	set allInput ""

	while {[string compare $input "%END"] != 0} {
	    set allInput [concat $allInput $input]	    
	    set input [gets stdin]	    
	    puts "user input: $input" 
	}

	puts "finished!"
	puts "allInput: $allInput"

	# write input to swift file and compile it in STC
    	set swiftFilename "tmp.swift"
    	set fileId [open $swiftFilename "w"]
    	puts -nonewline $fileId $allInput
    	close $fileId
	puts "Wrote tmp file to: $swiftFilename. Calling STC on it."
	set ticFilename "tmp.tic"
	exec stc -V $swiftFilename $ticFilename
	# read in tic output and process it (remove boilerplate code)
	set fileId [open $ticFilename "r"]
	set ticOutput [read $fileId]
	close $fileId
    }

}
