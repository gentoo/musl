# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/procps/procps-3.3.9.ebuild,v 1.6 2014/05/14 18:16:01 ssuominen Exp $

EAPI="4"

inherit eutils toolchain-funcs flag-o-matic

DESCRIPTION="standard informational utilities and process-handling tools"
# http://packages.debian.org/sid/procps
HOMEPAGE="http://procps.sourceforge.net/ http://gitorious.org/procps"
# SRC_URI="mirror://debian/pool/main/p/${PN}/${PN}_${PV}.orig.tar.xz"
FEDORA_HASH="0980646fa25e0be58f7afb6b98f79d74"
SRC_URI="http://pkgs.fedoraproject.org/repo/pkgs/${PN}-ng/${PN}-ng-${PV}.tar.xz/${FEDORA_HASH}/${PN}-ng-${PV}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="+ncurses nls static-libs test unicode"

RDEPEND="ncurses? ( >=sys-libs/ncurses-5.7-r7[unicode?] )
	!<sys-apps/sysvinit-2.88-r6"
DEPEND="${RDEPEND}
	ncurses? ( virtual/pkgconfig )
	test? ( dev-util/dejagnu )"

S=${WORKDIR}/${PN}-ng-${PV}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-3.3.8-kill-neg-pid.patch
	epatch "${FILESDIR}"/${PN}-3.3.8-no-GLOB_TILDE.patch
	epatch "${FILESDIR}"/${P}-no-error_h.patch
	epatch "${FILESDIR}"/${P}-configure.patch
	autoreconf
}

src_configure() {
	use elibc_musl && append-cppflags -D_XOPEN_SOURCE_EXTENDED
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
