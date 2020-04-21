# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit autotools eutils

DESCRIPTION="tool to manipulate Intel X86 and X86-64 processor microcode update collections"
HOMEPAGE="https://gitlab.com/iucode-tool/"
SRC_URI="https://gitlab.com/iucode-tool/releases/raw/master/${PN/_/-}_${PV}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE=""

DEPEND="elibc_musl? ( sys-libs/argp-standalone )"
RDEPEND=${DEPEND}

S="${WORKDIR}/${PN/_/-}-${PV}"

src_prepare() {
	eapply "${FILESDIR}/${PN}-2.2-limits.patch"
	use elibc_musl && eapply "${FILESDIR}/${PN}-2.2-argp.patch"

	eapply_user

	eautoreconf
}
