# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils autotools

DESCRIPTION="Async Resolver Library from OpenBSD/OpenSMTPD"
HOMEPAGE="https://github.com/OpenSMTPD/libasr"
SRC_URI="https://www.opensmtpd.org/archives/${P}.tar.gz"

LICENSE="ISC BSD BSD-1 BSD-2 BSD-4"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE=""

DEPEND="dev-libs/libbsd"
RDEPEND="${DEPEND}"

src_prepare(){
	# Patch from https://git.alpinelinux.org/cgit/aports/plain/main/libasr/0002-Replace-missing-res_randomid-with-the-more-secure-ar.patch, changed LIBS to incluse -lbsd
	epatch "${FILESDIR}/0002-Replace-missing-res_randomid-with-the-more-secure-ar.patch"
	default
	eautoreconf
}
