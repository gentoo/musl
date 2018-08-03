# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4

AUTOTOOLS_PRUNE_LIBTOOL_FILES=all

inherit autotools-multilib

DESCRIPTION="library that provides direct access to the IEEE 1394 bus"
HOMEPAGE="https://ieee1394.wiki.kernel.org/"
SRC_URI="mirror://kernel/linux/libs/ieee1394/${P}.tar.xz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~ppc ~x86"
IUSE="static-libs"

DEPEND="app-arch/xz-utils"
RDEPEND=""

src_prepare() {
	epatch "${FILESDIR}"/${P}-replace__uint32.patch
}
