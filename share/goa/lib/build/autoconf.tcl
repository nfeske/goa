
proc create_or_update_build_dir { } {

	mirror_source_dir_to_build_dir

	global build_dir cross_dev_prefix project_name project_dir
	global cppflags cflags cxxflags ldflags ldlibs

	# invoke configure script only once
	if {[file exists [file join $build_dir config.status]]} {
		return }

	set cmd { }

	lappend cmd "./configure"
	lappend cmd "--prefix" "/"
	lappend cmd "--host" x86_64-pc-elf
	lappend cmd "CPPFLAGS=$cppflags"
	lappend cmd "CFLAGS=$cflags"
	lappend cmd "CXXFLAGS=$cxxflags"
	lappend cmd "LDFLAGS=$ldflags $ldlibs"
	lappend cmd "LDLIBS=$ldlibs"
	lappend cmd "LIBS=$ldlibs"
	lappend cmd "CXX=${cross_dev_prefix}g++"
	lappend cmd "CC=${cross_dev_prefix}gcc"
	lappend cmd "STRIP=${cross_dev_prefix}strip"
	lappend cmd "RANLIB=${cross_dev_prefix}ranlib"

	# add project-specific arguments read from 'configure_args' file
	foreach arg [read_file_content_as_list [file join $project_dir configure_args]] {
		lappend cmd $arg }

	diag "create build directory via command:" {*}$cmd

	set orig_pwd [pwd]
	cd $build_dir

	if {[catch {exec -ignorestderr {*}$cmd | sed "s/^/\[$project_name:autoconf\] /" >@ stdout} msg]} {
		exit_with_error "build-directory creation via autoconf failed:\n" $msg }

	cd $orig_pwd
}


proc build { } {

	global build_dir verbose project_name jobs project_dir ldlibs

	set cmd { }

	# pass variables that are not fully handled by configure scripts
	lappend cmd make -C $build_dir
	lappend cmd "LDLIBS=$ldlibs"
	lappend cmd "DESTDIR=[file join $build_dir install]"
	lappend cmd "-j$jobs"

	if {$verbose == 0} {
		lappend cmd "-s" }

	# add project-specific arguments read from 'make_args' file
	foreach arg [read_file_content_as_list [file join $project_dir make_args]] {
		lappend cmd $arg }

	diag "build via command" {*}$cmd

	if {[catch {exec -ignorestderr {*}$cmd | sed "s/^/\[$project_name:make\] /" >@ stdout}]} {
		exit_with_error "build via make failed" }
}
