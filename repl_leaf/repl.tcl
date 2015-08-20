package provide repl 0.0

package require turbine 0.6.0
namespace import turbine::*

namespace eval repl {

  set ignores [list "u:HARD" "u:SOFT" "u:RANK" "u:NODE"]

  proc start_repl {} {

    # puts "Welcome to the extremely basic REPL turbine"
    while {1} {
      # puts "Please enter your swift script. Use %HELP for help."

      # create non-blocking socket connection
      set sock [ socket localhost 12345 ] 
      fconfigure $sock -blocking 0 -buffering line

      # receive from socket
      set allInput ""
      set input [gets $sock]
      # keep reading until you get something
      while {[string length $input] <= 0} {
        set input [gets $sock]
      }
      # as long as there's more input, keep reading from socket
      while {![fblocked $sock]} {
        append allInput "$input\n"
        set input [gets $sock]
      }
      append allInput "$input\n"


      # append extern statements to user's scripts
      set allInput "[externStatements]\n$allInput"
      puts "Running user input:\n$allInput"

      # write input to swift file and compile it in STC
      set swiftFilename "tmp.swift"
      set fileId [open $swiftFilename "w"]
      puts -nonewline $fileId $allInput
      close $fileId
      # puts "Wrote tmp file to: $swiftFilename. Calling STC on it."
      set ticFilename "tmp.tic"
      exec stc -c -O0 -V $swiftFilename $ticFilename
      # read in tic output
      set fileId [open $ticFilename "r"]
      set ticOutput [read $fileId]
      close $fileId


      # TODO must redirect stdout from turbine to this socket connection

      # eval the tic code definitions on all ranks and run worker_barrier
      loadTic [list $ticOutput]

      # now execute the main from the tic for this rank only
      uplevel #0 swift:main


      # # output globals dictionary back to jupyter kernel
      # puts $sock "{"
      # set globals [turbine::get_globals_map]
      # dict for {varname id} $globals {
      #   # ignore variables defined in $ignores
      #   if {[lsearch ${repl::ignores} $varname] >= 0} {
      #     continue
      #   }
      #   puts $sock "$varname:$id"
      # }
      # puts $sock "}"

      # DEBUG: output all swift code you ran
      puts $sock $allInput

      close $sock
    }
  }

  # Loads (evals) the tic code (a list) on the current worker (includes proc definitions
  # and calls to create global variables). Called on worker 0 first, in which case it
  # puts tasks to call this proc to other workers.
  # 
  # The tic code contains the commands to create a single copy of global
  # variables, which is sent to other workers.
  proc loadTic { tic_code } { 
    # eval tic code (now globals and proc defs are available to this rank)
    uplevel #0 {*}$tic_code

    # if rank 0 (only REPL worker)
    if {[adlb::rank] == 0} {

      set numWorkers [ adlb::workers ]
      # for all workers (start at 1, skip this current one)
      for {set worker 1} {$worker < $numWorkers} {incr worker} {
        # send targeted task to worker with payload "loadTic tic_code"
        set putAction [list "repl::loadTic"]
        lappend putAction $tic_code        
        adlb::put $worker ${turbine::WORK_TASK} $putAction ::turbine::INT_MAX 1 HARD
      }
    }
    adlb::worker_barrier
  }

  # returns extern statements for each global variable defined in earlier scripts
  proc externStatements {} {
    set externs ""
    set globals [turbine::get_globals_map]
    dict for {varname id} $globals {
      # ignore variables defined in $ignores
      if {[lsearch ${repl::ignores} $varname] >= 0} {
        continue
      }
      # take substring (cut out "u:" from u:<varname>)
      set name [string range $varname 2 end]
      append externs "extern int $name;\n"
    }

    return $externs
  }

  # looks up the global variable ids from globals_map, checks if they exist,
  # then retrieves their values and prints them out.
  proc printGlobals {} {
    set globals [turbine::get_globals_map]
    dict for {varname id} $globals {
      if {[adlb::exists $id]} {
        puts "variable $varname has id $id and value [adlb::retrieve $id]"
        } else {
          puts "variable $varname has id $id but is still not assigned a value"
        }
    }

  }

  proc printHelp {} {
    puts "Enter your swift script, followed by %END on a separate line."
    puts "REPL commands:"
    puts "%ls: print out global variable names, ids, and values"
    puts "%EXIT: exit this REPL program"
    puts "%END: indicate the end of your swift script"
  }

}
