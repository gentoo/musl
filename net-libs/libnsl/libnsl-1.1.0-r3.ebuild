# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools multilib-minimal

DESCRIPTION="Public client interface for NIS(YP) and NIS+ in a IPv6 ready version"
HOMEPAGE="https://github.com/thkukuk/libnsl"
SRC_URI="https://github.com/thkukuk/${PN}/archive/${P}.tar.gz"

SLOT="0/2"
LICENSE="LGPL-2.1+"

# Stabilize together with glibc-2.26!
KEYWORDS="~amd64 ~arm ~ia64 ~mips ~ppc ~sh ~sparc ~x86"

IUSE=""

DEPEND="
	net-libs/libtirpc[${MULTILIB_USEDEP}]
"
RDEPEND="${DEPEND}
	!<sys-libs/glibc-2.26
"

PATCHES=( "${FILESDIR}"/${P}-musl.patch )

S=${WORKDIR}/${PN}-${P}

src_prepare(){
	default
	find "${S}" -name '*.h' -exec \
		sed -e 's|^__BEGIN_DECLS$|#ifdef __cplusplus\nextern "C" {\n#endif|' \
		    -e 's|^__END_DECLS$|#ifdef __cplusplus\n}\n#endif|' \
		    -e 's| __THROW||' \
		    -i {} \; || die
	eautoreconf
}

multilib_src_configure() {
	local myconf=(
		--enable-shared
		--disable-static
	)
	ECONF_SOURCE=${S} econf "${myconf[@]}"
}

multilib_src_install_all() {
	einstalldocs
	find "${ED}" -name '*.la' -delete || die
}
