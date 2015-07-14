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
	exec stc -V $swiftFilename $ticFilename
	# read in tic output and process it (remove boilerplate code)
	set fileId [open $ticFilename "r"]
	set ticOutput [read $fileId]
	close $fileId

	set finalTicOutput ""
	set lines [split $ticOutput "\n"]

	# remove all lines of code that start with any of these terms	
	set searchTerms [list "package" "namespace" "turbine::defaults" "turbine::defaults" "turbine::declare_custom_work_types" "turbine::init" "turbine::enable_read_refcount" "turbine::check_constants" "turbine::finalize" "turbine::start" "adlb::declare_struct_type" "#*"]
	set lineNumbersToRemove [list]
	set lineNumber 0
	# mark which lines of code start with these terms
	foreach line $lines {
	    foreach searchTerm $searchTerms {
		if {[ string match $searchTerm* $line ]} {
		    lappend lineNumbersToRemove $lineNumber
		    break
		}
	    }
	    set lineNumber [expr {$lineNumber+1}]
	}

	# now remove the marked lines
	# iterate over list backwards (so removing lines doesn't change line numbers ahead of current point)
	for {set i [expr {[llength $lineNumbersToRemove] - 1}]} {$i >= 0} {incr i -1} {
	    set index [lindex $lineNumbersToRemove $i]
	    set lines [lreplace $lines $index $index]
	}
	
	# append main function call to script
	lappend lines "swift:main\n"
	# now join it into one string
	set cleanTicOutput [join $lines \n]
	# write it to a file for debugging (the r in "tric" stands for REPL)	
	set fileId [open "tmp.tric" "w"]
    	puts -nonewline $fileId $cleanTicOutput
    
	
	# now eval the tric code
	eval $cleanTicOutput
    }

}
