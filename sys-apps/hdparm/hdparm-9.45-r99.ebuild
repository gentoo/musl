# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/hdparm/hdparm-9.45.ebuild,v 1.2 2015/06/02 11:38:26 zlogene Exp $

EAPI="4"

inherit toolchain-funcs flag-o-matic

DESCRIPTION="Utility to change hard drive performance parameters"
HOMEPAGE="http://sourceforge.net/projects/hdparm/"
SRC_URI="mirror://sourceforge/hdparm/${P}.tar.gz"

LICENSE="BSD GPL-2" # GPL-2 only
SLOT="0"
KEYWORDS="amd64 ~arm ~mips ~ppc ~x86"
IUSE="static"

src_prepare() {
	use static && append-ldflags -static
	sed -i \
		-e "/^CFLAGS/ s:-O2:${CFLAGS}:" \
		-e "/^LDFLAGS/ s:-s:${LDFLAGS}:" \
		Makefile || die "sed"
	epatch "${FILESDIR}"/${P}-musl.patch
}

src_compile() {
	emake STRIP=: CC="$(tc-getCC)"
}

src_install() {
	into /
	dosbin hdparm contrib/idectl

	newinitd "${FILESDIR}"/hdparm-init-8 hdparm
	newconfd "${FILESDIR}"/hdparm-conf.d.3 hdparm

	doman hdparm.8
	dodoc hdparm.lsm Changelog README.acoustic hdparm-sysconfig
	docinto wiper
	dodoc wiper/{README.txt,wiper.sh}
}
