# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit xorg-2

DESCRIPTION="manage utmp/wtmp entries for non-init clients"

KEYWORDS="amd64 arm ia64 ~mips ppc ~sh sparc x86"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
	x11-proto/xproto"

PATCHES=(
	"${FILESDIR}"/${PN}-1.1.0-missing_path_wtmpx.patch
)
