# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCH_VER="1.1"
#UCLIBC_VER="1.0"

PATCH_GCC_VER="7.2.0"
PIE_GCC_VER="7.2.0"

inherit epatch toolchain

#KEYWORDS="~amd64 ~arm ~mips ~ppc ~x86"
KEYWORDS=""

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.13 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.13 )"
fi

src_prepare() {
	EPATCH_EXCLUDE="95_all_static_override_pie.patch
			96_all_powerpc_pie.patch"
	toolchain_src_prepare

	if use elibc_musl || [[ ${CATEGORY} = cross-*-musl* ]]; then
		epatch "${FILESDIR}"/6.3.0/cpu_indicator.patch
		epatch "${FILESDIR}"/7.1.0/posix_memalign.patch
	fi
}
