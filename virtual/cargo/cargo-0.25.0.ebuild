# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

DESCRIPTION="Virtual for cargo, the rust package manager"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

DEPEND=""
RDEPEND="|| ( =dev-util/cargo-${PV}* =dev-lang/rust-1.24*[extended] =dev-lang/rust-bin-1.24*[extended] )"
