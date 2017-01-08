# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit autotools

DESCRIPTION="Implementation of fts(3) functions for musl libc"
HOMEPAGE="https://github.com/pullmoll/musl-fts"
SRC_URI="https://github.com/pullmoll/musl-fts/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="static-libs"

DEPEND="
	!sys-libs/glibc
	!sys-libs/uclibc
"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable static-libs static)
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die
	insinto /usr/lib/pkgconfig
	doins musl-fts.pc
}
