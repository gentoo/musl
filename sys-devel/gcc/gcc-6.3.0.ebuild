# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

PATCH_VER="1.0"
#UCLIBC_VER="1.0"

inherit eutils toolchain

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.13 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.13 )"
fi

src_prepare() {
	toolchain_src_prepare

	if use elibc_musl || [[ ${CATEGORY} = cross-*-musl ]]; then
		epatch "${FILESDIR}"/4.9.4/boehm_gc.patch
		epatch "${FILESDIR}"/4.9.4/posix_memalign.patch
		epatch "${FILESDIR}"/5.4.0/cilkrts.patch
		epatch "${FILESDIR}"/6.3.0/musl.patch
	fi
}
