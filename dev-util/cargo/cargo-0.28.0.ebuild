# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CRATES="
aho-corasick-0.6.4
ansi_term-0.11.0
atty-0.2.9
backtrace-0.3.6
backtrace-sys-0.1.16
bitflags-1.0.1
bufstream-0.1.3
cc-1.0.10
cfg-if-0.1.2
clap-2.31.2
cmake-0.1.30
commoncrypto-0.2.0
commoncrypto-sys-0.2.0
core-foundation-0.5.1
core-foundation-sys-0.5.1
crates-io-0.16.0
crossbeam-0.3.2
crypto-hash-0.3.1
curl-0.4.12
curl-sys-0.4.2
dtoa-0.4.2
env_logger-0.5.9
failure-0.1.1
failure_derive-0.1.1
filetime-0.1.15
filetime-0.2.0
flate2-1.0.1
fnv-1.0.6
foreign-types-0.3.2
foreign-types-shared-0.1.1
fs2-0.4.3
fuchsia-zircon-0.3.3
fuchsia-zircon-sys-0.3.3
git2-0.7.1
git2-curl-0.8.1
glob-0.2.11
globset-0.4.0
hamcrest-0.1.1
hex-0.3.2
home-0.3.3
humantime-1.1.1
idna-0.1.4
ignore-0.4.2
itoa-0.4.1
jobserver-0.1.11
kernel32-sys-0.2.2
lazy_static-1.0.0
lazycell-0.6.0
libc-0.2.40
libgit2-sys-0.7.1
libssh2-sys-0.2.6
libz-sys-1.0.18
log-0.4.1
matches-0.1.6
memchr-2.0.1
miniz-sys-0.1.10
miow-0.3.1
num-traits-0.2.4
num_cpus-1.8.0
openssl-0.10.6
openssl-probe-0.1.2
openssl-sys-0.9.28
percent-encoding-1.0.1
pkg-config-0.3.11
proc-macro2-0.3.7
quick-error-1.2.1
quote-0.3.15
quote-0.5.2
rand-0.4.2
redox_syscall-0.1.37
redox_termios-0.1.1
regex-0.2.11
regex-1.0.0
regex-syntax-0.5.6
regex-syntax-0.6.0
remove_dir_all-0.5.1
rustc-demangle-0.1.8
same-file-1.0.2
schannel-0.1.12
scopeguard-0.3.3
semver-0.9.0
semver-parser-0.7.0
serde-1.0.55
serde_derive-1.0.55
serde_ignored-0.0.4
serde_json-1.0.17
shell-escape-0.1.4
socket2-0.3.5
strsim-0.7.0
syn-0.11.11
syn-0.13.10
synom-0.11.3
synstructure-0.6.1
tar-0.4.15
tempfile-3.0.2
termcolor-0.3.6
termion-1.5.1
textwrap-0.9.0
thread_local-0.3.5
toml-0.4.6
ucd-util-0.1.1
unicode-bidi-0.3.4
unicode-normalization-0.1.7
unicode-width-0.1.4
unicode-xid-0.0.4
unicode-xid-0.1.0
unreachable-1.0.0
url-1.7.0
utf8-ranges-1.0.0
vcpkg-0.2.3
vec_map-0.8.1
void-1.0.2
walkdir-2.1.4
winapi-0.2.8
winapi-0.3.4
winapi-build-0.1.1
winapi-i686-pc-windows-gnu-0.4.0
winapi-x86_64-pc-windows-gnu-0.4.0
wincolor-0.1.6"

inherit bash-completion-r1 cargo epatch versionator

case "${CHOST}" in
	armv7a*)
		CARGOARCH=armv7 ;;
	arm*)
		CARGOARCH=arm ;;
	*)
		CARGOARCH=${CHOST%%-*} ;;
esac
case "${CHOST}" in
	armv7a-hardfloat-*)
		CARGOLIBC=${ELIBC/glibc/gnu}eabihf ;;
	arm*)
		CARGOLIBC=${CHOST##*-} ;;
	*)
		CARGOLIBC=${ELIBC/glibc/gnu} ;;
