# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/netpbm/netpbm-10.51.00-r2.ebuild,v 1.6 2013/08/27 15:32:09 kensington Exp $

EAPI="3"

inherit toolchain-funcs eutils multilib

DESCRIPTION="A set of utilities for converting to/from the netpbm (and related) formats"
HOMEPAGE="http://netpbm.sourceforge.net/"
SRC_URI="mirror://gentoo/${P}.tar.xz
	mirror://gentoo/${P}-libpng-1.5.patch.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="jbig jpeg jpeg2k png rle svga tiff X xml zlib"

RDEPEND="jbig? ( media-libs/jbigkit )
	jpeg? ( virtual/jpeg:0 )
	jpeg2k? ( media-libs/jasper )
	png? ( >=media-libs/libpng-1.4:0 )
	rle? ( media-libs/urt )
	svga? ( media-libs/svgalib )
	tiff? ( >=media-libs/tiff-3.5.5:0 )
	xml? ( dev-libs/libxml2 )
	zlib? ( sys-libs/zlib )
	X? ( x11-libs/libX11 )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	sys-devel/flex"

maint_pkg_create() {
	local base="/usr/local/src"
	local srcdir="${base}/netpbm/release_number"
	if [[ -d ${srcdir} ]] ; then
		cd "${T}" || die

		ebegin "Exporting ${srcdir}/${PV} to netpbm-${PV}"
		svn export -q ${srcdir}/${PV} netpbm-${PV}
		eend $? || return 1

		ebegin "Creating netpbm-${PV}.tar.xz"
		tar cf - netpbm-${PV} | xz > netpbm-${PV}.tar.xz
		eend $?

		einfo "Tarball now ready at: ${T}/netpbm-${PV}.tar.xz"
	else
		einfo "You need to run:"
		einfo " cd ${base}"
		einfo " svn co https://netpbm.svn.sourceforge.net/svnroot/netpbm"
		die "need svn checkout dir"
	fi
}
pkg_setup() { [[ -n ${VAPIER_LOVES_YOU} && ! -e ${DISTDIR}/${P}.tar.xz ]] && maint_pkg_create ; }

netpbm_libtype() {
	case ${CHOST} in
		*-darwin*) echo dylib;;
		*)         echo unixshared;;
	esac
}
netpbm_libsuffix() {
	local suffix=$(get_libname)
	echo ${suffix//\.}
}
netpbm_ldshlib() {
	case ${CHOST} in
		*-darwin*) echo '$(LDFLAGS) -dynamiclib -install_name $(SONAME)';;
		*)         echo '$(LDFLAGS) -shared -Wl,-soname,$(SONAME)';;
	esac
}
netpbm_config() {
	if use $1 ; then
		[[ $2 != "!" ]] && echo -l${2:-$1}
	else
		echo NONE
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/netpbm-10.31-build.patch
	epatch "${FILESDIR}"/${P}-ppmtompeg-free.patch
	epatch "${FILESDIR}"/${P}-pnmconvol-nooffset.patch #338230
	epatch "${WORKDIR}"/${P}-libpng-1.5.patch #355025
	epatch "${FILESDIR}"/${P}-underlinking.patch #367405

	epatch "${FILESDIR}"/${P}-getline.patch

	# make sure we use system urt
	sed -i '/SUPPORT_SUBDIRS/s:urt::' GNUmakefile || die
	rm -rf urt

	# take care of the importinc stuff ourselves by only doing it once
	# at the top level and having all subdirs use that one set #149843
	sed -i \
		-e '/^importinc:/s|^|importinc:\nmanual_|' \
		-e '/-Iimportinc/s|-Iimp|-I"$(BUILDDIR)"/imp|g'\
		common.mk || die
	sed -i \
		-e '/%.c/s: importinc$::' \
		common.mk lib/Makefile lib/util/Makefile || die

	# avoid ugly depend.mk warnings
	touch $(find . -name Makefile | sed s:Makefile:depend.mk:g)
}

src_configure() {
	cat config.mk.in - >> config.mk <<-EOF
	# Misc crap
	BUILD_FIASCO = N
	SYMLINK = ln -sf

	# Toolchain options
	CC = $(tc-getCC) -Wall
	LD = \$(CC)
	CC_FOR_BUILD = $(tc-getBUILD_CC)
	LD_FOR_BUILD = \$(CC_FOR_BUILD)
	AR = $(tc-getAR)
	RANLIB = $(tc-getRANLIB)

	STRIPFLAG =
	CFLAGS_SHLIB = -fPIC

	LDRELOC = \$(LD) -r
	LDSHLIB = $(netpbm_ldshlib)
	LINKER_CAN_DO_EXPLICIT_LIBRARY = N # we can, but dont want to
	LINKERISCOMPILER = Y
	NETPBMLIBSUFFIX = $(netpbm_libsuffix)
	NETPBMLIBTYPE = $(netpbm_libtype)

	# Gentoo build options
	TIFFLIB = $(netpbm_config tiff)
	JPEGLIB = $(netpbm_config jpeg)
	PNGLIB = $(netpbm_config png)
	ZLIB = $(netpbm_config zlib z)
	LINUXSVGALIB = $(netpbm_config svga vga)
	XML2_LIBS = $(netpbm_config xml xml2)
	JBIGLIB = -ljbig
	JBIGHDR_DIR = $(netpbm_config jbig "!")
	JASPERLIB = -ljasper
	JASPERHDR_DIR = $(netpbm_config jpeg2k "!")
	URTLIB = $(netpbm_config rle)
	URTHDR_DIR =
	X11LIB = $(netpbm_config X X11)
	X11HDR_DIR =
	EOF
	# cannot chain the die with the heredoc above as bash-3
	# has a parser bug in that setup #282902
	[ $? -eq 0 ] || die "writing config.mk failed"
}

src_compile() {
	emake -j1 pm_config.h version.h manual_importinc || die #149843
	emake || die
}

src_install() {
	# Subdir make targets like to use `mkdir` all over the place
	# without any actual dependencies, thus the -j1.
	emake -j1 package pkgdir="${D}"/usr || die

	[[ $(get_libdir) != "lib" ]] && mv "${D}"/usr/lib "${D}"/usr/$(get_libdir)

	# Remove cruft that we don't need, and move around stuff we want
	rm "${D}"/usr/bin/{doc.url,manweb} || die
	rm -r "${D}"/usr/man/web || die
	rm -r "${D}"/usr/link || die
	rm "${D}"/usr/{README,VERSION,config_template,pkginfo} || die
	dodir /usr/share
	mv "${D}"/usr/man "${D}"/usr/share/ || die
	mv "${D}"/usr/misc "${D}"/usr/share/netpbm || die

	dodoc README
	cd doc
	dodoc HISTORY Netpbm.programming USERDOC
	dohtml -r .
}
