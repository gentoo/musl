# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils flag-o-matic

MY_P="gc-${PV}"

DESCRIPTION="The Boehm-Demers-Weiser conservative garbage collector"
HOMEPAGE="http://www.hboehm.info/gc/"
SRC_URI="http://www.hboehm.info/gc/gc_source/${MY_P}.tar.gz"

LICENSE="boehm-gc"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="cxx static-libs threads"

DEPEND=">=dev-libs/libatomic_ops-7.4
	virtual/pkgconfig"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-7.2e-os_dep.patch
	epatch "${FILESDIR}"/${PN}-7.4.2-getcontext.patch
	epatch "${FILESDIR}"/${PN}-7.4.2-testsuite.patch
}

src_configure() {
	local config=(
		--with-libatomic-ops
		$(use_enable cxx cplusplus)
		$(use_enable static-libs static)
		$(use threads || echo --disable-threads)
	)
	append-cppflags -DUSE_MMAP -DHAVE_DL_ITERATE_PHDR
	econf "${config[@]}"
}

src_install() {
	default
	use static-libs || prune_libtool_files

	rm -r "${ED}"/usr/share/gc || die
	dodoc README.QUICK doc/README{.environment,.linux,.macros}
	dohtml doc/*.html
	newman doc/gc.man GC_malloc.1
}
