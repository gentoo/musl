# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

LLVM_MAX_SLOT=6
PYTHON_COMPAT=( python2_7 python3_{5,6} pypy )

inherit llvm multiprocessing multilib-build python-any-r1 versionator toolchain-funcs

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
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

RUST_STAGE0_VERSION="1.$(($(get_version_component_range 2) - 1)).2"

# there is no cargo 0.28 tag, so use 0.27
CARGO_DEPEND_VERSION="0.$(($(get_version_component_range 2))).0"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="https://www.rust-lang.org/"

SRC_URI="https://static.rust-lang.org/dist/${SRC} -> rustc-${PV}-src.tar.xz
	amd64? (
		elibc_glibc? ( https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-x86_64-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-x86_64-unknown-linux-musl.tar.xz )
	)
	arm? (
		elibc_glibc? (
			https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-arm-unknown-linux-gnueabi.tar.xz
			https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-armv7-unknown-linux-gnueabihf.tar.xz
		)
		elibc_musl? (
			https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-arm-unknown-linux-musleabi.tar.xz
			https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-armv7-unknown-linux-musleabihf.tar.xz
		)
	)
	arm64? (
		elibc_glibc? ( https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-aarch64-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-aarch64-unknown-linux-musl.tar.xz )
	)
	x86? (
		elibc_glibc? ( https://static.rust-lang.org/dist/rust-${RUST_STAGE0_VERSION}-i686-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/rust-${RUST_STAGE0_VERSION}-i686-unknown-linux-musl.tar.xz )
	)
"

ALL_LLVM_TARGETS=( AArch64 AMDGPU ARM BPF Hexagon Lanai Mips MSP430
	NVPTX PowerPC Sparc SystemZ X86 XCore )
ALL_LLVM_TARGETS=( "${ALL_LLVM_TARGETS[@]/#/llvm_targets_}" )
LLVM_TARGET_USEDEPS=${ALL_LLVM_TARGETS[@]/%/?}

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"

IUSE="debug doc extended jemalloc libressl system-llvm wasm ${ALL_LLVM_TARGETS[*]}"

RDEPEND=">=app-eselect/eselect-rust-0.3_pre20150425
		jemalloc? ( dev-libs/jemalloc )
		system-llvm? ( sys-devel/llvm )
		extended? (
			libressl? ( dev-libs/libressl:0= )
			!libressl? ( dev-libs/openssl:0= )
			net-libs/http-parser:0/2.8.0
			net-libs/libssh2:=
			net-misc/curl:=[ssl]
			sys-libs/zlib:=
			!dev-util/rustfmt
			!dev-util/cargo
		)
"
DEPEND="${RDEPEND}
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
PDEPEND="!extended? ( >=dev-util/cargo-${CARGO_DEPEND_VERSION} )"

REQUIRED_USE="!system-llvm? ( || ( ${ALL_LLVM_TARGETS[*]} ) )"

PATCHES=(
	"${FILESDIR}/1.25.0/0001-Require-static-native-libraries-when-linking-static-.patch"
	"${FILESDIR}/1.27.0/0002-Remove-nostdlib-and-musl_root-from-musl-targets.patch"
	"${FILESDIR}/1.27.0/0003-Switch-musl-targets-to-link-dynamically-by-default.patch"
	"${FILESDIR}/1.25.0/0004-Prefer-libgcc_eh-over-libunwind-for-musl.patch"
	"${FILESDIR}/1.25.0/0005-Fix-LLVM-build.patch"
	"${FILESDIR}/1.25.0/0006-Fix-rustdoc-for-cross-targets.patch"
	"${FILESDIR}/1.25.0/0007-Add-openssl-configuration-for-musl-targets.patch"
	"${FILESDIR}/1.26.2/0008-Don-t-pass-CFLAGS-to-the-C-compiler.patch"
	"${FILESDIR}/1.25.0/0009-liblibc.patch"
	"${FILESDIR}/1.25.0/0010-llvm.patch"
	"${FILESDIR}/rust-1.27.0-libressl-2.7.0.patch"
)

S="${WORKDIR}/${MY_P}-src"

toml_usex() {
	usex "$1" true false
}

rust_host() {
	case "${1}" in
		arm)
			if [[ ${1} == ${DEFAULT_ABI} ]]; then
				if [[ ${CHOST} == armv7* ]]; then
					RUSTARCH=armv7
				else
					RUSTARCH=arm
				fi
			else
				RUSTARCH=arm
			fi ;;
		amd64)
			RUSTARCH=x86_64 ;;
		arm64)
			RUSTARCH=aarch64 ;;
		x86)
			RUSTARCH=i686 ;;
	esac
	case "${1}" in
		arm)
			if [[ ${1} == ${DEFAULT_ABI} ]]; then
				if [[ ${CHOST} == armv7a-hardfloat* ]]; then
					RUSTLIBC=${ELIBC/glibc/gnu}eabihf
				else
					RUSTLIBC=${CHOST##*-}
				fi
			else
				RUSTLIBC=${ELIBC/glibc/gnu}
			fi ;;
		*)
			RUSTLIBC=${ELIBC/glibc/gnu} ;;
	esac
	RUSTHOST=${RUSTARCH}-unknown-${KERNEL}-${RUSTLIBC}
	echo "${RUSTHOST}"
}

