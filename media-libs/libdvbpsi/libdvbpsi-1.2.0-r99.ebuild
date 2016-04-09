# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=4

inherit eutils

DESCRIPTION="library for MPEG TS/DVB PSI tables decoding and generation"
HOMEPAGE="http://www.videolan.org/libdvbpsi"
SRC_URI="http://download.videolan.org/pub/${PN}/${PV}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="doc static-libs"

RDEPEND=""
DEPEND="
	doc? (
		app-doc/doxygen
		>=media-gfx/graphviz-2.26
	)" # Require recent enough graphviz wrt #181147

DOCS=( AUTHORS ChangeLog NEWS README )

src_prepare() {
	epatch ${FILESDIR}/${P}-musl.patch
	sed -e '/CFLAGS/s:-O2::' -e '/CFLAGS/s:-O6::' -e '/CFLAGS/s:-Werror::' -i configure || die
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		--enable-release
}

src_compile() {
	emake
	use doc && emake doc
}

src_install() {
	default
	use doc && dohtml doc/doxygen/html/*
	rm -f "${ED}"usr/lib*/${PN}.la
}
