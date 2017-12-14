# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

LLVM_MAX_SLOT=4
PYTHON_COMPAT=( python2_7 )

inherit python-any-r1 versionator toolchain-funcs llvm

if [[ ${PV} = *beta* ]]; then
	betaver=${PV//*beta}
	BETA_SNAPSHOT="${betaver:0:4}-${betaver:4:2}-${betaver:6:2}"
	MY_P="rustc-beta"
	SLOT="beta/${PV}"
	SRC="${BETA_SNAPSHOT}/rustc-beta-src.tar.xz"
	KEYWORDS=""
else
	ABI_VER="$(get_version_component_range 1-2)"
	SLOT="stable/${ABI_VER}"
	MY_P="rustc-${PV}"
	SRC="${MY_P}-src.tar.xz"
	KEYWORDS="~amd64 ~arm ~x86"
fi

case "${CHOST}" in
	armv7a-hardfloat-*)
		RUSTARCH=armv7 ;;
	arm*)
		RUSTARCH=arm ;;
	*)
		RUSTARCH=${CHOST%%-*} ;;
esac
case "${CHOST}" in
	armv7a-hardfloat-*)
		RUSTLIBC=${ELIBC/glibc/gnu}eabihf ;;
	arm*)
		RUSTLIBC=${ELIBC/glibc/gnu}eabi ;;
	*)
		RUSTLIBC=${ELIBC/glibc/gnu} ;;
