# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/liblockfile/liblockfile-1.09.ebuild,v 1.16 2014/01/08 06:42:31 vapier Exp $

EAPI=4

inherit eutils multilib autotools user

DESCRIPTION="Implements functions designed to lock the standard mailboxes"
HOMEPAGE="http://www.debian.org/"
SRC_URI="mirror://debian/pool/main/libl/${PN}/${PN}_${PV}.orig.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE=""

pkg_setup() {
	enewgroup mail 12
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.06-respectflags.patch
	epatch "${FILESDIR}"/${PN}-1.09-no-ldconfig.patch
	epatch "${FILESDIR}"/${PN}-orphan-file.patch

	# I don't feel like making the Makefile portable
	[[ ${CHOST} == *-darwin* ]] \
		&& cp "${FILESDIR}"/Makefile.Darwin.in Makefile.in

	eautoreconf
}

src_configure() {
	local grp=mail
	if use prefix ; then
		# we never want to use LDCONFIG
		export LDCONFIG=${EPREFIX}/bin/true
		# in unprivileged installs this is "mail"
		grp=$(id -g)
	fi
	econf --with-mailgroup=${grp} --enable-shared
}

src_install() {
	dodir /usr/{bin,include,$(get_libdir)} /usr/share/man/{man1,man3}
	emake ROOT="${D}" install
	dodoc README Changelog
}
