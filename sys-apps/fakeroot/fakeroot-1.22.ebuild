# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools flag-o-matic

DESCRIPTION="A fake root environment by means of LD_PRELOAD and SysV IPC (or TCP) trickery"
HOMEPAGE="https://packages.qa.debian.org/f/fakeroot.html"
SRC_URI="mirror://debian/pool/main/${PN:0:1}/${PN}/${P/-/_}.orig.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm arm64 ppc ppc64 x86"
IUSE="acl debug static-libs test"
RESTRICT="!test? ( test )"

DEPEND="
	sys-libs/libcap
	acl? ( sys-apps/acl )
	test? ( app-arch/sharutils )"

DOCS="AUTHORS BUGS DEBUG README doc/README.saving"

PATCHES=(
	"${FILESDIR}"/${PN}-1.19-no-acl_h.patch
	"${FILESDIR}"/${PN}-1.20.2-glibc-2.24.patch
	"${FILESDIR}"/${PN}-1.22-xstatjunk.patch
	"${FILESDIR}"/${PN}-1.22-no64.patch
)

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	export ac_cv_header_sys_acl_h=$(usex acl)

	use debug && append-cppflags "-DLIBFAKEROOT_DEBUGGING"
	econf \
		$(use_enable static-libs static)
}

src_install() {
	default
	find "${ED}" -name '*.la' -o -name '*.a' -delete || die
}
