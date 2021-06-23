# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PATCH_VER="1"

inherit toolchain

KEYWORDS="amd64 arm arm64 ~mips ppc ppc64 x86"

RDEPEND=""
BDEPEND="${CATEGORY}/binutils"

src_prepare() {
	toolchain_src_prepare

	if use elibc_musl || [[ ${CATEGORY} = cross-*-musl* ]]; then
		eapply "${FILESDIR}"/10.1.0/cpu_indicator.patch
		eapply "${FILESDIR}"/7.1.0/posix_memalign.patch
		case $(tc-arch) in
			amd64|arm64|ppc64) eapply "${FILESDIR}"/9.3.0/gcc-pure64.patch ;;
		esac
	fi

	eapply_user
}
