# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCH_VER="1.1"
#UCLIBC_VER="1.0"

inherit epatch toolchain

# KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.13 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.13 )"
fi

src_prepare() {
	toolchain_src_prepare

	epatch "${FILESDIR}"/gcc-7.2.0-pr69728.patch

	# Meltdown/Spectre
	epatch "${FILESDIR}"/0001-gcc-7.2.0-move-struct-ix86_frame-to-machine-function.patch
	epatch "${FILESDIR}"/0002-gcc-7.2.0-move-struct-ix86_frame-to-machine-function.patch

	epatch "${FILESDIR}"/spectre-0001-mindirect-branch.patch
	epatch "${FILESDIR}"/spectre-0002-mfunction-return.patch
	epatch "${FILESDIR}"/spectre-0003-mindirect-branch-register.patch
	epatch "${FILESDIR}"/spectre-0004-v-register-modifier.patch
	epatch "${FILESDIR}"/spectre-0005-mcmodel-large.patch

	if use elibc_musl || [[ ${CATEGORY} = cross-*-musl* ]]; then
		epatch "${FILESDIR}"/6.3.0/cpu_indicator.patch
		epatch "${FILESDIR}"/7.1.0/posix_memalign.patch
	fi
}
