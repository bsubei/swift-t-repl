# Purpose
This swift script is a prototype to try to run a REPL-like user-input environment within Swift/T. It's currently being implemented as a Swift leaf function (calls a Tcl script).

# How to run Tcl leaf function from Swift/T
- First, write the Swift leaf function (merely calls the Tcl function). I already did this in file named repl.swift.
- Write the Tcl function definition (called start\_repl) and put it in the package namespace (already done in repl.tcl).
- Run `tclsh make-package.tcl > pkgIndex.tcl` to create a Tcl package (already done).
- Add the path to this folder to TCLLIBPATH environment variable (to call it from Tcl).
- Also add the path to this folder to the SWIFT\_PATH environment variable.
- In your swift script, import the Tcl package (called repl here), and call the function (called repl\_tcl, already done in repl\leaf.swift).
- To compile the swift script, use `stc -r $PWD repl_leaf.swift`, then run it in turbine.
