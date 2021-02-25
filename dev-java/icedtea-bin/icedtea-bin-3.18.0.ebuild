# Copyright 2020-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit java-vm-2 toolchain-funcs multilib-build

ALPINE_PN="openjdk8"
ALPINE_PV="8.282.08-r0"
ALPINE_P="java-1.8-openjdk"
ALPINE_PATH="usr/lib/jvm/${ALPINE_P}"
S="${WORKDIR}"

get_apk_names() {
	ARCH="${2-${1}}"
	echo "${1}? (
		${BASE_URI}/${ARCH}/${ALPINE_PN}-${ALPINE_PV}.apk -> ${PF}-${ARCH}.tar.gz
		${BASE_URI}/${ARCH}/${ALPINE_PN}-jre-${ALPINE_PV}.apk -> ${PF}-jre-${ARCH}.tar.gz
		${BASE_URI}/${ARCH}/${ALPINE_PN}-jre-base-${ALPINE_PV}.apk -> ${PF}-jre-base-${ARCH}.tar.gz
		${BASE_URI}/${ARCH}/${ALPINE_PN}-jre-lib-${ALPINE_PV}.apk -> ${PF}-jre-lib-${ARCH}.tar.gz
		${BASE_URI}/${ARCH}/${ALPINE_PN}-doc-${ALPINE_PV}.apk -> ${PF}-doc-${ARCH}.tar.gz
		examples? ( ${BASE_URI}/${ARCH}/${ALPINE_PN}-demos-${ALPINE_PV}.apk -> ${PF}-demos-${ARCH}.tar.gz )
		debug? ( ${BASE_URI}/${ARCH}/${ALPINE_PN}-dbg-${ALPINE_PV}.apk -> ${PF}-dbg-${ARCH}.tar.gz )
	)"
}

DESCRIPTION="Binary build of the IcedTea JDK from Alpine Linux"
HOMEPAGE="http://icedtea.classpath.org"
BASE_URI="http://dl-cdn.alpinelinux.org/alpine/edge/community/"
SRC_URI="
	$(get_apk_names amd64 x86_64)
	$(get_apk_names arm armhf)
	$(get_apk_names arm armv7)
	$(get_apk_names arm64 aarch64)
	$(get_apk_names ppc64 ppc64le)
	$(get_apk_names s390 s390x)
	$(get_apk_names x86 x86)
"

LICENSE="GPL-2-with-classpath-exception"
SLOT="8"
KEYWORDS="-* amd64 arm arm64 ppc64 x86"
IUSE="big-endian elibc_musl cups +gtk pulseaudio selinux debug examples alsa headless-awt"

REQUIRED_USE="
	gtk? ( !headless-awt )
	ppc64? ( !big-endian )
	elibc_musl
"
RESTRICT="preserve-libs strip mirror"
QA_PREBUILT="opt/.*"

RDEPEND=""
DEPEND="
	>=dev-libs/glib-2.60.7:2
	>=media-libs/fontconfig-2.13:1.0
	>=media-libs/freetype-2.9.1:2
	>=media-libs/lcms-2.9:2
	>=sys-apps/baselayout-java-0.1.0-r1
	>=sys-libs/zlib-1.2.11-r2
	virtual/jpeg-compat:62
	alsa? ( >=media-libs/alsa-lib-1.2 )
	cups? ( >=net-print/cups-2.0 )
	gtk? (
		>=dev-libs/atk-2.32.0
		>=x11-libs/cairo-1.16.0
		x11-libs/gdk-pixbuf:2
		>=x11-libs/gtk+-2.24:2
		>=x11-libs/pango-1.42
	)
	selinux? ( sec-policy/selinux-java )
	virtual/ttf-fonts
	!headless-awt? (
		media-libs/giflib:0/7
		=media-libs/libpng-1.6*
		>=x11-libs/libX11-1.6
		>=x11-libs/libXcomposite-0.4
		>=x11-libs/libXext-1.3
		>=x11-libs/libXi-1.7
		>=x11-libs/libXrender-0.9.10
		>=x11-libs/libXtst-1.2
	)
"
PDEPEND="
	pulseaudio? ( dev-java/icedtea-sound )
"

src_unpack() {
	if use arm; then
		# Only unpack armv7 or armhf according to tc-is-softfloat
		[ "$(tc-is-softfloat)" = "no" ] && arch="armhf" || arch="armv7"
		for k in ${A}; do
			if [ -z "${k##*${arch}*}" ]; then
				unpack ${k}
			fi
		done
	else
		unpack ${A}
	fi
}

src_prepare() {
	default

	# Overwrite normal binaries with the ones with debug symbols
	if use debug; then
		# Remove .debug extension
		shopt -s globstar
		for file in usr/lib/debug/**/*.debug; do
			mv "${file}" "${file%.debug}" || die
		done
		shopt -u globstar
		cp -r usr/lib/debug/usr . || die
		rm -rv usr/lib/debug || die
	fi

	if ! use alsa; then
		rm -v "${ALPINE_PATH}"/jre/lib/*/libjsoundalsa.* || die
	fi

	if use headless-awt; then
		rm -rv "${ALPINE_PATH}"/{,jre/}bin/policytool \
			"${ALPINE_PATH}"/bin/appletviewer || die
	fi
}

src_install() {
	local dest="/opt/${P}"
	local ddest="${ED}${dest#/}"
	dodir "${dest}"

	dodoc "${ALPINE_PATH}"/{ASSEMBLY_EXCEPTION,LICENSE,release,THIRD_PARTY_README}

	# doins doesn't preserve executable bits
	cp -pRP "${ALPINE_PATH}"/{bin,include,jre,lib,man} "${ddest}" || die

	if use examples; then
		cp -pRP "${ALPINE_PATH}"/{demo,sample} "${ddest}" || die
	fi

	# use system-wide cacert store
	rm "${ddest}"/jre/lib/security/cacerts || die
	dosym ../../../../../etc/ssl/certs/java/cacerts "${dest}"/jre/lib/security/cacerts

	java-vm_install-env "${FILESDIR}/icedtea-bin.env.sh"

	# Both icedtea itself and the icedtea ebuild set PAX markings but we
	# disable them for the icedtea-bin build because the line below will
	# respect end-user settings when icedtea-bin is actually installed.
	java-vm_set-pax-markings "${ddest}"

	# Each invocation appends to the config.
	java-vm_revdep-mask "${EPREFIX}${dest}"
	java-vm_sandbox-predict /proc/self/coredump_filter
}
