# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/ruby/ruby-2.0.0_p353.ebuild,v 1.6 2013/12/15 17:44:01 ago Exp $

EAPI=5

#PATCHSET=1

inherit autotools eutils flag-o-matic multilib versionator

RUBYPL=$(get_version_component_range 4)

MY_P="${PN}-$(get_version_component_range 1-3)-${RUBYPL:-0}"
S=${WORKDIR}/${MY_P}

SLOT=$(get_version_component_range 1-2)
MY_SUFFIX=$(delete_version_separator 1 ${SLOT})
RUBYVERSION=2.0.0

if [[ -n ${PATCHSET} ]]; then
	if [[ ${PVR} == ${PV} ]]; then
		PATCHSET="${PV}-r0.${PATCHSET}"
	else
		PATCHSET="${PVR}.${PATCHSET}"
	fi
else
	PATCHSET="${PVR}"
fi

DESCRIPTION="An object-oriented scripting language"
HOMEPAGE="http://www.ruby-lang.org/"
SRC_URI="mirror://ruby/2.0/${MY_P}.tar.bz2
		 http://dev.gentoo.org/~flameeyes/ruby-team/${PN}-patches-${PATCHSET}.tar.bz2"

LICENSE="|| ( Ruby-BSD BSD-2 )"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="berkdb debug doc examples gdbm ipv6 +rdoc rubytests socks5 ssl tk xemacs ncurses +readline"

RDEPEND="
	berkdb? ( sys-libs/db )
	gdbm? ( sys-libs/gdbm )
	ssl? ( dev-libs/openssl )
	socks5? ( >=net-proxy/dante-1.1.13 )
	tk? ( dev-lang/tk[threads] )
	ncurses? ( sys-libs/ncurses )
	readline?  ( sys-libs/readline )
	dev-libs/libyaml
	virtual/libffi
	sys-libs/zlib
	>=app-eselect/eselect-ruby-20100402
	!<dev-ruby/rdoc-3.9.4
	!<dev-ruby/rubygems-1.8.10-r1"

DEPEND="${RDEPEND}"
PDEPEND="
	>=dev-ruby/rubygems-2.0.2[ruby_targets_ruby20]
	>=dev-ruby/json-1.7.7[ruby_targets_ruby20]
	>=dev-ruby/rake-0.9.6[ruby_targets_ruby20]
	rdoc? ( >=dev-ruby/rdoc-4.0.0[ruby_targets_ruby20] )
	xemacs? ( app-xemacs/ruby-modes )"

src_prepare() {
	EPATCH_FORCE="yes" EPATCH_SUFFIX="patch" \
		epatch "${WORKDIR}/patches"

	epatch "${FILESDIR}"/${PN}-uclibc-isnan-isinf.patch
	epatch "${FILESDIR}"/${PN}-add-asm_ioctl_h.patch

	# We can no longer unbundle all of rake because rubygems now depends
	# on this. We leave the actual rake code around to bootstrap
	# rubygems, but remove the bits that would cause a file collision.
	einfo "Unbundling gems..."
	cd "$S"
	rm -r \
		{bin,lib}/rake lib/rake.rb man/rake.1 \
		bin/gem || die "removal failed"

	# Fix a hardcoded lib path in configure script
	sed -i -e "s:\(RUBY_LIB_PREFIX=\"\${prefix}/\)lib:\1$(get_libdir):" \
		configure.in || die "sed failed"

	eautoreconf
}

