package require fileutil

# set filenames [::fileutil::findByPattern "$file_path/xilinx_specific/" -glob {*.sv *.v}]
# foreach filename $filenames {
#     if {[file isfile $filename]} {
#         #set dirs_var([file dirname $filename])
#         vlog -v -incr -work work $defines $include_dir "$file_path$filename"
#     }
# }

set filenames [::fileutil::findByPattern "$file_path" -glob {*.sv *.v}]
foreach filename $filenames {
    if {[file isfile $filename]} {
        #set dirs_var([file dirname $filename])
        vlog -v -incr -work work $defines $include_dir "$file_path$filename"
    }
}