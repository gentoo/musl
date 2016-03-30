# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit bash-completion-r1 eutils

DESCRIPTION="Generate or check digests or MACs of files"
HOMEPAGE="http://mcrypt.hellug.gr/shash/"
SRC_URI="ftp://mcrypt.hellug.gr/pub/mcrypt/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="static"

DEPEND=">=app-crypt/mhash-0.8.18-r1"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${PV}-manpage-fixes.patch
	epatch "${FILESDIR}"/${P}-binary-files.patch
	epatch "${FILESDIR}"/${P}-missing-includes.patch
}

src_configure() {
	econf $(use_enable static static-link)
}

src_install() {
	emake install DESTDIR="${D}"
	dodoc AUTHORS ChangeLog INSTALL NEWS doc/sample.shashrc doc/FORMAT
	newbashcomp "${FILESDIR}"/shash.bash-completion ${PN}
}
