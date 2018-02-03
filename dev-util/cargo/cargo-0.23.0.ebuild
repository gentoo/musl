# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CRATES="
advapi32-sys-0.2.0
aho-corasick-0.5.3
aho-corasick-0.6.3
atty-0.2.3
backtrace-0.3.3
backtrace-sys-0.1.14
bitflags-0.7.0
bitflags-0.9.1
bufstream-0.1.3
cc-1.0.0
cfg-if-0.1.2
cmake-0.1.26
commoncrypto-0.2.0
commoncrypto-sys-0.2.0
conv-0.3.3
core-foundation-0.4.4
core-foundation-sys-0.4.4
crossbeam-0.2.10
crossbeam-0.3.0
crypto-hash-0.3.0
curl-0.4.8
curl-sys-0.3.15
custom_derive-0.1.7
dbghelp-sys-0.2.0
docopt-0.8.1
dtoa-0.4.2
env_logger-0.4.3
error-chain-0.11.0
filetime-0.1.12
flate2-0.2.20
fnv-1.0.5
foreign-types-0.3.2
foreign-types-shared-0.1.1
fs2-0.4.2
git2-0.6.8
git2-curl-0.7.0
glob-0.2.11
globset-0.2.0
hamcrest-0.1.1
hex-0.2.0
home-0.3.0
idna-0.1.4
ignore-0.2.2
itoa-0.3.4
jobserver-0.1.6
kernel32-sys-0.2.2
lazy_static-0.2.9
libc-0.2.31
libgit2-sys-0.6.16
libssh2-sys-0.2.6
libz-sys-1.0.17
log-0.3.8
magenta-0.1.1
magenta-sys-0.1.1
matches-0.1.6
memchr-0.1.11
memchr-1.0.1
miniz-sys-0.1.10
miow-0.2.1
net2-0.2.31
num-0.1.40
num-bigint-0.1.40
num-complex-0.1.40
num-integer-0.1.35
num-iter-0.1.34
num-rational-0.1.39
num-traits-0.1.40
num_cpus-1.7.0
openssl-0.9.22
openssl-probe-0.1.1
openssl-sys-0.9.22
percent-encoding-1.0.0
pkg-config-0.3.9
psapi-sys-0.1.0
quote-0.3.15
rand-0.3.16
redox_syscall-0.1.31
redox_termios-0.1.1
regex-0.1.80
regex-0.2.2
regex-syntax-0.3.9
regex-syntax-0.4.1
rustc-demangle-0.1.5
rustc-serialize-0.3.24
same-file-0.1.3
scoped-tls-0.1.0
scopeguard-0.1.2
semver-0.8.0
semver-parser-0.7.0
serde-1.0.15
serde_derive-1.0.15
serde_derive_internals-0.16.0
serde_ignored-0.0.4
serde_json-1.0.3
shell-escape-0.1.3
socket2-0.2.3
strsim-0.6.0
syn-0.11.11
synom-0.11.3
tar-0.4.13
tempdir-0.3.5
termcolor-0.3.3
termion-1.5.1
thread-id-2.0.0
thread_local-0.2.7
thread_local-0.3.4
toml-0.4.5
unicode-bidi-0.3.4
unicode-normalization-0.1.5
unicode-xid-0.0.4
unreachable-1.0.0
url-1.5.1
userenv-sys-0.2.0
utf8-ranges-0.1.3
utf8-ranges-1.0.0
vcpkg-0.2.2
void-1.0.2
walkdir-1.0.7
winapi-0.2.8
winapi-build-0.1.1
wincolor-0.1.4
ws2_32-sys-0.2.1
"

inherit multiprocessing bash-completion-r1 cargo versionator

case "${CHOST}" in
	armv7a-hardfloat-*)
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
		CARGOLIBC=${ELIBC/glibc/gnu}eabi ;;
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
	net-libs/http-parser:=
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

PATCHES=(
	"${FILESDIR}/${P}-libressl-2.6.3.patch"
)

src_configure() {
	# Do nothing
	echo "Configuring cargo..."
}

src_compile() {
	export CARGO_HOME="${ECARGO_HOME}"
	local cargo="${WORKDIR}/cargo-${CARGO_SNAPSHOT_VERSION}-${CARGOHOST}/cargo/bin/cargo"
	${cargo} build --release -j$(makeopts_jobs) || die

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
