#!/bin/bash

. /etc/init.d/functions.sh

if [[ $# -eq 0 || $# -gt 2 ]] ; then
	exec echo "Usage: $0 <version> [netpbm svn root]"
fi

PN=netpbm
PV=$1
P=${PN}-${PV}

SVN_ROOT=${2:-/usr/local/src}

T=/tmp

maint_pkg_create() {
	local base="/usr/local/src"
	local srcdir="${base}/netpbm/release_number"
	local htmldir="${base}/netpbm/userguide"
	if [[ -d ${srcdir} ]] ; then
		cd "${T}" || die

		rm -rf ${P}

		ebegin "Exporting ${srcdir}/${PV} to ${P}"
		svn export -q "${srcdir}/${PV}" ${P}
		eend $? || return 1

		ebegin "Exporting ${htmldir} to ${P}/userguide"
		svn export -q "${htmldir}" ${P}/userguide
		eend $? || return 1

		ebegin "Generating manpages from html"
		(cd "${P}/userguide" && ../buildtools/makeman *.html)
		eend $? || return 1

		ebegin "Creating ${P}.tar.xz"
		tar cf - ${P} | xz > ${P}.tar.xz
		eend $?

		einfo "Tarball now ready at: ${T}/${P}.tar.xz"
	else
		einfo "You need to run:"
		einfo " cd ${base}"
		einfo " svn co https://netpbm.svn.sourceforge.net/svnroot/netpbm"
		die "need svn checkout dir"
	fi
}
maint_pkg_create
