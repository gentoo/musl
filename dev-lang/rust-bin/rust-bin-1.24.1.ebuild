# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils bash-completion-r1 toolchain-funcs

MY_P="rust-${PV}"

DESCRIPTION="Systems programming language from Mozilla"
HOMEPAGE="http://www.rust-lang.org/"
SRC_URI="amd64? ( https://portage.smaeul.xyz/distfiles/${MY_P}-x86_64-unknown-linux-musl.tar.xz )
	arm? (
		https://portage.smaeul.xyz/distfiles/${MY_P}-arm-unknown-linux-musleabi.tar.xz
		https://portage.smaeul.xyz/distfiles/${MY_P}-armv7-unknown-linux-musleabihf.tar.xz
		)
	arm64? ( https://portage.smaeul.xyz/distfiles/${MY_P}-aarch64-unknown-linux-musl.tar.xz )
	x86? ( https://portage.smaeul.xyz/distfiles/${MY_P}-i686-unknown-linux-musl.tar.xz )"

LICENSE="|| ( MIT Apache-2.0 ) BSD-1 BSD-2 BSD-4 UoI-NCSA"
SLOT="stable"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="doc extended"

DEPEND=">=app-eselect/eselect-rust-0.3_pre20150425
	!dev-lang/rust:0
	<=net-libs/http-parser-2.6.2
"
RDEPEND="${DEPEND}"

QA_PREBUILT="
	opt/${P}/bin/rustc-bin-${PV}
	opt/${P}/bin/rustdoc-bin-${PV}
	opt/${P}/lib/*.so
	opt/${P}/lib/rustlib/*/lib/*.so
	opt/${P}/lib/rustlib/*/lib/*.rlib*
"

pkg_pretend () {
	if [[ "$(tc-is-softfloat)" != "no" ]] && [[ ${CHOST} == armv7* ]]; then
		die "${CHOST} is not supported by upstream Rust. You must use a hard float version."
	elif [[ ${CHOST} == armv6*h* ]]; then
		die "${CHOST} is not supported on musl. You must use a soft float version."
	fi
}

src_unpack() {
	default

	local postfix
	use amd64 && postfix=x86_64-unknown-linux-musl

	if use arm && [[ "$(tc-is-softfloat)" != "no" ]] && [[ ${CHOST} == armv6* ]]; then
		postfix=arm-unknown-linux-musleabi
	elif use arm && [[ ${CHOST} == armv7*h* ]]; then
		postfix=armv7-unknown-linux-musleabihf
        fi

	use arm64 && postfix=aarch64-unknown-linux-musl

	use x86 && postfix=i686-unknown-linux-musl
	mv "${WORKDIR}/${MY_P}-${postfix}" "${S}" || die
}

src_install() {
	local std=$(grep 'std' ./components)
	local components="rustc,${std}"
	if use doc && ! use extended; then
		components="${components},rust-docs"
	elif use doc && use extended; then
		components="${components},rust-docs,cargo"
	elif use ! doc && use extended; then
		components="${components},cargo"
	elif use ! doc && ! use extended; then
		components="${components}"
	fi

	./install.sh \
		--components="${components}" \
		--disable-verify \
		--prefix="${D}/opt/${P}" \
		--mandir="${D}/usr/share/${P}/man" \
		--disable-ldconfig \
		|| die

	if use extended; then
		dosym "/opt/${P}/bin/cargo" /usr/bin/cargo
		dosym "/opt/${P}/share/zsh/site-functions/_cargo" /usr/share/zsh/site-functions/_cargo
		newbashcomp "${D}/opt/${P}/etc/bash_completion.d/cargo" cargo
	fi

	local rustc=rustc-bin-${PV}
	local rustdoc=rustdoc-bin-${PV}
	local rustgdb=rust-gdb-bin-${PV}

	mv "${D}/opt/${P}/bin/rustc" "${D}/opt/${P}/bin/${rustc}" || die
	mv "${D}/opt/${P}/bin/rustdoc" "${D}/opt/${P}/bin/${rustdoc}" || die
	mv "${D}/opt/${P}/bin/rust-gdb" "${D}/opt/${P}/bin/${rustgdb}" || die

	dosym "../../opt/${P}/bin/${rustc}" "/usr/bin/${rustc}"
	dosym "../../opt/${P}/bin/${rustdoc}" "/usr/bin/${rustdoc}"
	dosym "../../opt/${P}/bin/${rustgdb}" "/usr/bin/${rustgdb}"

	cat <<-EOF > "${T}"/50${P}
	LDPATH="/opt/${P}/lib"
	MANPATH="/usr/share/${P}/man"
	EOF
	doenvd "${T}"/50${P}

	cat <<-EOF > "${T}/provider-${P}"
	/usr/bin/rustdoc
	/usr/bin/rust-gdb
	EOF
	dodir /etc/env.d/rust
	insinto /etc/env.d/rust
	doins "${T}/provider-${P}"
}

pkg_postinst() {
	eselect rust update --if-unset

	elog "Rust installs a helper script for calling GDB now,"
	elog "for your convenience it is installed under /usr/bin/rust-gdb-bin-${PV},"

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
