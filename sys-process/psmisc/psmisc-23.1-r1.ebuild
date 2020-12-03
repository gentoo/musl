# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="A set of tools that use the proc filesystem"
HOMEPAGE="http://psmisc.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~mips ppc ppc64 x86"
IUSE="ipv6 nls selinux X"

RDEPEND=">=sys-libs/ncurses-5.7-r7:0=
	nls? ( virtual/libintl )
	selinux? ( sys-libs/libselinux )"
DEPEND="${RDEPEND}
	>=sys-devel/libtool-2.2.6b
	nls? ( sys-devel/gettext )"

DOCS=( AUTHORS ChangeLog NEWS README )

PATCHES=(
	"${FILESDIR}"/${P}-include_limits.patch 
)

src_configure() {
	local myeconfargs=(
		$(use_enable selinux)
		--disable-harden-flags
		$(use_enable ipv6)
		$(use_enable nls)
	)
	econf "${myeconfargs[@]}"
}

src_compile() {
	emake
}

src_install() {
	default

	use X || rm -f "${ED%/}"/usr/bin/pstree.x11

	# fuser is needed by init.d scripts; use * wildcard for #458250
	dodir /bin
	mv "${ED%/}"/usr/bin/*fuser "${ED%/}"/bin || die
}
