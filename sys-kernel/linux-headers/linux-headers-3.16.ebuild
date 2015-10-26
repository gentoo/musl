# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="4"

ETYPE="headers"
H_SUPPORTEDARCH="alpha amd64 arc arm arm64 avr32 bfin cris frv hexagon hppa ia64 m32r m68k metag microblaze mips mn10300 openrisc ppc ppc64 s390 score sh sparc tile x86 xtensa"
inherit kernel-2
detect_version

PATCH_VER="1"
SRC_URI="http://dev.gentoo.org/~blueness/dist/gentoo-headers-3.16-1.tar.xz
	http://dev.gentoo.org/~blueness/dist/gentoo-headers-base-3.16.tar.xz"

KEYWORDS="amd64 arm ~mips ppc x86"

DEPEND="app-arch/xz-utils
	dev-lang/perl"
RDEPEND="!!media-sound/alsa-headers"

S=${WORKDIR}/gentoo-headers-base-${PV}

src_unpack() {
	unpack ${A}
}

src_prepare() {
	[[ -n ${PATCH_VER} ]] && EPATCH_SUFFIX="patch" epatch "${WORKDIR}"/${PV}
}

src_install() {
	kernel-2_src_install

	# hrm, build system sucks
	find "${ED}" '(' -name '.install' -o -name '*.cmd' ')' -delete
	find "${ED}" -depth -type d -delete 2>/dev/null

	# provided by libdrm (for now?)
	rm -rf "${ED}"/$(kernel_header_destdir)/drm
}

src_test() {
	einfo "Possible unescaped attribute/type usage"
	egrep -r \
		-e '(^|[[:space:](])(asm|volatile|inline)[[:space:](]' \
		-e '\<([us](8|16|32|64))\>' \
		.

	einfo "Missing linux/types.h include"
	egrep -l -r -e '__[us](8|16|32|64)' "${ED}" | xargs grep -L linux/types.h

	emake ARCH=$(tc-arch-kernel) headers_check
}
