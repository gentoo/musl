# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

DESCRIPTION="ldconfig for musl in Gentoo"
HOMEPAGE="http://dev.gentoo.org/~blueness"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
#KEYWORDS="~amd64"
KEYWORDS=""
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

pkg_preinst () {
	use elibc_musl || die "This package only works on a musl system"
}

src_unpack () {
	mkdir -p ${P}
	cp "${FILESDIR}"/${P} ${P}/${PN}
}

src_install () {
	into /
	dosbin ${PN}
	echo 'LDPATH="include ld.so.conf.d/*.conf"' > "${T}"/00musl
	doenvd "${T}"/00musl || die
}
