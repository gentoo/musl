# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools toolchain-funcs

IUSE="nls xinerama bidi +truetype +imlib +slit +systray +toolbar vim-syntax"

REQUIRED_USE="systray? ( toolbar )"

DESCRIPTION="X11 window manager featuring tabs and an iconbar"

SRC_URI="mirror://sourceforge/fluxbox/${P}.tar.xz"
HOMEPAGE="http://www.fluxbox.org"
SLOT="0"
LICENSE="MIT"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"

RDEPEND="
	!!<=x11-misc/fbdesk-1.2.1
	!!<=x11-misc/fluxconf-0.9.9
	!!<x11-themes/fluxbox-styles-fluxmod-20040809-r1
	bidi? ( >=dev-libs/fribidi-0.19.2 )
	imlib? ( >=media-libs/imlib2-1.2.0[X] )
	truetype? ( media-libs/freetype )
	vim-syntax? ( app-vim/fluxbox-syntax )
	x11-libs/libXext
	x11-libs/libXft
	x11-libs/libXpm
	x11-libs/libXrandr
	x11-libs/libXrender
	xinerama? ( x11-libs/libXinerama )
	|| ( x11-misc/gxmessage x11-apps/xmessage )
"

DEPEND="
	${RDEPEND}
	bidi? ( virtual/pkgconfig )
	nls? ( sys-devel/gettext )
	x11-base/xorg-proto
"

PATCHES=(
	"${FILESDIR}"/0001-strip-fluxbox-remote.patch
	"${FILESDIR}"/0002-fix-nls-musl.patch
)

src_prepare() {

	default
	eautoreconf
}

src_configure() {

	local myeconfargs=(
		$(use_enable imlib imlib2)
		$(use_enable bidi fribidi)
		$(use_enable slit)
		$(use_enable systray)
		$(use_enable toolbar)
		$(use_enable truetype xft)
		$(use_enable xinerama)
		--sysconfdir="${EPREFIX}"/etc/X11/${PN} \
		--with-style="${EPREFIX}"/usr/share/fluxbox/styles/Emerge

	)

	if ! use nls; then
	local myeconfargs=( --disable-nls )
	fi

	econf "${myeconfargs[@]}"
}

src_compile() {
	default

}

src_install() {

	emake DESTDIR="${D}" STRIP="" install
	dodoc README* AUTHORS TODO* ChangeLog NEWS

	# Install the generated menu
	insinto /usr/share/fluxbox
	doins data/menu

	insinto /usr/share/xsessions
	doins "${FILESDIR}"/${PN}.desktop

	exeinto /etc/X11/Sessions
	newexe "${FILESDIR}"/${PN}.xsession fluxbox

	# Styles menu framework
	insinto /usr/share/fluxbox/menu.d/styles
	doins "${FILESDIR}"/styles-menu-fluxbox
	doins "${FILESDIR}"/styles-menu-commonbox
	doins "${FILESDIR}"/styles-menu-user
}
