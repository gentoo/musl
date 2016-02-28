# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils flag-o-matic toolchain-funcs

MY_P="${PN}-${PV/_pre/-PR}"

DESCRIPTION="Identify/delete duplicate files residing within specified directories"
HOMEPAGE="https://github.com/adrianlopezroche/fdupes https://code.google.com/p/fdupes/"
SRC_URI="
	https://fdupes.googlecode.com/files/${P}.tar.gz
	https://github.com/adrianlopezroche/${PN}/archive/${P}.tar.gz
	"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE=""

S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch \
		"${FILESDIR}"/${P}-makefile.patch \
		"${FILESDIR}"/${PN}-1.50_pre2-compare-file.patch \
		"${FILESDIR}"/${PN}-1.50_pre2-typo.patch \
		"${FILESDIR}"/${P}-remove-stdin-lvalue.patch

	append-lfs-flags
}

src_compile() {
	emake CC=$(tc-getCC)
}

src_install() {
	dobin fdupes
	doman fdupes.1
	dodoc CHANGES CONTRIBUTORS README TODO
}
