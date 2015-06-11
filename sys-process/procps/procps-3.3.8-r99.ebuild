# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/procps/procps-3.3.8-r1.ebuild,v 1.10 2013/12/26 14:41:10 maekke Exp $

EAPI="4"

inherit eutils toolchain-funcs flag-o-matic

DESCRIPTION="standard informational utilities and process-handling tools"
# http://packages.debian.org/sid/procps
HOMEPAGE="http://procps.sourceforge.net/ http://gitorious.org/procps"
# SRC_URI="mirror://debian/pool/main/p/${PN}/${PN}_${PV}.orig.tar.xz"
FEDORA_HASH="aecbeeda2ab308f8d09dddcb4cb9a572"
SRC_URI="http://pkgs.fedoraproject.org/repo/pkgs/${PN}-ng/${PN}-ng-${PV}.tar.xz/${FEDORA_HASH}/${PN}-ng-${PV}.tar.xz
	https://gitorious.org/${PN}/${PN}/commit/ce5e995921e770bfcda25e42fe090aeccdbf1291.patch -> ${P}-respect_epipe_in_fileutils.patch"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="+ncurses nls static-libs unicode"

RDEPEND="ncurses? ( >=sys-libs/ncurses-5.7-r7[unicode?] )"
DEPEND="${RDEPEND}
	ncurses? ( virtual/pkgconfig )
	test? ( dev-util/dejagnu )"

S=${WORKDIR}/${PN}-ng-${PV}

src_prepare() {
	epatch "${FILESDIR}"/${P}-kill-neg-pid.patch \
		"${DISTDIR}"/${P}-respect_epipe_in_fileutils.patch \
		"${FILESDIR}"/${P}-no-error_h.patch \
		"${FILESDIR}"/${P}-no-GLOB_TILDE.patch
}

src_configure() {
	use elibc_musl && export ac_cv_search_dlopen=
	use elibc_musl && append-cflags -D_XOPEN_SOURCE_EXTENDED
	econf \
		--exec-prefix="${EPREFIX}" \
		--docdir='$(datarootdir)'/doc/${PF} \
		$(use_with ncurses) \
		$(use_enable nls) \
		$(use_enable static-libs static) \
		$(use_enable unicode watch8bit)
}

src_install() {
	default
#	dodoc sysctl.conf

	# The configure script is completely whacked in the head
	mv "${ED}"/lib* "${ED}"/usr/ || die
	gen_usr_ldscript -a procps
	prune_libtool_files
}
