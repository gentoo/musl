# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} )

inherit bash-completion-r1 check-reqs estack flag-o-matic llvm multiprocessing multilib-build python-any-r1 rust-toolchain toolchain-funcs

ABI_VER="$(ver_cut 1-2)"
SLOT="stable/${ABI_VER}"
MY_P="rustc-${PV}"
SRC="${MY_P}-src.tar.xz"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"

RUST_STAGE0_VERSION="1.$(($(ver_cut 2) - 1)).0"
RUST_TOOLCHAIN_BASEURL="https://portage.smaeul.xyz/distfiles/"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="
	https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.xz
	!system-bootstrap? (
		amd64? ( $(rust_arch_uri x86_64-gentoo-linux-musl        rust-${RUST_STAGE0_VERSION} ) )
		arm?   ( $(rust_arch_uri armv7a-unknown-linux-musleabihf rust-${RUST_STAGE0_VERSION} ) )
		arm64? ( $(rust_arch_uri aarch64-gentoo-linux-musl       rust-${RUST_STAGE0_VERSION} ) )
		ppc?   ( $(rust_arch_uri powerpc-gentoo-linux-musl       rust-${RUST_STAGE0_VERSION} ) )
		ppc64? ( $(rust_arch_uri powerpc64-gentoo-linux-musl     rust-${RUST_STAGE0_VERSION} ) )
		x86?   ( $(rust_arch_uri i686-gentoo-linux-musl          rust-${RUST_STAGE0_VERSION} ) )
	)
"

# keep in sync with llvm ebuild of the same version as bundled one.
ALL_LLVM_TARGETS=( AArch64 AMDGPU ARM AVR BPF Hexagon Lanai Mips MSP430
	NVPTX PowerPC RISCV Sparc SystemZ WebAssembly X86 XCore )
ALL_LLVM_TARGETS=( "${ALL_LLVM_TARGETS[@]/#/llvm_targets_}" )
LLVM_TARGET_USEDEPS=${ALL_LLVM_TARGETS[@]/%/?}

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="clippy cpu_flags_arm_neon cpu_flags_arm_thumb2 cpu_flags_x86_sse2 debug doc libressl miri nightly parallel-compiler rls rustfmt +system-bootstrap system-llvm test wasm ${ALL_LLVM_TARGETS[*]}"

# Please keep the LLVM dependency block separate. Since LLVM is slotted,
# we need to *really* make sure we're not pulling more than one slot
# simultaneously.

