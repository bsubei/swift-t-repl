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
    	set filename "tmp.swift"
    	set fileId [open $filename "w"]
    	puts -nonewline $fileId $allInput
    	close $fileId
    }

}
