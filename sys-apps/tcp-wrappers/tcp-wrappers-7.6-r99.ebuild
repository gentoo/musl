# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/tcp-wrappers/tcp-wrappers-7.6-r8.ebuild,v 1.26 2013/05/14 05:46:04 radhermit Exp $

inherit eutils toolchain-funcs multilib

MY_P="${P//-/_}"
PATCH_VER="1.0"
DESCRIPTION="TCP Wrappers"
HOMEPAGE="ftp://ftp.porcupine.org/pub/security/index.html"
SRC_URI="ftp://ftp.porcupine.org/pub/security/${MY_P}.tar.gz
	mirror://gentoo/${P}-patches-${PATCH_VER}.tar.bz2"

LICENSE="tcp_wrappers_license"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="ipv6"

S=${WORKDIR}/${MY_P}

src_unpack() {
	unpack ${A}
	cd "${S}"

	chmod ug+w Makefile

	EPATCH_SUFFIX="patch"
	PATCHDIR=${WORKDIR}/${PV}
	epatch ${PATCHDIR}/${P}-makefile.patch
	epatch ${PATCHDIR}/generic
	epatch ${PATCHDIR}/${P}-shared.patch
	use ipv6 && epatch ${PATCHDIR}/${P}-ipv6-1.14.diff

	epatch "${FILESDIR}"/${P}-remove-DECLS.patch
}

src_compile() {
	tc-export AR CC RANLIB

	local myconf="-DHAVE_WEAKSYMS"
	use ipv6 && myconf="${myconf} -DINET6=1 -Dss_family=__ss_family -Dss_len=__ss_len"

	emake \
		REAL_DAEMON_DIR=/usr/sbin \
		GENTOO_OPT="${myconf}" \
		MAJOR=0 MINOR=${PV:0:1} REL=${PV:2:3} \
		config-check || die "emake config-check failed"

	emake \
		REAL_DAEMON_DIR=/usr/sbin \
		GENTOO_OPT="${myconf}" \
		MAJOR=0 MINOR=${PV:0:1} REL=${PV:2:3} \
		linux || die "emake linux failed"
}

src_install() {
	dosbin tcpd tcpdchk tcpdmatch safe_finger try-from || die

	doman *.[358]
	dosym hosts_access.5 /usr/share/man/man5/hosts.allow.5
	dosym hosts_access.5 /usr/share/man/man5/hosts.deny.5

	insinto /usr/include
	doins tcpd.h

	into /usr
	dolib.a libwrap.a

	into /
	newlib.so libwrap.so libwrap.so.0.${PV}
	dosym libwrap.so.0.${PV} /$(get_libdir)/libwrap.so.0
	dosym libwrap.so.0 /$(get_libdir)/libwrap.so
	# bug #4411
	gen_usr_ldscript libwrap.so || die "gen_usr_ldscript failed"

	dodoc BLURB CHANGES DISCLAIMER README* "${FILESDIR}"/hosts.allow.example
}
