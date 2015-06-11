# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/boehm-gc/boehm-gc-7.2e.ebuild,v 1.9 2014/01/18 20:05:46 ago Exp $

EAPI=5

inherit autotools eutils flag-o-matic

MY_P="gc-${PV/_/}"

DESCRIPTION="The Boehm-Demers-Weiser conservative garbage collector"
HOMEPAGE="http://www.hpl.hp.com/personal/Hans_Boehm/gc/"
SRC_URI="http://www.hpl.hp.com/personal/Hans_Boehm/gc/gc_source/${MY_P}.tar.gz"

LICENSE="boehm-gc"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="cxx static-libs threads"

DEPEND=">=dev-libs/libatomic_ops-7.2
	virtual/pkgconfig"

S="${WORKDIR}/${MY_P/e}"

src_prepare() {
	rm -r libatomic_ops || die

	append-cppflags -DNO_GETCONTEXT

	epatch "${FILESDIR}"/${P}-automake-1.13.patch
	epatch "${FILESDIR}"/${PN}-7.2e-os_dep.patch
	eautoreconf
}

src_configure() {
	local config=(
		--with-libatomic-ops
		$(use_enable cxx cplusplus)
		$(use_enable static-libs static)
		$(use threads || echo --disable-threads)
	)
	econf "${config[@]}"
}

src_install() {
	default

	rm -r "${ED}"/usr/share/gc || die

	# dist_noinst_HEADERS
	insinto /usr/include/gc
	doins include/{cord.h,ec.h,javaxfc.h}
	insinto /usr/include/gc/private
	doins include/private/*.h

	dodoc README.QUICK doc/README{.environment,.linux,.macros} doc/barrett_diagram
	dohtml doc/*.html
	newman doc/gc.man GC_malloc.1

	use static-libs || prune_libtool_files #457872
}
