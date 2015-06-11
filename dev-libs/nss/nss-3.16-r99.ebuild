# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/nss/nss-3.16.ebuild,v 1.13 2014/07/24 10:58:18 polynomial-c Exp $

EAPI=5
inherit eutils flag-o-matic multilib toolchain-funcs

NSPR_VER="4.10"
RTM_NAME="NSS_${PV//./_}_RTM"
# Rev of https://git.fedorahosted.org/cgit/nss-pem.git
PEM_GIT_REV="3ade37c5c4ca5a6094e3f4b2e4591405db1867dd"
PEM_P="${PN}-pem-${PEM_GIT_REV}"

DESCRIPTION="Mozilla's Network Security Services library that implements PKI support"
HOMEPAGE="http://www.mozilla.org/projects/security/pki/nss/"
SRC_URI="ftp://ftp.mozilla.org/pub/mozilla.org/security/nss/releases/${RTM_NAME}/src/${P}.tar.gz
	cacert? ( http://dev.gentoo.org/~anarchy/patches/${PN}-3.14.1-add_spi+cacerts_ca_certs.patch )
	nss-pem? ( https://git.fedorahosted.org/cgit/nss-pem.git/snapshot/${PEM_P}.tar.bz2 )"

LICENSE="|| ( MPL-2.0 GPL-2 LGPL-2.1 )"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="+cacert +nss-pem utils"

DEPEND="virtual/pkgconfig
	>=dev-libs/nspr-${NSPR_VER}"
RDEPEND=">=dev-libs/nspr-${NSPR_VER}
	>=dev-db/sqlite-3.5
	sys-libs/zlib"

RESTRICT="test"

S="${WORKDIR}/${P}/${PN}"

src_setup() {
	export LC_ALL="C"
}

src_unpack() {
	unpack ${A}
	if use nss-pem ; then
		mv "${PEM_P}"/nss/lib/ckfw/pem/ "${S}"/lib/ckfw/ || die
	fi
}

src_prepare() {
	# Custom changes for gentoo
	epatch "${FILESDIR}/${PN}-3.15-gentoo-fixups.patch"
	epatch "${FILESDIR}/${PN}-3.15-gentoo-fixup-warnings.patch"
	epatch "${FILESDIR}/${PN}-3.16-musl.patch"
	use cacert && epatch "${DISTDIR}/${PN}-3.14.1-add_spi+cacerts_ca_certs.patch"
	use nss-pem && epatch "${FILESDIR}/${PN}-3.15.4-enable-pem.patch"
	epatch "${FILESDIR}/nss-3.14.2-solaris-gcc.patch"
	cd coreconf
	# hack nspr paths
	echo 'INCLUDES += -I$(DIST)/include/dbm' \
		>> headers.mk || die "failed to append include"

	# modify install path
	sed -e 's:SOURCE_PREFIX = $(CORE_DEPTH)/\.\./dist:SOURCE_PREFIX = $(CORE_DEPTH)/dist:' \
		-i source.mk

	# Respect LDFLAGS
	sed -i -e 's/\$(MKSHLIB) -o/\$(MKSHLIB) \$(LDFLAGS) -o/g' rules.mk

	# Ensure we stay multilib aware
	sed -i -e "/@libdir@/ s:lib64:$(get_libdir):" "${S}"/config/Makefile

	# Fix pkgconfig file for Prefix
	sed -i -e "/^PREFIX =/s:= /usr:= ${EPREFIX}/usr:" \
		"${S}"/config/Makefile

	# use host shlibsign if need be #436216
	if tc-is-cross-compiler ; then
		sed -i \
			-e 's:"${2}"/shlibsign:shlibsign:' \
			"${S}"/cmd/shlibsign/sign.sh
	fi

	# dirty hack
	cd "${S}"
	sed -i -e "/CRYPTOLIB/s:\$(SOFTOKEN_LIB_DIR):../freebl/\$(OBJDIR):" \
		lib/ssl/config.mk
	sed -i -e "/CRYPTOLIB/s:\$(SOFTOKEN_LIB_DIR):../../lib/freebl/\$(OBJDIR):" \
		cmd/platlibs.mk
}

nssarch() {
	# Most of the arches are the same as $ARCH
	local t=${1:-${CHOST}}
	case ${t} in
	aarch64*)echo "aarch64";;
	hppa*)   echo "parisc";;
	i?86*)   echo "i686";;
	x86_64*) echo "x86_64";;
	*)       tc-arch ${t};;
	esac
}

nssbits() {
	local cc="${1}CC" cppflags="${1}CPPFLAGS" cflags="${1}CFLAGS"
	echo > "${T}"/test.c || die
	${!cc} ${!cppflags} ${!cflags} -c "${T}"/test.c -o "${T}"/test.o || die
	case $(file "${T}"/test.o) in
	*32-bit*x86-64*) echo USE_X32=1;;
	*64-bit*|*ppc64*|*x86_64*) echo USE_64=1;;
	*32-bit*|*ppc*|*i386*) ;;
	*) die "Failed to detect whether your arch is 64bits or 32bits, disable distcc if you're using it, please";;
	esac
}

