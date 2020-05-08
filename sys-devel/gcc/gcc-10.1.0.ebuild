# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PATCH_VER="1"

inherit toolchain

KEYWORDS="~amd64 ~arm ~arm64 ~mips ~ppc ~ppc64 ~x86"

RDEPEND=""
DEPEND=">=${CATEGORY}/binutils-2.20"

src_prepare() {
	toolchain_src_prepare

	if use elibc_musl || [[ ${CATEGORY} = cross-*-musl* ]]; then
		eapply "${FILESDIR}"/10.1.0/cpu_indicator.patch
		eapply "${FILESDIR}"/7.1.0/posix_memalign.patch
		case $(tc-arch) in
			amd64|arm64|ppc64) eapply "${FILESDIR}"/8.3.0/gcc-pure64.patch ;;
		esac
	fi

	eapply_user
}
