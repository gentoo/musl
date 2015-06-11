# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/dosfstools/dosfstools-3.0.27.ebuild,v 1.1 2015/04/03 07:05:29 vapier Exp $

EAPI="5"

inherit toolchain-funcs flag-o-matic eutils

DESCRIPTION="DOS filesystem tools - provides mkdosfs, mkfs.msdos, mkfs.vfat"
HOMEPAGE="http://www.daniel-baumann.ch/software/dosfstools/"
SRC_URI="https://github.com/dosfstools/dosfstools/releases/download/v${PV}/${P}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 ~arm ~mips ~ppc ~x86"
RESTRICT="test" # there is no test target #239071

src_prepare() {
	sed -i \
		-e "/^PREFIX/s:=.*:= ${EPREFIX}/usr:" \
		-e '/^OPTFLAGS/d' \
		-e '/^DEBUGFLAGS/d' \
		-e "/\$(DOCDIR)/s:${PN}:${PF}:" \
		Makefile || die
	epatch "${FILESDIR}"/${PN}-3.0.27-Fix-format-string-in-check.c.patch
	epatch "${FILESDIR}"/${PN}-3.0.28-fix_build_with_musl.patch
	append-lfs-flags
	tc-export CC
}
