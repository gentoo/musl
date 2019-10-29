# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python{2_7,3_{5,6,7}} )

inherit check-reqs eapi7-ver flag-o-matic llvm multiprocessing python-any-r1 toolchain-funcs

ABI_VER="$(ver_cut 1-2)"
SLOT="stable/${ABI_VER}"
MY_P="rustc-${PV}"
SRC="${MY_P}-src.tar.xz"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"

RUST_STAGE0_VERSION="1.$(($(ver_cut 2) - 1)).0"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.xz
	amd64? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-x86_64-gentoo-linux-musl.tar.xz )
	arm? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-armv7a-unknown-linux-musleabihf.tar.xz )
	arm64? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-aarch64-gentoo-linux-musl.tar.xz )
	ppc? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-powerpc-gentoo-linux-musl.tar.xz )
	ppc64? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-powerpc64-gentoo-linux-musl.tar.xz )
	x86? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-i686-gentoo-linux-musl.tar.xz )
"

ALL_LLVM_TARGETS=( AArch64 AMDGPU ARM BPF Hexagon Lanai Mips MSP430
	NVPTX PowerPC Sparc SystemZ WebAssembly X86 XCore )
ALL_LLVM_TARGETS=( "${ALL_LLVM_TARGETS[@]/#/llvm_targets_}" )
LLVM_TARGET_USEDEPS=${ALL_LLVM_TARGETS[@]/%/?}

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="clippy cpu_flags_x86_sse2 debug doc libressl rls rustfmt system-llvm ${ALL_LLVM_TARGETS[*]}"

# Please keep the LLVM dependency block separate. Since LLVM is slotted,
# we need to *really* make sure we're not pulling one than more slot
# simultaneously.

