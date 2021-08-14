#!/bin/en bash
function system_info(){
	cat <<-EOF
	-h or --help	get usage 
	-t		get system time
	-d		get system disk information
	-m		get system memory information
	EOF
}
