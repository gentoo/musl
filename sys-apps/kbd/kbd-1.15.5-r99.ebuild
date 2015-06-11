# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/kbd/kbd-1.15.5-r1.ebuild,v 1.6 2014/01/09 13:37:41 polynomial-c Exp $

EAPI="4"

inherit eutils

DESCRIPTION="Keyboard and console utilities"
HOMEPAGE="http://freshmeat.net/projects/kbd/"
SRC_URI="ftp://ftp.altlinux.org/pub/people/legion/kbd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="nls pam"

RDEPEND="pam? ( virtual/pam )"
DEPEND="${RDEPEND}"

src_unpack() {
	default
	cd "${S}"

	# broken file ... upstream git punted it
	rm po/es.po

	# Rename conflicting keymaps to have unique names, bug #293228
	cd "${S}"/data/keymaps/i386
	mv dvorak/no.map dvorak/no-dvorak.map
	mv fgGIod/trf.map fgGIod/trf-fgGIod.map
	mv olpc/es.map olpc/es-olpc.map
	mv olpc/pt.map olpc/pt-olpc.map
	mv qwerty/cz.map qwerty/cz-qwerty.map
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-loadkeys-parse.patch #447440
	epatch "${FILESDIR}"/${P}-musl-headers-error.patch
	epatch "${FILESDIR}"/${P}-fix-struct_winsize-collision.patch
}

src_configure() {
	econf \
		$(use_enable nls) \
		$(use_enable pam vlock)
}

src_install() {
	default
	dohtml doc/*.html
}
