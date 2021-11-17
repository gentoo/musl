# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PATCH_VER="3"
MUSL_VER="1"
inherit toolchain

KEYWORDS="amd64 arm arm64 ~mips ppc ppc64 x86"

RDEPEND=""
BDEPEND="${CATEGORY}/binutils"

src_prepare() {
	toolchain_src_prepare

	eapply_user
}
