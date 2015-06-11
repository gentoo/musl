# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/strace/strace-4.8.ebuild,v 1.5 2014/02/20 13:36:59 jer Exp $

EAPI="4"

inherit flag-o-matic eutils

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://strace.git.sourceforge.net/gitroot/strace/strace"
	inherit git-2 autotools
else
	SRC_URI="mirror://sourceforge/${PN}/${P}.tar.xz"
	KEYWORDS="amd64 arm ~mips ppc x86"
fi

DESCRIPTION="A useful diagnostic, instructional, and debugging tool"
HOMEPAGE="http://sourceforge.net/projects/strace/"

LICENSE="BSD"
SLOT="0"
IUSE="aio +perl static"

# strace only uses the header from libaio to decode structs
DEPEND="aio? ( >=dev-libs/libaio-0.3.106 )
	sys-kernel/linux-headers"
RDEPEND=""

src_prepare() {
	if epatch_user || [[ ! -e configure ]] ; then
		# git generation
		eautoreconf
		[[ ! -e CREDITS ]] && cp CREDITS{.in,}
	fi

	epatch ${FILESDIR}/${P}-musl.patch
	export ac_cv_have_long_long_off_t=yes

	filter-lfs-flags # configure handles this sanely
	use static && append-ldflags -static

	export ac_cv_header_libaio_h=$(usex aio)
}

src_install() {
	default
	use perl || rm "${ED}"/usr/bin/strace-graph
	dodoc CREDITS
}