pkg_setup() {
	export RUST_BACKTRACE=1
	if use system-llvm; then
		llvm_pkg_setup
		local llvm_config="$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"

		export LLVM_LINK_SHARED=1
		export RUSTFLAGS="$RUSTFLAGS -L native=$("$llvm_config" --libdir)"
	fi

	python-any-r1_pkg_setup
}

src_prepare() {
	"${WORKDIR}/rust-${RUST_STAGE0_VERSION}-$(rust_host ${ARCH})/install.sh" \
		--destdir="${WORKDIR}/stage0" \
		--prefix=/ \
		--components=rust-std-$(rust_host ${ARCH}),rustc,cargo \
		--disable-ldconfig \
		|| die

	default
}

src_configure() {
	local rust_target="" rust_targets="" rust_target_name arch_cflags

	# Collect rust target names to compile standard libs for all ABIs.
	for v in $(multilib_get_enabled_abi_pairs); do
		rust_targets="${rust_targets},\"$(rust_host ${v##*.})\""
	done
	if use wasm; then
		rust_targets="${rust_targets},\"wasm32-unknown-unknown\""
	fi
	rust_targets="${rust_targets#,}"

	rust_target=$(rust_host $ARCH)

	cat <<- EOF > "${S}"/config.toml
		[llvm]
		ninja = true
		optimize = $(toml_usex !debug)
		release-debuginfo = $(toml_usex debug)
		assertions = $(toml_usex debug)
		targets = "${LLVM_TARGETS// /;}"
		[build]
		build = "${rust_target}"
		host = ["${rust_target}"]
		target = [${rust_targets}]
		cargo = "${WORKDIR}/stage0/bin/cargo"
		rustc = "${WORKDIR}/stage0/bin/rustc"
		docs = $(toml_usex doc)
		compiler-docs = $(toml_usex doc)
		submodules = false
		python = "${EPYTHON}"
		locked-deps = true
		vendor = true
		verbose = 2
		extended = $(toml_usex extended)
		[install]
		prefix = "${EPREFIX}/usr"
		libdir = "$(get_libdir)"
		docdir = "share/doc/${P}"
		mandir = "share/${P}/man"
		[rust]
		optimize = $(toml_usex !debug)
		debuginfo = $(toml_usex debug)
		debug-assertions = $(toml_usex debug)
		use-jemalloc = $(toml_usex jemalloc)
		default-linker = "$(tc-getCC)"
		channel = "${SLOT%%/*}"
		rpath = false
		lld = $(toml_usex wasm)
		optimize-tests = $(toml_usex !debug)
		dist-src = false
		[dist]
		src-tarball = false
	EOF

	for v in $(multilib_get_enabled_abi_pairs); do
		rust_target=$(rust_host ${v##*.})
		arch_cflags="$(get_abi_CFLAGS ${v##*.})"

		cat <<- EOF >> "${S}"/config.env
			CFLAGS_${rust_target}=${arch_cflags}
		EOF

		cat <<- EOF >> "${S}"/config.toml
			[target.${rust_target}]
			cc = "$(tc-getBUILD_CC)"
			cxx = "$(tc-getBUILD_CXX)"
			linker = "$(tc-getCC)"
			ar = "$(tc-getAR)"
		EOF

		use system-llvm && cat <<- EOF >> "${S}"/config.toml
			llvm-config = "$(get_llvm_prefix "$LLVM_MAX_SLOT")/bin/llvm-config"
		EOF
	done

	if use wasm; then
		cat <<- EOF >> "${S}"/config.toml
			[target.wasm32-unknown-unknown]
			linker = "lld"
		EOF
	fi
}

src_compile() {
	env $(cat "${S}"/config.env)\
		./x.py build --verbose --config="${S}"/config.toml -j$(makeopts_jobs) || die
}

src_install() {
	local rust_target abi_libdir

	env DESTDIR="${D}" ./x.py install || die

	mv "${D}/usr/bin/rustc" "${D}/usr/bin/rustc-${PV}" || die
	mv "${D}/usr/bin/rustdoc" "${D}/usr/bin/rustdoc-${PV}" || die
	mv "${D}/usr/bin/rust-gdb" "${D}/usr/bin/rust-gdb-${PV}" || die
	mv "${D}/usr/bin/rust-lldb" "${D}/usr/bin/rust-lldb-${PV}" || die

	# Copy shared library versions of standard libraries for all targets
	# into the system's abi-dependent lib directories because the rust
	# installer only does so for the native ABI.
	for v in $(multilib_get_enabled_abi_pairs); do
		if [ ${v##*.} = ${DEFAULT_ABI} ]; then
			continue
		fi
		abi_libdir=$(get_abi_LIBDIR ${v##*.})
		rust_target=$(rust_host ${v##*.})
		mkdir -p "${D}/usr/${abi_libdir}"
		cp "${D}/usr/$(get_libdir)/rustlib/${rust_target}/lib"/*.so \
		   "${D}/usr/${abi_libdir}" || die
	done

	rm "${D}/usr/$(get_libdir)/rustlib/components" || die
	rm "${D}/usr/$(get_libdir)/rustlib/install.log" || die
	rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-std-$(rust_host ${ARCH})" || die
	rm "${D}/usr/$(get_libdir)/rustlib/manifest-rustc" || die
	rm "${D}/usr/$(get_libdir)/rustlib/rust-installer-version" || die
	rm "${D}/usr/$(get_libdir)/rustlib/uninstall.sh" || die

	if use doc; then
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-docs" || die
	fi

	if use extended; then
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-cargo" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rls-preview" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-analysis-$(rust_host ${ARCH})" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rust-src" || die
		rm "${D}/usr/$(get_libdir)/rustlib/manifest-rustfmt-preview" || die

		rm "${D}/usr/share/doc/${P}/LICENSE-APACHE.old" || die
		rm "${D}/usr/share/doc/${P}/LICENSE-MIT.old" || die
	fi

	rm "${D}/usr/share/doc/${P}/LICENSE-APACHE" || die
	rm "${D}/usr/share/doc/${P}/LICENSE-MIT" || die

	docompress "/usr/share/${P}/man"

	cat <<-EOF > "${T}"/50${P}
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

	elog "Rust installs a helper script for calling GDB and LLDB,"
	elog "for your convenience it is installed under /usr/bin/rust-{gdb,lldb}-${PV}."

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
