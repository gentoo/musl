# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DIST_AUTHOR=MZSANFORD
DIST_VERSION=0.61
inherit perl-module

DESCRIPTION="Access CPU info. number, etc on Win and UNIX"

SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE=""

PATCHES=( "${FILESDIR}"/${PN}-${DIST_VERSION}-fix-unistd-h.patch )