esac
RUSTHOST=${RUSTARCH}-unknown-${KERNEL}-${RUSTLIBC}
STAGE0_VERSION="1.$(($(get_version_component_range 2) - 1)).0"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.xz
	amd64? (
		elibc_glibc? ( https://static.rust-lang.org/dist/rust-${STAGE0_VERSION}-x86_64-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/rust-${STAGE0_VERSION}-x86_64-unknown-linux-musl.tar.xz )
	)
	arm? (
		elibc_glibc? (
			https://static.rust-lang.org/dist/rust-${STAGE0_VERSION}-arm-unknown-linux-gnueabi.tar.xz
			https://static.rust-lang.org/dist/rust-${STAGE0_VERSION}-armv7-unknown-linux-gnueabihf.tar.xz
		)
		elibc_musl? (
			https://portage.smaeul.xyz/distfiles/rust-${STAGE0_VERSION}-arm-unknown-linux-musleabi.tar.xz
			https://portage.smaeul.xyz/distfiles/rust-${STAGE0_VERSION}-armv7-unknown-linux-musleabihf.tar.xz
		)
	)
	x86? (
		elibc_glibc? ( https://static.rust-lang.org/dist/rust-${STAGE0_VERSION}-i686-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/rust-${STAGE0_VERSION}-i686-unknown-linux-musl.tar.xz )
	)
"

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="debug doc jemalloc system-llvm"

RDEPEND="
	system-llvm? ( sys-devel/llvm:4 )
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	>=sys-devel/gcc-4.7
	!system-llvm? (
		>=dev-util/cmake-3.4.3
		dev-util/ninja
	)
"

PDEPEND=">=app-eselect/eselect-rust-0.3_pre20150425
	dev-util/cargo"

PATCHES=(
	"${FILESDIR}/0001-Explicitly-run-perl-for-OpenSSL-Configure.patch"
	"${FILESDIR}/0002-Require-rlibs-for-dependent-crates-when-linking-stat.patch"
	"${FILESDIR}/0003-Adjust-dependency-resolution-errors-to-be-more-consi.patch"
	"${FILESDIR}/0004-Require-static-native-libraries-when-linking-static-.patch"
	"${FILESDIR}/0005-Remove-nostdlib-and-musl_root-from-musl-targets.patch"
	"${FILESDIR}/0006-Prefer-libgcc_eh-over-libunwind-for-musl.patch"
	"${FILESDIR}/0007-Fix-LLVM-build.patch"
	"${FILESDIR}/0008-Add-openssl-configuration-for-musl-targets.patch"
	"${FILESDIR}/0009-liblibc.patch"
	"${FILESDIR}/0010-static-linking-default.patch"
	"${FILESDIR}/llvm-musl-fixes.patch"
)

S="${WORKDIR}/${MY_P}-src"

toml_usex() {
	usex "$1" true false
}

pkg_setup() {
	export RUST_BACKTRACE=1
	if use system-llvm; then
		llvm_pkg_setup
		local llvm_config="$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"

		export LLVM_LINK_SHARED=1
		export RUSTFLAGS="$RUSTFLAGS -Lnative=$("$llvm_config" --libdir)"
	fi

	python-any-r1_pkg_setup
}

src_prepare() {
	default

	"${WORKDIR}/rust-${STAGE0_VERSION}-${RUSTHOST}/install.sh" \
		--prefix="${WORKDIR}/stage0" \
		--components=rust-std-${RUSTHOST},rustc,cargo \
		--disable-ldconfig \
		|| die
}

src_configure() {
	cat <<- EOF > "${S}"/config.toml
	[llvm]
	ninja = true
	optimize = $(toml_usex !debug)
	assertions = $(toml_usex debug)
	[build]
	build = "${RUSTHOST}"
	host = ["${RUSTHOST}"]
	target = ["${RUSTHOST}"]
	cargo = "${WORKDIR}/stage0/bin/cargo"
	rustc = "${WORKDIR}/stage0/bin/rustc"
	docs = $(toml_usex doc)
	compiler-docs = $(toml_usex doc)
	submodules = false
	python = "${EPYTHON}"
	locked-deps = true
	vendor = true
	verbose = 2
	[install]
	prefix = "${EPREFIX}/usr"
	libdir = "$(get_libdir)/${P}"
	mandir = "share/${P}/man"
	docdir = "share/doc/${P}"
	[rust]
	optimize = $(toml_usex !debug)
	debug-assertions = $(toml_usex debug)
	debuginfo = $(toml_usex debug)
	use-jemalloc = $(toml_usex jemalloc)
	channel = "${SLOT%%/*}"
	rpath = false
	optimize-tests = $(toml_usex !debug)
	[dist]
	src-tarball = false
	[target.${RUSTHOST}]
	cc = "$(tc-getCC)"
	cxx = "$(tc-getCXX)"
	crt-static = false
	EOF
	use system-llvm && cat <<- EOF >> "${S}"/config.toml
	llvm-config = "$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"
	EOF
}

src_compile() {
	./x.py build || die
}

src_install() {
	env DESTDIR="${D}" ./x.py install || die

	rm "${D}/usr/$(get_libdir)/${P}/rustlib/components" || die
	rm "${D}/usr/$(get_libdir)/${P}/rustlib/install.log" || die
	rm "${D}/usr/$(get_libdir)/${P}/rustlib/manifest-rust-std-${RUSTHOST}" || die
	rm "${D}/usr/$(get_libdir)/${P}/rustlib/manifest-rustc" || die
	rm "${D}/usr/$(get_libdir)/${P}/rustlib/rust-installer-version" || die
	rm "${D}/usr/$(get_libdir)/${P}/rustlib/uninstall.sh" || die

	mv "${D}/usr/bin/rustc" "${D}/usr/bin/rustc-${PV}" || die
	mv "${D}/usr/bin/rustdoc" "${D}/usr/bin/rustdoc-${PV}" || die
	mv "${D}/usr/bin/rust-gdb" "${D}/usr/bin/rust-gdb-${PV}" || die
	mv "${D}/usr/bin/rust-lldb" "${D}/usr/bin/rust-lldb-${PV}" || die

	if use doc; then
		rm "${D}/usr/$(get_libdir)/${P}/rustlib/manifest-rust-docs" || die
	fi

	rm "${D}/usr/share/doc/${P}/LICENSE-MIT" || die
	rm "${D}/usr/share/doc/${P}/LICENSE-APACHE" || die

	docompress "${D}/usr/share/${P}/man"
	dodoc COPYRIGHT

	cat <<-EOF > "${T}"/50${P}
	LDPATH="/usr/$(get_libdir)/${P}"
	MANPATH="/usr/share/${P}/man"
	EOF
	doenvd "${T}"/50${P}

	cat <<-EOF > "${T}/provider-${P}"
	/usr/bin/rustdoc
	/usr/bin/rust-gdb
	/usr/bin/rust-lldb
	EOF
	dodir /etc/env.d/rust
	insinto /etc/env.d/rust
	doins "${T}/provider-${P}"
}

pkg_postinst() {
	eselect rust update --if-unset

	elog "Rust installs a helper script for calling GDB now,"
	elog "for your convenience it is installed under /usr/bin/rust-gdb-${PV}."

	if has_version app-editors/emacs || has_version app-editors/emacs-vcs; then
		elog "install app-emacs/rust-mode to get emacs support for rust."
	fi

	if has_version app-editors/gvim || has_version app-editors/vim; then
		elog "install app-vim/rust-vim to get vim support for rust."
	fi

	if has_version 'app-shells/zsh'; then
		elog "install app-shells/rust-zshcomp to get zsh completion for rust."
	fi
}

pkg_postrm() {
	eselect rust unset --if-invalid
}
