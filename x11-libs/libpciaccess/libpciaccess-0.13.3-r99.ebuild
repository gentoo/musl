# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libpciaccess/libpciaccess-0.13.3.ebuild,v 1.4 2015/02/20 11:18:03 ago Exp $

EAPI=5

XORG_MULTILIB=yes
inherit xorg-2

DESCRIPTION="Library providing generic access to the PCI bus and devices"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="minimal zlib"

DEPEND="!<x11-base/xorg-server-1.5
	zlib? (	>=sys-libs/zlib-1.2.8-r1:=[${MULTILIB_USEDEP}] )"
RDEPEND="${DEPEND}
	sys-apps/hwids"

PATCHES=(
	"${FILESDIR}"/${PN}-0.13.2-limits.patch
	"${FILESDIR}"/${PN}-0.13.2-arm.patch
)

pkg_setup() {
	xorg-2_pkg_setup

	XORG_CONFIGURE_OPTIONS=(
		"$(use_with zlib)"
		"--with-pciids-path=${EPREFIX}/usr/share/misc"
	)
}

multilib_src_install() {
	default

	if multilib_is_native_abi; then
		dodir /usr/bin
		${BASH} libtool --mode=install "$(type -P install)" -c scanpci/scanpci "${ED}"/usr/bin || die
	fi
}
