# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CRATES="
advapi32-sys-0.2.0
aho-corasick-0.5.3
aho-corasick-0.6.4
atty-0.2.6
backtrace-0.3.5
backtrace-sys-0.1.16
bitflags-0.9.1
bitflags-1.0.1
bufstream-0.1.3
cc-1.0.4
cfg-if-0.1.2
cmake-0.1.29
commoncrypto-0.2.0
commoncrypto-sys-0.2.0
core-foundation-0.4.6
core-foundation-sys-0.4.6
crossbeam-0.2.12
crossbeam-0.3.2
crypto-hash-0.3.0
curl-0.4.11
curl-sys-0.4.1
docopt-0.8.3
dtoa-0.4.2
env_logger-0.4.3
error-chain-0.11.0
filetime-0.1.14
flate2-0.2.20
fnv-1.0.6
foreign-types-0.3.2
foreign-types-shared-0.1.1
fs2-0.4.3
fuchsia-zircon-0.3.3
fuchsia-zircon-sys-0.3.3
git2-0.6.11
git2-curl-0.7.0
glob-0.2.11
globset-0.2.1
hamcrest-0.1.1
hex-0.2.0
home-0.3.0
idna-0.1.4
ignore-0.2.2
itoa-0.3.4
jobserver-0.1.9
kernel32-sys-0.2.2
lazy_static-0.2.11
lazy_static-1.0.0
libc-0.2.35
libgit2-sys-0.6.19
libssh2-sys-0.2.6
libz-sys-1.0.18
log-0.3.9
log-0.4.1
matches-0.1.6
memchr-0.1.11
memchr-1.0.2
memchr-2.0.1
miniz-sys-0.1.10
miow-0.2.1
net2-0.2.31
num-0.1.41
num-bigint-0.1.41
num-complex-0.1.41
num-integer-0.1.35
num-iter-0.1.34
num-rational-0.1.40
num-traits-0.1.41
num_cpus-1.8.0
openssl-0.9.23
openssl-probe-0.1.2
openssl-sys-0.9.23
percent-encoding-1.0.1
pkg-config-0.3.9
psapi-sys-0.1.1
quote-0.3.15
rand-0.3.20
redox_syscall-0.1.37
redox_termios-0.1.1
regex-0.1.80
regex-0.2.5
regex-syntax-0.3.9
regex-syntax-0.4.2
rustc-demangle-0.1.5
rustc-serialize-0.3.24
same-file-0.1.3
schannel-0.1.10
scoped-tls-0.1.0
scopeguard-0.1.2
semver-0.8.0
semver-parser-0.7.0
serde-1.0.27
serde_derive-1.0.27
serde_derive_internals-0.19.0
serde_ignored-0.0.4
serde_json-1.0.9
shell-escape-0.1.3
socket2-0.3.0
strsim-0.6.0
syn-0.11.11
synom-0.11.3
tar-0.4.14
tempdir-0.3.5
termcolor-0.3.3
termion-1.5.1
thread-id-2.0.0
thread_local-0.2.7
thread_local-0.3.5
toml-0.4.5
unicode-bidi-0.3.4
unicode-normalization-0.1.5
unicode-xid-0.0.4
unreachable-1.0.0
url-1.6.0
userenv-sys-0.2.0
utf8-ranges-0.1.3
utf8-ranges-1.0.0
vcpkg-0.2.2
void-1.0.2
walkdir-1.0.7
winapi-0.2.8
winapi-0.3.3
winapi-build-0.1.1
winapi-i686-pc-windows-gnu-0.3.2
winapi-x86_64-pc-windows-gnu-0.3.2
wincolor-0.1.4
ws2_32-sys-0.2.1
"

inherit bash-completion-r1 cargo versionator

case "${CHOST}" in
	armv7*)
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
CARGO_SNAPSHOT_VERSION="0.$(($(get_version_component_range 2) - 0)).0"

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
	x86? (
		elibc_glibc? ( https://static.rust-lang.org/dist/cargo-${CARGO_SNAPSHOT_VERSION}-i686-unknown-linux-gnu.tar.xz )
		elibc_musl? ( https://portage.smaeul.xyz/distfiles/cargo-${CARGO_SNAPSHOT_VERSION}-i686-unknown-linux-musl.tar.xz )
	)"

RESTRICT="mirror"
LICENSE="|| ( MIT Apache-2.0 )"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"

IUSE="bash-completion doc libressl"

COMMON_DEPEND="
	libressl? (
		>=dev-libs/libressl-2.5.0:=
		<dev-libs/libressl-2.7.0:=
	)
	!libressl? ( dev-libs/openssl:0= )
	net-libs/http-parser:0/2.6.2
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