esac
CARGOHOST=${CARGOARCH}-unknown-${KERNEL}-${CARGOLIBC}
CARGO_SNAPSHOT_VERSION="0.$(($(get_version_component_range 2) - 1)).0"

DESCRIPTION="The Rust's package manager"
HOMEPAGE="http://crates.io"
SRC_URI="https://github.com/rust-lang/cargo/archive/${PV}.tar.gz -> ${P}.tar.gz
	$(cargo_crate_uris ${CRATES})
	amd64? (
		elibc_glibc? ( https://static.rust-lang.org/dist/cargo-${CARGO_SNAPSHOT_VERSION}-x86_64-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/cargo-${CARGO_SNAPSHOT_VERSION}-x86_64-unknown-linux-musl.tar.xz )
	)
	arm? (
		elibc_glibc? (
			https://static.rust-lang.org/dist/cargo-${CARGO_SNAPSHOT_VERSION}-arm-unknown-linux-gnueabi.tar.xz
			https://static.rust-lang.org/dist/cargo-${CARGO_SNAPSHOT_VERSION}-armv7-unknown-linux-gnueabihf.tar.xz
		)
		elibc_musl? (
			https://portage.smaeul.xyz/distfiles/cargo-${CARGO_SNAPSHOT_VERSION}-arm-unknown-linux-musleabi.tar.xz
			https://portage.smaeul.xyz/distfiles/cargo-${CARGO_SNAPSHOT_VERSION}-armv7-unknown-linux-musleabihf.tar.xz
		)
	)
	arm64? (
		elibc_glibc? ( https://static.rust-lang.org/dist/cargo-${CARGO_SNAPSHOT_VERSION}-aarch64-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/cargo-${CARGO_SNAPSHOT_VERSION}-aarch64-unknown-linux-musl.tar.xz )
	)
	x86? (
		elibc_glibc? ( https://static.rust-lang.org/dist/cargo-${CARGO_SNAPSHOT_VERSION}-i686-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/cargo-${CARGO_SNAPSHOT_VERSION}-i686-unknown-linux-musl.tar.xz )
	)"

RESTRICT="mirror"
LICENSE="|| ( MIT Apache-2.0 )"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

IUSE="bash-completion doc libressl"

COMMON_DEPEND="
	libressl? ( dev-libs/libressl:0= )
	!libressl? ( dev-libs/openssl:0= )
	net-libs/http-parser:0/2.8.0
	net-libs/libssh2:=
	net-misc/curl:=[ssl]
	sys-libs/zlib:=
"
RDEPEND="
	${COMMON_DEPEND}
	!dev-util/cargo-bin
"
DEPEND="
	${COMMON_DEPEND}
	>=virtual/rust-1.9.0
	dev-util/cmake
	sys-apps/coreutils
	sys-apps/diffutils
	sys-apps/findutils
	sys-apps/sed"

PATCHES=()

src_prepare() {
	default

	(cd ${WORKDIR} && epatch "${FILESDIR}/cargo27-libressl27.patch" || die "Could not apply patch")
}

src_configure() {
	# Do nothing
	echo "Configuring cargo..."
}

src_compile() {
	export CARGO_HOME="${ECARGO_HOME}"
	local cargo="${WORKDIR}/cargo-${CARGO_SNAPSHOT_VERSION}-${CARGOHOST}/cargo/bin/cargo"
	${cargo} build --release || die

	# Building HTML documentation
	use doc && ${cargo} doc
}

src_install() {
	dobin target/release/cargo

	# Install HTML documentation
	use doc && HTML_DOCS=("target/doc")
	einstalldocs

	use bash-completion && newbashcomp src/etc/cargo.bashcomp.sh cargo
	insinto /usr/share/zsh/site-functions
	doins src/etc/_cargo
	doman src/etc/man/*
}
