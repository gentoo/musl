# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic ltprune

MY_P="gc-${PV}"

DESCRIPTION="The Boehm-Demers-Weiser conservative garbage collector"
HOMEPAGE="http://www.hboehm.info/gc/"
SRC_URI="http://www.hboehm.info/gc/gc_source/${MY_P}.tar.gz"

LICENSE="boehm-gc"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ia64 ~mips ~ppc ~sparc ~x86"
IUSE="cxx static-libs threads"

DEPEND=">=dev-libs/libatomic_ops-7.4
	virtual/pkgconfig"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	"${FILESDIR}"/${PN}-7.4.2-testsuite.patch
	"${FILESDIR}"/${PN}-7.6.0-sys_select.patch
)

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

src_compile() {
	# Workaround build errors. #574566
	use ia64 && emake src/ia64_save_regs_in_stack.lo
	use sparc && emake src/sparc_mach_dep.lo
	default
}

src_install() {
	default
	use static-libs || prune_libtool_files

	rm -r "${ED}"/usr/share/gc || die
	dodoc README.QUICK doc/README{.environment,.linux,.macros}
	docinto html
	dodoc doc/*.html
	newman doc/gc.man GC_malloc.1
}
