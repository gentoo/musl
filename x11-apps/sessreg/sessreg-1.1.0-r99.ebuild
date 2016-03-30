# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils xorg-2

DESCRIPTION="manage utmp/wtmp entries for non-init clients"

KEYWORDS="amd64 arm ~mips ppc x86"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
	x11-proto/xproto"

src_prepare() {
	epatch "${FILESDIR}"/${P}-missing_path_wtmpx.patch
}
