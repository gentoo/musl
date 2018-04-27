# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit systemd toolchain-funcs versionator

MY_PV="$(get_version_component_range 1-2)"

DESCRIPTION="Userspace utils and init scripts for the AppArmor application security system"
HOMEPAGE="http://apparmor.net/"
SRC_URI="https://launchpad.net/${PN}/${MY_PV}/${PV}/+download/${PN}-${MY_PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="doc"

RDEPEND="~sys-libs/libapparmor-${PV}"
DEPEND="${RDEPEND}
	dev-lang/perl
	sys-devel/bison
	sys-devel/flex
	doc? ( dev-tex/latex2html )
"

S=${WORKDIR}/apparmor-${MY_PV}/parser/

PATCHES=( "${FILESDIR}/apparmor-${MY_PV}-musl.patch" )

src_prepare() {

	default
}

src_compile()  {

	emake CC="$(tc-getCC)" CXX="$(tc-getCXX)" USE_SYSTEM=1 arch manpages
}

src_test() {

	emake CXX="$(tc-getCXX)" USE_SYSTEM=1 check
}

src_install() {

	cd parser/
	emake DESTDIR="${D}" DISTRO="unknown" USE_SYSTEM=1  install

	dodir /etc/apparmor.d/disable

	newinitd "${FILESDIR}/${PN}-init" ${PN}
	systemd_newunit "${FILESDIR}/apparmor.service" apparmor.service

	use doc && dodoc techdoc.pdf

	exeinto /usr/share/apparmor
	doexe "${FILESDIR}/apparmor_load.sh"
	doexe "${FILESDIR}/apparmor_unload.sh"

}