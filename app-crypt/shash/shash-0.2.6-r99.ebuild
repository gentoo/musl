# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/shash/shash-0.2.6-r1.ebuild,v 1.25 2014/01/18 05:39:58 vapier Exp $

inherit bash-completion eutils

DESCRIPTION="Generate or check digests or MACs of files"
HOMEPAGE="http://mcrypt.hellug.gr/shash/"
SRC_URI="ftp://mcrypt.hellug.gr/pub/mcrypt/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="static"

DEPEND=">=app-crypt/mhash-0.8.18-r1"
RDEPEND="${DEPEND}"

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}"/${PV}-manpage-fixes.patch
	epatch "${FILESDIR}"/${P}-binary-files.patch
	epatch "${FILESDIR}"/${P}-missing-includes.patch
}

src_compile() {
	econf $(use_enable static static-link) || die "econf failed"
	emake || die "emake failed"
}

src_install() {
	make install DESTDIR="${D}" || die "install failed"
	dodoc AUTHORS ChangeLog INSTALL NEWS doc/sample.shashrc doc/FORMAT
	dobashcompletion "${FILESDIR}"/shash.bash-completion ${PN}
}
