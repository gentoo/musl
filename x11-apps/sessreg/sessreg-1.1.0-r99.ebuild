# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/sessreg/sessreg-1.1.0.ebuild,v 1.11 2015/03/14 13:57:53 maekke Exp $

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
