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

	set finalTicOutput ""
	set data [split $ticOutput "\n"]
	# regex extracts names of procs (functions) from ticOutput
	set regResult [regexp -all -inline {\s*proc\s+([\w:]+)\s*\{} $ticOutput ]    	
	# extracts unique names from regexp result
	foreach {tmp procName} $regResult {
	    puts "found proc name: $procName"
 	}
	
	# regex extracts insides of a swift:main function
	if [ regexp {\s*proc\s+swift:main\s*\{[^*]*\}\s*\{([^*\}]*)\}} $ticOutput -> procCode] then {
	    puts "code inside main proc: $procCode"
	    # TODO run what's inside main function
	    # TODO if calls to any proc
		# include definition of proc
	}


    }

}
