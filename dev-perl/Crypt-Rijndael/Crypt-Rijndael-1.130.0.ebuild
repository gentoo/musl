# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

MODULE_AUTHOR=LEONT
MODULE_VERSION=1.13
inherit perl-module

DESCRIPTION="Crypt::CBC compliant Rijndael encryption module"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~mips ppc ppc64 x86"
IUSE="test"
RESTRICT="!test? ( test )"

DEPEND="
	virtual/perl-ExtUtils-MakeMaker
	test? (
		virtual/perl-Test-Simple
	)
"

SRC_TEST="do parallel"

src_prepare() {
	use elibc_musl && epatch "${FILESDIR}"/musl-int-types.patch
	default
}
