# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils toolchain-funcs flag-o-matic

DESCRIPTION="Tool for creating compressed filesystem type squashfs"
HOMEPAGE="http://squashfs.sourceforge.net"
SRC_URI="mirror://sourceforge/squashfs/squashfs${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="+xz lzma lz4 lzo xattr"

RDEPEND="
	sys-libs/zlib
	!xz? ( !lzo? ( sys-libs/zlib ) )
	lz4? ( app-arch/lz4 )
	lzma? ( app-arch/xz-utils )
	lzo? ( dev-libs/lzo )
	xattr? ( sys-apps/attr )
	xz? ( app-arch/xz-utils )
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/squashfs${PV}/${PN}"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-4.2-missing-includes.patch
}

src_configure() {
	# set up make command line variables in EMAKE_SQUASHFS_CONF
	EMAKE_SQUASHFS_CONF=(
		$(usex lzma LZMA_XZ_SUPPORT=1 LZMA_XS_SUPPORT=0)
		$(usex lzo LZO_SUPPORT=1 LZO_SUPPORT=0)
		$(usex lz4 LZ4_SUPPORT=1 LZ4_SUPPORT=0)
		$(usex xattr XATTR_SUPPORT=1 XATTR_SUPPORT=0)
		$(usex xz XZ_SUPPORT=1 XZ_SUPPORT=0)
	)

	append-cppflags -DFNM_EXTMATCH=0
	tc-export CC
}

src_compile() {
	emake ${EMAKE_SQUASHFS_CONF[@]}
}

src_install() {
	dobin mksquashfs unsquashfs
	dodoc ../README
}
