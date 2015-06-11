# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/squashfs-tools/squashfs-tools-4.2.ebuild,v 1.12 2014/01/18 11:37:50 vapier Exp $

EAPI="2"

inherit eutils toolchain-funcs flag-o-matic

MY_PV=${PV}
DESCRIPTION="Tool for creating compressed filesystem type squashfs"
HOMEPAGE="http://squashfs.sourceforge.net"
SRC_URI="mirror://sourceforge/squashfs/squashfs${MY_PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="+xz lzo xattr"

RDEPEND="
	sys-libs/zlib
	xz? ( app-arch/xz-utils )
	lzo? ( dev-libs/lzo )
	!xz? ( !lzo? ( sys-libs/zlib ) )
	xattr? ( sys-apps/attr )"
DEPEND="${RDEPEND}"

S=${WORKDIR}/squashfs${MY_PV}/squashfs-tools

use_sed() {
	local u=$1 s="${2:-`echo $1 | tr '[:lower:]' '[:upper:]'`}_SUPPORT"
	printf '/^#?%s =/%s\n' "${s}" \
		"$( use $u && echo s:.*:${s} = 1: || echo d )"
}

src_prepare() {
	epatch ${FILESDIR}/${P}-missing-includes.patch
}

src_configure() {
	append-cppflags -DFNM_EXTMATCH=0
	tc-export CC
	sed -i -r \
		-e "$(use_sed xz XZ)" \
		-e "$(use_sed lzo)" \
		-e "$(use_sed xattr)" \
		Makefile || die
}

src_install() {
	dobin mksquashfs unsquashfs || die
	cd ..
	dodoc README ACKNOWLEDGEMENTS CHANGES PERFORMANCE.README || die
}

pkg_postinst() {
	ewarn "This version of mksquashfs requires a 2.6.29 kernel or better"
	use xz &&
		ewarn "XZ support requires a 2.6.38 kernel or better"
}
