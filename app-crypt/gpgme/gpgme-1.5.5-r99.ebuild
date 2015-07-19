# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/gpgme/gpgme-1.5.5.ebuild,v 1.6 2015/07/07 05:28:00 jer Exp $

EAPI="5"

inherit eutils libtool

DESCRIPTION="GnuPG Made Easy is a library for making GnuPG easier to use"
HOMEPAGE="http://www.gnupg.org/related_software/gpgme"
SRC_URI="mirror://gnupg/gpgme/${P}.tar.bz2"

LICENSE="GPL-2 LGPL-2.1"
SLOT="1/11" # subslot = soname major version
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="common-lisp static-libs"

DEPEND="app-crypt/gnupg
	>=dev-libs/libassuan-2.0.2
	>=dev-libs/libgpg-error-1.11"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FIELSDIR}"/${P}-error_t-provided-by-argp_h.patch
	epatch "${FILESDIR}"/${PN}-1.1.8-et_EE.patch
	elibtoolize
}

src_configure() {
	econf \
		--includedir="${EPREFIX}/usr/include/gpgme" \
		$(use_enable static-libs static)
}

src_install() {
	default
	prune_libtool_files

	if ! use common-lisp; then
		rm -fr "${ED}usr/share/common-lisp"
	fi
}