src_configure() {
	local myconf=

	# -fomit-frame-pointer makes ruby segfault, see bug #150413.
	filter-flags -fomit-frame-pointer
	# In many places aliasing rules are broken; play it safe
	# as it's risky with newer compilers to leave it as it is.
	append-flags -fno-strict-aliasing
	# SuperH needs this
	use sh && append-flags -mieee

	# Socks support via dante
	if use socks5 ; then
		# Socks support can't be disabled as long as SOCKS_SERVER is
		# set and socks library is present, so need to unset
		# SOCKS_SERVER in that case.
		unset SOCKS_SERVER
	fi

	# Increase GC_MALLOC_LIMIT if set (default is 8000000)
	if [ -n "${RUBY_GC_MALLOC_LIMIT}" ] ; then
		append-flags "-DGC_MALLOC_LIMIT=${RUBY_GC_MALLOC_LIMIT}"
	fi

	# ipv6 hack, bug 168939. Needs --enable-ipv6.
	use ipv6 || myconf="${myconf} --with-lookup-order-hack=INET"

#	if use libedit; then
#		einfo "Using libedit to provide readline extension"
#		myconf="${myconf} --enable-libedit --with-readline"
#	elif use readline; then
#		einfo "Using readline to provide readline extension"
#		myconf="${myconf} --with-readline"
#	else
#		myconf="${myconf} --without-readline"
#	fi
	myconf="${myconf} $(use_with readline)"

	INSTALL="${EPREFIX}/usr/bin/install -c" econf \
		--program-suffix=${MY_SUFFIX} \
		--with-soname=ruby${MY_SUFFIX} \
		--enable-shared \
		--enable-pthread \
		--enable-psych \
		--disable-rpath \
		$(use_enable socks5 socks) \
		$(use_enable doc install-doc) \
		--enable-ipv6 \
		$(use_enable debug) \
		$(use_with berkdb dbm) \
		$(use_with gdbm) \
		$(use_with ssl openssl) \
		$(use_with tk) \
		$(use_with ncurses curses) \
		${myconf} \
		--enable-option-checking=no \
		|| die "econf failed"
}

src_compile() {
	emake V=1 EXTLDFLAGS="${LDFLAGS}" || die "emake failed"
}

src_test() {
	emake -j1 V=1 test || die "make test failed"

	elog "Ruby's make test has been run. Ruby also ships with a make check"
	elog "that cannot be run until after ruby has been installed."
	elog
	if use rubytests; then
		elog "You have enabled rubytests, so they will be installed to"
		elog "/usr/share/${PN}-${SLOT}/test. To run them you must be a user other"
		elog "than root, and you must place them into a writeable directory."
		elog "Then call: "
		elog
		elog "ruby${MY_SUFFIX} -C /location/of/tests runner.rb"
	else
		elog "Enable the rubytests USE flag to install the make check tests"
	fi
}

src_install() {
	# Remove the remaining bundled gems. We do this late in the process
	# since they are used during the build to e.g. create the
	# documentation.
	rm -rf ext/json || die

	# Ruby is involved in the install process, we don't want interference here.
	unset RUBYOPT

	local MINIRUBY=$(echo -e 'include Makefile\ngetminiruby:\n\t@echo $(MINIRUBY)'|make -f - getminiruby)

	LD_LIBRARY_PATH="${D}/usr/$(get_libdir)${LD_LIBRARY_PATH+:}${LD_LIBRARY_PATH}"
	RUBYLIB="${S}:${D}/usr/$(get_libdir)/ruby/${RUBYVERSION}"
	for d in $(find "${S}/ext" -type d) ; do
		RUBYLIB="${RUBYLIB}:$d"
	done
	export LD_LIBRARY_PATH RUBYLIB

	emake V=1 DESTDIR="${D}" install || die "make install failed"

	# Remove installed rubygems copy
	rm -r "${D}/usr/$(get_libdir)/ruby/${RUBYVERSION}/rubygems" || die "rm rubygems failed"
	rm -r "${D}/usr/$(get_libdir)/ruby/${RUBYVERSION}"/rdoc* || die "rm rdoc failed"
	rm -r "${D}/usr/bin/"{ri,rdoc}"${MY_SUFFIX}" || die "rm rdoc bins failed"

	if use doc; then
		make DESTDIR="${D}" install-doc || die "make install-doc failed"
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r sample
	fi

	dosym "libruby${MY_SUFFIX}$(get_libname ${PV%_*})" \
		"/usr/$(get_libdir)/libruby$(get_libname ${PV%.*})"
	dosym "libruby${MY_SUFFIX}$(get_libname ${PV%_*})" \
		"/usr/$(get_libdir)/libruby$(get_libname ${PV%_*})"

	dodoc ChangeLog NEWS doc/NEWS* README* || die

	if use rubytests; then
		pushd test
		insinto /usr/share/${PN}-${SLOT}/test
		doins -r .
		popd
	fi
}

pkg_postinst() {
	if [[ ! -n $(readlink "${ROOT}"usr/bin/ruby) ]] ; then
		eselect ruby set ruby${MY_SUFFIX}
	fi

	elog
	elog "To switch between available Ruby profiles, execute as root:"
	elog "\teselect ruby set ruby(18|19|...)"
	elog
}

pkg_postrm() {
	eselect ruby cleanup
}