src_compile() {
	strip-flags

	tc-export AR RANLIB {BUILD_,}{CC,PKG_CONFIG}
	local makeargs=(
		CC="${CC}"
		AR="${AR} rc \$@"
		RANLIB="${RANLIB}"
		OPTIMIZER=
		$(nssbits)
	)

	# Take care of nspr settings #436216
	append-cppflags $(${PKG_CONFIG} nspr --cflags)
	append-ldflags $(${PKG_CONFIG} nspr --libs-only-L)
	unset NSPR_INCLUDE_DIR
	export NSPR_LIB_DIR=${T}/fake-dir

	# Do not let `uname` be used.
	if use kernel_linux ; then
		makeargs+=(
			OS_TARGET=Linux
			OS_RELEASE=2.6
			OS_TEST="$(nssarch)"
		)
	fi

	export BUILD_OPT=1
	export NSS_USE_SYSTEM_SQLITE=1
	export NSDISTMODE=copy
	export NSS_ENABLE_ECC=1
	export XCFLAGS="${CFLAGS} ${CPPFLAGS}"
	export FREEBL_NO_DEPEND=1
	export ASFLAGS=""

	local d

	# Build the host tools first.
	LDFLAGS="${BUILD_LDFLAGS}" \
	XCFLAGS="${BUILD_CFLAGS}" \
	emake -j1 -C coreconf \
		CC="${BUILD_CC}" \
		$(nssbits BUILD_)
	makeargs+=( NSINSTALL="${PWD}/$(find -type f -name nsinstall)" )

	# Then build the target tools.
	for d in . lib/dbm ; do
		emake -j1 "${makeargs[@]}" -C ${d}
	done
}

# Altering these 3 libraries breaks the CHK verification.
# All of the following cause it to break:
# - stripping
# - prelink
# - ELF signing
# http://www.mozilla.org/projects/security/pki/nss/tech-notes/tn6.html
# Either we have to NOT strip them, or we have to forcibly resign after
# stripping.
#local_libdir="$(get_libdir)"
#export STRIP_MASK="
#	*/${local_libdir}/libfreebl3.so*
#	*/${local_libdir}/libnssdbm3.so*
#	*/${local_libdir}/libsoftokn3.so*"

export NSS_CHK_SIGN_LIBS="freebl3 nssdbm3 softokn3"

generate_chk() {
	local shlibsign="$1"
	local libdir="$2"
	einfo "Resigning core NSS libraries for FIPS validation"
	shift 2
	local i
	for i in ${NSS_CHK_SIGN_LIBS} ; do
		local libname=lib${i}.so
		local chkname=lib${i}.chk
		"${shlibsign}" \
			-i "${libdir}"/${libname} \
			-o "${libdir}"/${chkname}.tmp \
		&& mv -f \
			"${libdir}"/${chkname}.tmp \
			"${libdir}"/${chkname} \
		|| die "Failed to sign ${libname}"
	done
}

cleanup_chk() {
	local libdir="$1"
	shift 1
	local i
	for i in ${NSS_CHK_SIGN_LIBS} ; do
		local libfname="${libdir}/lib${i}.so"
		# If the major version has changed, then we have old chk files.
		[ ! -f "${libfname}" -a -f "${libfname}.chk" ] \
			&& rm -f "${libfname}.chk"
	done
}

src_install() {
	cd "${S}"/dist

	dodir /usr/$(get_libdir)
	cp -L */lib/*$(get_libname) "${ED}"/usr/$(get_libdir) || die "copying shared libs failed"
	# We generate these after stripping the libraries, else they don't match.
	#cp -L */lib/*.chk "${ED}"/usr/$(get_libdir) || die "copying chk files failed"
	cp -L */lib/libcrmf.a "${ED}"/usr/$(get_libdir) || die "copying libs failed"

	# Install nss-config and pkgconfig file
	dodir /usr/bin
	cp -L */bin/nss-config "${ED}"/usr/bin
	dodir /usr/$(get_libdir)/pkgconfig
	cp -L */lib/pkgconfig/nss.pc "${ED}"/usr/$(get_libdir)/pkgconfig

	# all the include files
	insinto /usr/include/nss
	doins public/nss/*.h

	local f nssutils
	# Always enabled because we need it for chk generation.
	nssutils="shlibsign"
	if use utils; then
		# The tests we do not need to install.
		#nssutils_test="bltest crmftest dbtest dertimetest
		#fipstest remtest sdrtest"
		nssutils="addbuiltin atob baddbdir btoa certcgi certutil checkcert
		cmsutil conflict crlutil derdump digest makepqg mangle modutil multinit
		nonspr10 ocspclnt oidcalc p7content p7env p7sign p7verify pk11mode
		pk12util pp rsaperf selfserv shlibsign signtool signver ssltap strsclnt
		symkeyutil tstclnt vfychain vfyserv"
	fi
	cd "${S}"/dist/*/bin/
	for f in ${nssutils}; do
		dobin ${f}
	done

	# Prelink breaks the CHK files. We don't have any reliable way to run
	# shlibsign after prelink.
	local l libs=() liblist
	for l in ${NSS_CHK_SIGN_LIBS} ; do
		libs+=("${EPREFIX}/usr/$(get_libdir)/lib${l}.so")
	done
	liblist=$(printf '%s:' "${libs[@]}")
	echo -e "PRELINK_PATH_MASK=${liblist%:}" > "${T}/90nss"
	doenvd "${T}/90nss"
}

pkg_postinst() {
	# We must re-sign the libraries AFTER they are stripped.
	local shlibsign="${EROOT}/usr/bin/shlibsign"
	# See if we can execute it (cross-compiling & such). #436216
	"${shlibsign}" -h >&/dev/null
	if [[ $? -gt 1 ]] ; then
		shlibsign="shlibsign"
	fi
	generate_chk "${shlibsign}" "${EROOT}"/usr/$(get_libdir)
}

pkg_postrm() {
	cleanup_chk "${EROOT}"/usr/$(get_libdir)
}