# How to use it:
# 1. List all the working slots (with min versions) in ||, newest first.
# 2. Update the := to specify *max* version, e.g. < 9.
# 3. Specify LLVM_MAX_SLOT, e.g. 8.
LLVM_DEPEND="
	|| (
		>=sys-devel/llvm-8:=[${LLVM_TARGET_USEDEPS// /,}]
	)
	<sys-devel/llvm-9:=
"
LLVM_MAX_SLOT=8

COMMON_DEPEND="
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	net-libs/http-parser:=
	net-libs/libssh2:=
	net-misc/curl:=[ssl]
	sys-libs/zlib:=
	system-llvm? (
		${LLVM_DEPEND}
	)
"
DEPEND="${COMMON_DEPEND}
	${PYTHON_DEPS}
	|| (
		>=sys-devel/gcc-4.7
		>=sys-devel/clang-3.5
	)
	!system-llvm? (
		dev-util/cmake
		dev-util/ninja
	)
"
RDEPEND="${COMMON_DEPEND}
	>=app-eselect/eselect-rust-20190311
	!dev-util/cargo
	rustfmt? ( !dev-util/rustfmt )"
REQUIRED_USE="|| ( ${ALL_LLVM_TARGETS[*]} )
	x86? ( cpu_flags_x86_sse2 )
"

PATCHES=(
	"${FILESDIR}/0001-Don-t-pass-CFLAGS-to-the-C-compiler.patch"
	"${FILESDIR}/0002-Fix-LLVM-build.patch"
	"${FILESDIR}/0003-Allow-rustdoc-to-work-when-cross-compiling-on-musl.patch"
	"${FILESDIR}/0004-Require-static-native-libraries-when-linking-static-.patch"
	"${FILESDIR}/0005-Remove-nostdlib-and-musl_root-from-musl-targets.patch"
	"${FILESDIR}/0006-Prefer-libgcc_eh-over-libunwind-for-musl.patch"
	"${FILESDIR}/0007-runtest-Fix-proc-macro-tests-on-musl-hosts.patch"
	"${FILESDIR}/0008-Correct-minimum-system-LLVM-version-in-tests.patch"
	"${FILESDIR}/0009-test-use-extern-for-plugins-Don-t-assume-multilib.patch"
	"${FILESDIR}/0010-test-sysroot-crates-are-unstable-Fix-test-when-rpath.patch"
	"${FILESDIR}/0011-Ignore-broken-and-non-applicable-tests.patch"
	"${FILESDIR}/0012-Link-stage-2-tools-dynamically-to-libstd.patch"
	"${FILESDIR}/0013-Move-debugger-scripts-to-usr-share-rust.patch"
	"${FILESDIR}/0014-Add-gentoo-target-specs.patch"
	"${FILESDIR}/0030-liblibc-linkage.patch"
	"${FILESDIR}/0040-rls-atomics.patch"
	"${FILESDIR}/0050-llvm.patch"
	"${FILESDIR}/0051-llvm-D45520.patch"
	"${FILESDIR}/0052-llvm-D52013.patch"
	"${FILESDIR}/0053-llvm-secureplt.patch"
	"${FILESDIR}/0060-fix-build-with-libressl-2.9.1.patch"
)

S="${WORKDIR}/${MY_P}-src"

toml_usex() {
	usex "$1" true false
}

pre_build_checks() {
	CHECKREQS_DISK_BUILD="7G"
	eshopts_push -s extglob
	if is-flagq '-g?(gdb)?([1-9])'; then
		CHECKREQS_DISK_BUILD="10G"
	fi
	eshopts_pop
	check-reqs_pkg_setup
}

pkg_pretend() {
	pre_build_checks
}

pkg_setup() {
	export RUST_BACKTRACE=1
	pre_build_checks
	python-any-r1_pkg_setup
	if use system-llvm; then
		llvm_pkg_setup
		local llvm_config="$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"

		export LLVM_LINK_SHARED=1
		export RUSTFLAGS="$RUSTFLAGS -Lnative=$("$llvm_config" --libdir)"
	fi
}

src_prepare() {
	default

	"${WORKDIR}/rust-${RUST_STAGE0_VERSION}-${CHOST}/install.sh" \
		--destdir="${WORKDIR}/stage0" \
		--prefix=/ \
		--components=rust-std-$CHOST,rustc,cargo \
		--disable-ldconfig \
		|| die
}

src_configure() {
	local tools='"cargo"'

	for tool in clippy rls rustfmt; do
		if use $tool; then
			tools+=", \"$tool\""
		fi
	done

	cat <<- EOF > "${S}"/config.toml
		[llvm]
		ninja = true
		optimize = $(toml_usex !debug)
		release-debuginfo = $(toml_usex debug)
		assertions = $(toml_usex debug)
		targets = "${LLVM_TARGETS// /;}"
		experimental-targets = ""
		link-shared = $(toml_usex system-llvm)
		[build]
		build = "${CHOST}"
		host = ["${CHOST}"]
		target = ["${CHOST}"]
		cargo = "${WORKDIR}/stage0/bin/cargo"
		rustc = "${WORKDIR}/stage0/bin/rustc"
		docs = $(toml_usex doc)
		compiler-docs = $(toml_usex doc)
		submodules = false
		python = "${EPYTHON}"
		locked-deps = true
		vendor = true
		verbose = 0
		sanitizers = false
		profiler = false
		extended = true
		tools = [${tools}]
		[install]
		prefix = "${EPREFIX}/usr"
		libdir = "lib"
		docdir = "share/doc/${P}"
		mandir = "share/${P}/man"
		[rust]
		optimize = $(toml_usex !debug)
		debuginfo = $(toml_usex debug)
		debug-assertions = $(toml_usex debug)
		default-linker = "$(tc-getCC)"
		channel = "stable"
		rpath = false
		optimize-tests = $(toml_usex !debug)
		dist-src = false
		jemalloc = false
		[dist]
		src-tarball = false
		[target.${CHOST}]
		cc = "$(tc-getCC)"
		cxx = "$(tc-getCXX)"
		linker = "$(tc-getCC)"
		ar = "$(tc-getAR)"
	EOF
	use system-llvm && cat <<- EOF >> "${S}"/config.toml
		llvm-config = "$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"
	EOF
}

src_compile() {
	"${EPYTHON}" x.py build --config="${S}"/config.toml -j$(makeopts_jobs) --exclude src/tools/miri || die
}

src_test() {
	"${EPYTHON}" x.py test -j$(makeopts_jobs) --no-doc --no-fail-fast \
		src/test/codegen \
		src/test/codegen-units \
		src/test/compile-fail \
		src/test/incremental \
		src/test/mir-opt \
		src/test/pretty \
		src/test/run-fail \
		src/test/run-fail/pretty \
		src/test/run-make \
		src/test/run-make-fulldeps \
		src/test/run-pass \
		src/test/run-pass/pretty \
		src/test/run-pass-fulldeps \
		src/test/run-pass-fulldeps/pretty \
		src/test/ui \
		src/test/ui-fulldeps || die
}

src_install() {
	env DESTDIR="${D}" "${EPYTHON}" x.py install || die

	mv "${ED}/usr/bin/cargo" "${ED}/usr/bin/cargo-${PV}" || die
	mv "${ED}/usr/bin/rustc" "${ED}/usr/bin/rustc-${PV}" || die
	mv "${ED}/usr/bin/rustdoc" "${ED}/usr/bin/rustdoc-${PV}" || die
	mv "${ED}/usr/bin/rust-gdb" "${ED}/usr/bin/rust-gdb-${PV}" || die
	mv "${ED}/usr/bin/rust-gdbgui" "${ED}/usr/bin/rust-gdbgui-${PV}" || die
	mv "${ED}/usr/bin/rust-lldb" "${ED}/usr/bin/rust-lldb-${PV}" || die

	rm "${ED}/usr/lib"/*.so || die
	rm "${ED}/usr/lib/rustlib/components" || die
	rm "${ED}/usr/lib/rustlib/install.log" || die
	rm "${ED}/usr/lib/rustlib"/manifest-* || die
	rm "${ED}/usr/lib/rustlib/rust-installer-version" || die
	rm "${ED}/usr/lib/rustlib/uninstall.sh" || die

	if use clippy; then
		mv "${ED}/usr/bin/cargo-clippy" "${ED}/usr/bin/cargo-clippy-${PV}" || die
		mv "${ED}/usr/bin/clippy-driver" "${ED}/usr/bin/clippy-driver-${PV}" || die
	fi
	if use rls; then
		mv "${ED}/usr/bin/rls" "${ED}/usr/bin/rls-${PV}" || die
	fi
	if use rustfmt; then
		mv "${ED}/usr/bin/cargo-fmt" "${ED}/usr/bin/cargo-fmt-${PV}" || die
		mv "${ED}/usr/bin/rustfmt" "${ED}/usr/bin/rustfmt-${PV}" || die
	fi

	if use doc; then
		dodir "/usr/share/doc/${P}"
		mv "${ED}/usr/share/doc/rust"/* "${ED}/usr/share/doc/${P}" || die
		rmdir "${ED}/usr/share/doc/rust" || die
	fi

	dodoc COPYRIGHT
	rm "${ED}/usr/share/doc/${P}"/*.old || die
	rm "${ED}/usr/share/doc/${P}/LICENSE-APACHE" || die
	rm "${ED}/usr/share/doc/${P}/LICENSE-MIT" || die

	docompress "/usr/share/${P}/man"

	cat <<-EOF > "${T}"/50${P}
		LDPATH="${EPREFIX}/usr/lib/rustlib/${CHOST}/lib"
		MANPATH="${EPREFIX}/usr/share/${P}/man"
	EOF
	doenvd "${T}"/50${P}

	# note: eselect-rust adds EROOT to all paths below
	cat <<-EOF > "${T}/provider-${P}"
		/usr/bin/cargo
		/usr/bin/rustdoc
		/usr/bin/rust-gdb
		/usr/bin/rust-gdbgui
		/usr/bin/rust-lldb
	EOF
	if use clippy; then
		echo /usr/bin/cargo-clippy >> "${T}/provider-${P}"
		echo /usr/bin/clippy-driver >> "${T}/provider-${P}"
	fi
	if use rls; then
		echo /usr/bin/rls >> "${T}/provider-${P}"
	fi
	if use rustfmt; then
		echo /usr/bin/cargo-fmt >> "${T}/provider-${P}"
		echo /usr/bin/rustfmt >> "${T}/provider-${P}"
	fi
	dodir /etc/env.d/rust
	insinto /etc/env.d/rust
	doins "${T}/provider-${P}"
}

pkg_postinst() {
	eselect rust update --if-unset

	elog "Rust installs a helper script for calling GDB and LLDB,"
	elog "for your convenience it is installed under /usr/bin/rust-{gdb,lldb}-${PV}."

	ewarn "cargo is now installed from dev-lang/rust{,-bin} instead of dev-util/cargo."
	ewarn "This might have resulted in a dangling symlink for /usr/bin/cargo on some"
	ewarn "systems. This can be resolved by calling 'sudo eselect rust set ${P}'."

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
