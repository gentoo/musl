# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/mpg123/mpg123-1.15.4.ebuild,v 1.11 2013/08/07 13:24:23 ago Exp $

EAPI=5
inherit toolchain-funcs libtool flag-o-matic

DESCRIPTION="a realtime MPEG 1.0/2.0/2.5 audio player for layers 1, 2 and 3"
HOMEPAGE="http://www.mpg123.org/"
SRC_URI="http://www.mpg123.org/download/${P}.tar.bz2"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="3dnow 3dnowext alsa altivec coreaudio int-quality ipv6 jack mmx nas oss portaudio pulseaudio sdl sse"

RDEPEND="app-eselect/eselect-mpg123
	>=sys-devel/libtool-2.2.6b
	alsa? ( media-libs/alsa-lib )
	jack? ( media-sound/jack-audio-connection-kit )
	nas? ( media-libs/nas )
	portaudio? ( media-libs/portaudio )
	pulseaudio? ( media-sound/pulseaudio )
	sdl? ( media-libs/libsdl )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

DOCS=( AUTHORS ChangeLog NEWS NEWS.libmpg123 README )

src_prepare() {
	elibtoolize # for Darwin bundles

	epatch ${FILESDIR}/${PN}-largefile.patch
}

src_configure() {
	local _audio=dummy
	local _output=dummy
	local _cpu=generic_fpu

	for flag in nas portaudio sdl oss jack alsa pulseaudio coreaudio; do
		if use ${flag}; then
			_audio="${_audio} ${flag/pulseaudio/pulse}"
			_output=${flag/pulseaudio/pulse}
		fi
	done

	use altivec && _cpu=altivec

	if [[ $(tc-arch) == amd64 || ${ARCH} == x64-* ]]; then
		use sse && _cpu=x86-64
	elif use x86 && gcc-specs-pie ; then
		# Don't use any mmx, 3dnow, sse and 3dnowext #bug 164504
		_cpu=generic_fpu
	elif use x86-macos ; then
		# ASM doesn't work quite as expected with the Darwin linker
		_cpu=generic_fpu
	else
		use mmx && _cpu=mmx
		use 3dnow && _cpu=3dnow
		use sse && _cpu=x86
		use 3dnowext && _cpu=x86
	fi

	econf \
		--with-optimization=0 \
		--with-audio="${_audio}" \
		--with-default-audio=${_output} \
		--with-cpu=${_cpu} \
		--enable-network \
		--disable-lfs-alias \
		$(use_enable ipv6) \
		--enable-int-quality=$(usex int-quality)
}

src_install() {
	default
	mv "${ED}"/usr/bin/mpg123{,-mpg123}
	find "${ED}" -name '*.la' -exec sed -i -e "/^dependency_libs/s:=.*:='':" {} +
}

pkg_postinst() {
	eselect mpg123 update ifunset
}

pkg_postrm() {
	eselect mpg123 update ifunset
}
