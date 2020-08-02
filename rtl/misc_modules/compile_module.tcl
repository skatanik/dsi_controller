package require fileutil

set filenames [::fileutil::findByPattern ./ -glob {*.sv *.v}]
foreach filename $filenames {
    if {[file isfile $filename]} {
        #set dirs_var([file dirname $filename])
        vlog -v -incr -work work $defines $include_dir $filename
    }
}