# How to use it:
# 1. List all the working slots (with min versions) in ||, newest first.
# 2. Update the := to specify *max* version, e.g. < 12.
# 3. Specify LLVM_MAX_SLOT, e.g. 11.
LLVM_DEPEND="
	|| (
		sys-devel/llvm:11[${LLVM_TARGET_USEDEPS// /,}]
	)
	<sys-devel/llvm-12:=
"
LLVM_MAX_SLOT=11

BOOTSTRAP_DEPEND="|| ( >=dev-lang/rust-1.$(($(ver_cut 2) - 1)) >=dev-lang/rust-bin-1.$(($(ver_cut 2) - 1)) )"

BDEPEND="
	${PYTHON_DEPS}
	app-eselect/eselect-rust
	|| (
		>=sys-devel/gcc-4.7
		>=sys-devel/clang-3.5
	)
	system-bootstrap? ( ${BOOTSTRAP_DEPEND}	)
	!system-llvm? (
		dev-util/cmake
		dev-util/ninja
	)
"

# libgit2 should be at least same as bundled into libgit-sys #707746
DEPEND="
	>=dev-libs/libgit2-0.99:=
	net-libs/libssh2:=
	net-libs/http-parser:=
	net-misc/curl:=[http2,ssl]
	elibc_musl? ( >=sys-libs/musl-1.2.1-r2 )
	sys-libs/zlib:=
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	system-llvm? (
		${LLVM_DEPEND}
		wasm? ( sys-devel/lld )
	)
"

RDEPEND="${DEPEND}
	app-eselect/eselect-rust
"

REQUIRED_USE="|| ( ${ALL_LLVM_TARGETS[*]} )
	miri? ( nightly )
	parallel-compiler? ( nightly )
	test? ( ${ALL_LLVM_TARGETS[*]} )
	wasm? ( llvm_targets_WebAssembly )
	x86? ( cpu_flags_x86_sse2 )
"

# we don't use cmake.eclass, but can get a warnings
CMAKE_WARN_UNUSED_CLI=no

QA_FLAGS_IGNORED="
	usr/lib/${PN}/${PV}/bin/.*
	usr/lib/${PN}/${PV}/lib/lib.*.so
	usr/lib/${PN}/${PV}/lib/rustlib/.*/bin/.*
	usr/lib/${PN}/${PV}/lib/rustlib/.*/lib/lib.*.so
"

QA_SONAME="
	usr/lib/${PN}/${PV}/lib/lib.*.so.*
	usr/lib/${PN}/${PV}/lib/rustlib/.*/lib/lib.*.so
"

# causes double bootstrap
RESTRICT="test"

PATCHES=(
	"${FILESDIR}"/1.46.0-don-t-create-prefix-at-time-of-check.patch
	"${FILESDIR}"/1.47.0-libressl.patch
	"${FILESDIR}"/0001-Don-t-pass-CFLAGS-to-the-C-compiler.patch
	"${FILESDIR}"/0002-Fix-LLVM-build.patch
	"${FILESDIR}"/0003-Fix-linking-to-zlib-when-cross-compiling.patch
	"${FILESDIR}"/0004-Fix-rustdoc-when-cross-compiling-on-musl.patch
	"${FILESDIR}"/0005-Use-static-native-libraries-when-linking-static-exec.patch
	"${FILESDIR}"/0006-Remove-musl_root-and-CRT-fallback-from-musl-targets.patch
	"${FILESDIR}"/0007-Prefer-libgcc_eh-over-libunwind-for-musl.patch
	"${FILESDIR}"/0008-Link-libssp_nonshared.a-on-all-musl-targets.patch
	"${FILESDIR}"/0009-test-failed-doctest-output-Fix-normalization.patch
	"${FILESDIR}"/0010-test-sysroot-crates-are-unstable-Fix-test-when-rpath.patch
	"${FILESDIR}"/0011-test-use-extern-for-plugins-Don-t-assume-multilib.patch
	"${FILESDIR}"/0012-Ignore-broken-and-non-applicable-tests.patch
	"${FILESDIR}"/0013-Link-stage-2-tools-dynamically-to-libstd.patch
	"${FILESDIR}"/0014-Move-debugger-scripts-to-usr-share-rust.patch
	"${FILESDIR}"/0015-Add-gentoo-target-specs.patch
	"${FILESDIR}"/0030-libc-linkage.patch
	"${FILESDIR}"/0040-rls-atomics.patch
	"${FILESDIR}"/0050-llvm.patch
	"${FILESDIR}"/0051-llvm-powerpc-elfv2.patch
)

S="${WORKDIR}/${MY_P}-src"

toml_usex() {
	usex "$1" true false
}

pre_build_checks() {
	local M=6144
	M=$(( $(usex clippy 128 0) + ${M} ))
	M=$(( $(usex miri 128 0) + ${M} ))
	M=$(( $(usex rls 512 0) + ${M} ))
	M=$(( $(usex rustfmt 256 0) + ${M} ))
	M=$(( $(usex system-llvm 0 2048) + ${M} ))
	M=$(( $(usex wasm 256 0) + ${M} ))
	M=$(( $(usex debug 15 10) * ${M} / 10 ))
	eshopts_push -s extglob
	if is-flagq '-g?(gdb)?([1-9])'; then
		M=$(( 15 * ${M} / 10 ))
	fi
	eshopts_pop
	M=$(( $(usex system-bootstrap 0 1024) + ${M} ))
	M=$(( $(usex doc 256 0) + ${M} ))
	CHECKREQS_DISK_BUILD=${M}M check-reqs_pkg_${EBUILD_PHASE}
}

pkg_pretend() {
	pre_build_checks
}

pkg_setup() {
	pre_build_checks
	python-any-r1_pkg_setup

	# required to link agains system libs, otherwise
	# crates use bundled sources and compile own static version
	export LIBGIT2_SYS_USE_PKG_CONFIG=1
	export LIBSSH2_SYS_USE_PKG_CONFIG=1
	export PKG_CONFIG_ALLOW_CROSS=1

	if use system-llvm; then
		llvm_pkg_setup

		local llvm_config="$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"

		export LLVM_LINK_SHARED=1
		export RUSTFLAGS="${RUSTFLAGS} -Lnative=$("${llvm_config}" --libdir)"
	fi
}

src_prepare() {
	if ! use system-bootstrap; then
		local rust_stage0_root="${WORKDIR}"/rust-stage0
		local rust_stage0="rust-${RUST_STAGE0_VERSION}-${CHOST}"

		"${WORKDIR}/${rust_stage0}"/install.sh --disable-ldconfig \
			--components=rust-std-${CHOST},rustc,cargo \
			--destdir="${rust_stage0_root}" --prefix=/ || die
	fi

	default
}

src_configure() {
	local arch_cflags rust_target="" rust_targets="\"$CHOST\"" tools="\"cargo\""

	# Collect rust target names to compile standard libs for all ABIs.
	for v in $(multilib_get_enabled_abi_pairs); do
		rust_target=$(rust_abi $(get_abi_CHOST ${v##*.}) | sed s/gnu/musl/)
		rust_targets="${rust_targets},\"${rust_target}\""

		if [ "$rust_target" = "armv7-unknown-linux-musleabihf" ] &&
				use cpu_flags_arm_neon && use cpu_flags_arm_thumb2; then
			rust_targets="${rust_targets},\"thumbv7neon-unknown-linux-musleabihf\""
		fi
	done
	if use wasm; then
		rust_targets="${rust_targets},\"wasm32-unknown-unknown\""
		if use system-llvm; then
			# un-hardcode rust-lld linker for this target
			# https://bugs.gentoo.org/715348
			sed -i '/linker:/ s/rust-lld/wasm-ld/' src/librustc_target/spec/wasm32_base.rs || die
		fi
	fi

	if use clippy; then
		tools="\"clippy\",$tools"
	fi
	if use miri; then
		tools="\"miri\",$tools"
	fi
	if use rls; then
		tools="\"rls\",\"analysis\",\"src\",$tools"
	fi
	if use rustfmt; then
		tools="\"rustfmt\",$tools"
	fi

	local rust_stage0_root
	if use system-bootstrap; then
		rust_stage0_root="$(rustc --print sysroot)"
	else
		rust_stage0_root="${WORKDIR}"/rust-stage0
	fi

	rust_target="${CHOST}"

	cat <<- _EOF_ > "${S}"/config.toml
		[llvm]
		optimize = $(toml_usex !debug)
		release-debuginfo = $(toml_usex debug)
		assertions = $(toml_usex debug)
		ninja = true
		targets = "${LLVM_TARGETS// /;}"
		experimental-targets = ""
		link-shared = $(toml_usex system-llvm)
		[build]
		build = "${rust_target}"
		host = ["${rust_target}"]
		target = [${rust_targets}]
		cargo = "${rust_stage0_root}/bin/cargo"
		rustc = "${rust_stage0_root}/bin/rustc"
		docs = $(toml_usex doc)
		compiler-docs = $(toml_usex doc)
		submodules = false
		python = "${EPYTHON}"
		locked-deps = true
		vendor = true
		extended = true
		tools = [${tools}]
		verbose = 2
		sanitizers = false
		profiler = false
		cargo-native-static = false
		[install]
		prefix = "${EPREFIX}/usr/lib/${PN}/${PV}"
		sysconfdir = "etc"
		docdir = "share/doc/rust"
		bindir = "bin"
		libdir = "lib"
		mandir = "share/man"
		[rust]
		# https://github.com/rust-lang/rust/issues/54872
		codegen-units-std = 1
		optimize = true
		debug = $(toml_usex debug)
		debug-assertions = $(toml_usex debug)
		debuginfo-level-rustc = 0
		backtrace = true
		incremental = false
		default-linker = "$(tc-getCC)"
		parallel-compiler = $(toml_usex parallel-compiler)
		channel = "$(usex nightly nightly stable)"
		rpath = false
		verbose-tests = true
		optimize-tests = $(toml_usex !debug)
		codegen-tests = true
		dist-src = false
		remap-debuginfo = true
		lld = $(usex system-llvm false $(toml_usex wasm))
		backtrace-on-ice = true
		jemalloc = false
		[dist]
		src-tarball = false
		[target.${rust_target}]
		cc = "$(tc-getCC)"
		cxx = "$(tc-getCXX)"
		linker = "$(tc-getCC)"
		ar = "$(tc-getAR)"
		crt-static = false
	_EOF_
	if use system-llvm; then
		cat <<- EOF >> "${S}"/config.toml
			llvm-config = "$(get_llvm_prefix "${LLVM_MAX_SLOT}")/bin/llvm-config"
		EOF
	fi

	for v in $(multilib_get_enabled_abi_pairs); do
		rust_target=$(rust_abi $(get_abi_CHOST ${v##*.}) | sed s/gnu/musl/)
		arch_cflags="$(get_abi_CFLAGS ${v##*.})"

		export "CFLAGS_${rust_target//-/_}"="$CFLAGS ${arch_cflags}"

		cat <<- _EOF_ >> "${S}"/config.toml
			[target.${rust_target}]
			cc = "$(tc-getCC)"
			cxx = "$(tc-getCXX)"
			linker = "$(tc-getCC)"
			ar = "$(tc-getAR)"
			crt-static = false
		_EOF_

		if [ "$rust_target" = "armv7-unknown-linux-musleabihf" ] &&
				use cpu_flags_arm_neon && use cpu_flags_arm_thumb2; then
			rust_target=thumbv7neon-unknown-linux-musleabihf

			export "CFLAGS_${rust_target//-/_}"="$CFLAGS ${arch_cflags}"

			cat <<- _EOF_ >> "${S}"/config.toml
				[target.${rust_target}]
				cc = "$(tc-getCC)"
				cxx = "$(tc-getCXX)"
				linker = "$(tc-getCC)"
				ar = "$(tc-getAR)"
				crt-static = false
			_EOF_
		fi
	done

	if use wasm; then
		cat <<- _EOF_ >> "${S}"/config.toml
			[target.wasm32-unknown-unknown]
			linker = "$(usex system-llvm lld rust-lld)"
		_EOF_
	fi

	einfo "Rust configured with the following settings:"
	cat "${S}"/config.toml || die
}

src_compile() {
	RUST_BACKTRACE=1 \
	"${EPYTHON}" ./x.py build -vv --config="${S}"/config.toml -j$(makeopts_jobs) || die
}

src_test() {
	# https://rustc-dev-guide.rust-lang.org/tests/intro.html

	# those are basic and codegen tests.
	local tests=(
		codegen
		codegen-units
		compile-fail
		incremental
		mir-opt
		pretty
		run-make
	)

	# fails if llvm is not built with ALL targets.
	# and known to fail with system llvm sometimes.
	use system-llvm || tests+=( assembly )

	# fragile/expensive/less important tests
	# or tests that require extra builds
	# TODO: instead of skipping, just make some nonfatal.
	if [[ ${ERUST_RUN_EXTRA_TESTS:-no} != no ]]; then
		tests+=(
			rustdoc
			rustdoc-js
			rustdoc-js-std
			rustdoc-ui
			run-make-fulldeps
			ui
			ui-fulldeps
		)
	fi

	local i failed=()
	einfo "rust_src_test: enabled tests ${tests[@]/#/src/test/}"
	for i in "${tests[@]}"; do
		local t="src/test/${i}"
		einfo "rust_src_test: running ${t}"
		if ! RUST_BACKTRACE=1 \
				"${EPYTHON}" ./x.py test -vv --config="${S}"/config.toml \
				-j$(makeopts_jobs) --no-doc --no-fail-fast "${t}"
		then
				failed+=( "${t}" )
				eerror "rust_src_test: ${t} failed"
		fi
	done

	if [[ ${#failed[@]} -ne 0 ]]; then
		eerror "rust_src_test: failure summary: ${failed[@]}"
		die "aborting due to test failures"
	fi
}

src_install() {
	DESTDIR="${D}" \
	"${EPYTHON}" ./x.py install -vv --config="${S}"/config.toml || die

	# bug #689562, #689160
	rm -v "${D}/usr/lib/${PN}/${PV}/etc/bash_completion.d/cargo" || die
	rmdir -v "${D}/usr/lib/${PN}/${PV}"/etc{/bash_completion.d,} || die
	dobashcomp build/tmp/dist/cargo-image/etc/bash_completion.d/cargo

	# Move public shared libs to abi specific libdir
	mv "${ED}/usr/lib/${PN}/${PV}/lib"/*.so "${ED}/usr/lib/${PN}/${PV}/lib/rustlib/${CHOST}/lib" || die

	rm "${ED}/usr/lib/${PN}/${PV}/lib/rustlib/components" || die
	rm "${ED}/usr/lib/${PN}/${PV}/lib/rustlib/install.log" || die
	rm "${ED}/usr/lib/${PN}/${PV}/lib/rustlib"/manifest-* || die
	rm "${ED}/usr/lib/${PN}/${PV}/lib/rustlib/rust-installer-version" || die
	rm "${ED}/usr/lib/${PN}/${PV}/lib/rustlib/uninstall.sh" || die

	local symlinks=(
		cargo
		rustc
		rustdoc
		rust-gdb
		rust-gdbgui
		rust-lldb
	)

	use clippy && symlinks+=( clippy-driver cargo-clippy )
	use miri && symlinks+=( miri cargo-miri )
	use rls && symlinks+=( rls )
	use rustfmt && symlinks+=( rustfmt cargo-fmt )

	einfo "installing eselect-rust symlinks and paths"
	local i
	for i in "${symlinks[@]}"; do
		# we need realpath on /usr/bin/* symlink return version-appended binary path.
		# so /usr/bin/rustc should point to /usr/lib/rust/<ver>/bin/rustc-<ver>
		# need to fix eselect-rust to remove this hack.
		local ver_i="${i}-${PV}"
		mv -v "${ED}/usr/lib/${PN}/${PV}/bin/${i}" "${ED}/usr/lib/${PN}/${PV}/bin/${ver_i}" || die
		ln -v "${ED}/usr/lib/${PN}/${PV}/bin/${ver_i}" "${ED}/usr/lib/${PN}/${PV}/bin/${i}" || die
		dosym "../lib/${PN}/${PV}/bin/${ver_i}" "/usr/bin/${ver_i}"
	done

	# symlinks to switch components to active rust in eselect
	dosym "${PV}/lib" "/usr/lib/${PN}/lib-${PV}"
	dosym "${PV}/share/man" "/usr/lib/${PN}/man-${PV}"
	dosym "${PN}/${PV}/lib/rustlib" "/usr/lib/rustlib-${PV}"
	dosym "../../lib/${PN}/${PV}/share/doc" "/usr/share/doc/${P}"

	newenvd - "50${P}" <<-_EOF_
		LDPATH="${EPREFIX}/usr/lib/${PN}/${PV}/lib/rustlib/${CHOST}/lib"
		MANPATH="${EPREFIX}/usr/lib/rust/man"
	_EOF_

	rm -rf "${ED}/usr/lib/${PN}/${PV}"/*.old || die
	rm -rf "${ED}/usr/lib/${PN}/${PV}/doc"/*.old || die

	# note: eselect-rust adds EROOT to all paths below
	cat <<-_EOF_ > "${T}/provider-${P}"
		/usr/bin/cargo
		/usr/bin/rustdoc
		/usr/bin/rust-gdb
		/usr/bin/rust-gdbgui
		/usr/bin/rust-lldb
		/usr/lib/rustlib
		/usr/lib/rust/lib
		/usr/lib/rust/man
		/usr/share/doc/rust
	_EOF_

	if use clippy; then
		echo /usr/bin/clippy-driver >> "${T}/provider-${P}"
		echo /usr/bin/cargo-clippy >> "${T}/provider-${P}"
	fi
	if use miri; then
		echo /usr/bin/miri >> "${T}/provider-${P}"
		echo /usr/bin/cargo-miri >> "${T}/provider-${P}"
	fi
	if use rls; then
		echo /usr/bin/rls >> "${T}/provider-${P}"
	fi
	if use rustfmt; then
		echo /usr/bin/rustfmt >> "${T}/provider-${P}"
		echo /usr/bin/cargo-fmt >> "${T}/provider-${P}"
	fi

	insinto /etc/env.d/rust
	doins "${T}/provider-${P}"
}

pkg_postinst() {
	eselect rust update --if-unset

	elog "Rust installs a helper script for calling GDB and LLDB,"
	elog "for your convenience it is installed under /usr/bin/rust-{gdb,lldb}-${PV}."

	if has_version app-editors/emacs; then
		elog "install app-emacs/rust-mode to get emacs support for rust."
	fi

	if has_version app-editors/gvim || has_version app-editors/vim; then
		elog "install app-vim/rust-vim to get vim support for rust."
	fi
}

pkg_postrm() {
	eselect rust cleanup
}
