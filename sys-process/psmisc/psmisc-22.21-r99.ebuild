# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/psmisc/psmisc-22.21.ebuild,v 1.2 2014/01/18 03:51:41 vapier Exp $

EAPI="4"

inherit eutils

DESCRIPTION="A set of tools that use the proc filesystem"
HOMEPAGE="http://psmisc.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="ipv6 nls selinux X"

RDEPEND=">=sys-libs/ncurses-5.7-r7
	nls? ( virtual/libintl )
	selinux? ( sys-libs/libselinux )"
DEPEND="${RDEPEND}
	>=sys-devel/libtool-2.2.6b
	nls? ( sys-devel/gettext )"

DOCS="AUTHORS ChangeLog NEWS README"

src_prepare() {
	epatch "${FILESDIR}"/${P}-add-limits_h.patch
}

src_configure() {
	econf \
		$(use_enable selinux) \
		--disable-harden-flags \
		$(use_enable ipv6) \
		$(use_enable nls)
}

src_compile() {
	# peekfd is a fragile crap hack #330631
	nonfatal emake -C src peekfd || touch src/peekfd{.o,}
	emake
}

src_install() {
	default

	use X || rm -f "${ED}"/usr/bin/pstree.x11

	[[ -s ${ED}/usr/bin/peekfd ]] || rm -f "${ED}"/usr/bin/peekfd
	[[ -e ${ED}/usr/bin/peekfd ]] || rm -f "${ED}"/usr/share/man/man1/peekfd.1

	# fuser is needed by init.d scripts; use * wildcard for #458250
	dodir /bin
	mv "${ED}"/usr/bin/*fuser "${ED}"/bin || die
}
