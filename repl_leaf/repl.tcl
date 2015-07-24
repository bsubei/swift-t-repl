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

    # eval the tic code definitions on all ranks and run worker_barrier
    loadTic [list $ticOutput]

    # now execute the main from the tic for this rank only
    uplevel #0 swift:main
  }


  # TODO multiple copies of variables are created, one in each worker. Need to fix
  # this soon. Only one copy should be created, and then the other workers
  # should access the variables using the globals_map
  # But so far, putting tasks to workers works.
  proc loadTic { tic_code } { 
      # eval tic code (now globals and proc defs are available to this rank)
      uplevel #0 {*}$tic_code

      # if rank 0 (only REPL loop)
      if {[adlb::rank] == 0} {

        set numWorkers [ adlb::workers ]
        puts "numWorkers: $numWorkers"
        # for all workers (start at 1, skip this current one)
        for {set worker 1} {$worker < $numWorkers} {incr worker} {
          # # set max priority
          # send targeted task to worker with payload "loadTic tic_code"
          set putAction [list "repl::loadTic"]
          lappend putAction $tic_code
          adlb::put $worker ${turbine::WORK_TASK} $putAction 0 1 HARD
        }
      }
      puts "rank: [adlb::rank] done"
      adlb::worker_barrier
    }



    # rank 0 (REPL loop) compiles user input into tic (only contains 
    # proc definitions and global var assignments). Then, it calls loadTic
    # on it. This spawns tasks for all other workers to, so they all have the variable
    # and proc definitions (nothing executed, though, on any of the ranks). Once they
    # all reach the barrier, rank 0 (REPL) executes swift:main and carries on with
    # any function calls.

    # The only problem is: user can no longer interactively start tasks and then start
    # more until the other tasks (workers) are finished, unless we set the loadTic targeted
    # tasks to a very high priority (in which case, the definitions, such as swift:main or
    # globals may be overwritten).



}
