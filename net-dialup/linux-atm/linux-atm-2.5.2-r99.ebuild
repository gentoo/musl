# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils flag-o-matic libtool linux-info

DESCRIPTION="Tools for ATM"
HOMEPAGE="http://linux-atm.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="static-libs"

RDEPEND=""
DEPEND="virtual/yacc"

RESTRICT="test"

DOCS=( AUTHORS BUGS ChangeLog NEWS README THANKS )

CONFIG_CHECK="~ATM"

src_prepare() {
	epatch "${FILESDIR}"/${P}-headers.patch
	epatch "${FILESDIR}"/${P}-mask-on_exit.patch
	epatch "${FILESDIR}"/${P}-remove-SYS_poll-hack.patch

	sed -i '/#define _LINUX_NETDEVICE_H/d' \
		src/arpd/*.c || die "sed command on arpd/*.c files failed"

	elibtoolize
}

src_configure() {
	append-flags -fno-strict-aliasing

	econf $(use_enable static-libs static)
}

src_install() {
	default
	prune_libtool_files
	dodoc doc/README* doc/atm*
}
