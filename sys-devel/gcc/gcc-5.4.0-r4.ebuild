# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCH_VER="1.7"
UCLIBC_VER="1.0"

# Hardened gcc 4 stuff
PIE_VER="0.6.5"
SPECS_VER="0.2.0"
SPECS_GCC_VER="4.4.3"
# arch/libc configurations known to be stable with {PIE,SSP}-by-default
PIE_GLIBC_STABLE="x86 amd64 mips ppc ppc64 arm ia64"
PIE_UCLIBC_STABLE="x86 arm amd64 mips ppc ppc64"
SSP_STABLE="amd64 x86 mips ppc ppc64 arm"
# uclibc need tls and nptl support for SSP support
# uclibc need to be >= 0.9.33
SSP_UCLIBC_STABLE="x86 amd64 mips ppc ppc64 arm"
PIE_MUSL_STABLE="amd64 arm ppc mips x86"
SSP_MUSL_STABLE="amd64 arm ppc mips"
#end Hardened stuff

inherit epatch toolchain

KEYWORDS="alpha amd64 arm arm64 hppa ia64 ~m68k ~mips ppc ppc64 ~s390 ~sh ~sparc x86"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.8 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

src_prepare() {
	if has_version '<sys-libs/glibc-2.12' ; then
		ewarn "Your host glibc is too old; disabling automatic fortify."
		ewarn "Please rebuild gcc after upgrading to >=glibc-2.12 #362315"
		EPATCH_EXCLUDE+=" 10_all_default-fortify-source.patch"
	fi
	is_crosscompile && EPATCH_EXCLUDE+=" 05_all_gcc-spec-env.patch"

	toolchain_src_prepare

	# Upstream Patch
	epatch "${FILESDIR}"/${PN}-4.9.3-tree-vect-data-refs-correctness.patch
	epatch "${FILESDIR}"/${PN}-5.4.0-pr68470.patch
	epatch "${FILESDIR}"/${PN}-5.4.0-pr70473.patch
	epatch "${FILESDIR}"/${PN}-5.4.0-pr71696-CVE-2016-6131.patch

	if use elibc_musl || [[ ${CATEGORY} = cross-*-musl* ]]; then
		epatch "${FILESDIR}"/4.9.4/gthread.patch
		epatch "${FILESDIR}"/4.9.4/boehm_gc.patch
		epatch "${FILESDIR}"/4.9.4/posix_memalign.patch
		epatch "${FILESDIR}"/5.4.0/cilkrts.patch
		epatch "${FILESDIR}"/5.4.0/linker_path.patch
		epatch "${FILESDIR}"/5.4.0/musl.patch
		epatch "${FILESDIR}"/5.4.0/ppc-secure_plt.patch
	fi
}
