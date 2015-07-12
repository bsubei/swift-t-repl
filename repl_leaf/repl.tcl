package provide repl 0.0
namespace eval repl {

    proc start_repl {} {

	while "1" {
	    set input [gets stdin]
	    puts "$input"
	}

    }
}
