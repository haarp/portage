# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Linux multi-touch gesture recognizer"
HOMEPAGE="https://github.com/JoseExposito/touchegg"

if [[ "${PV}" == 9999 ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/JoseExposito/touchegg.git"
else
	SRC_URI="https://github.com/JoseExposito/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
fi

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+daemon +gtk systemd"

REQUIRED_USE="systemd? ( daemon )"

RDEPEND="
	dev-libs/glib:2
	dev-libs/libinput
	dev-libs/pugixml
	virtual/libudev
	x11-libs/cairo
	x11-libs/libX11
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXtst
	gtk? ( x11-libs/gtk+:3 )
	systemd? ( sys-apps/systemd )
"

DEPEND="${RDEPEND}"

DOCS=( "README.md" "CHANGELOG.md" "HACKING.md" )

src_prepare() {
	# Bump cmake version
	sed -e '/^cmake_minimum_required(/s/[0-9\.]\+/4.0/' \
		-i CMakeLists.txt || die
	# We define this variable ourselves
	sed -e '/pkg_get_variable(SYSTEMD_SERVICE_DIR /d' \
		-i CMakeLists.txt || die
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_INSTALL_SYSCONFDIR="${EPREFIX}/etc"
		-DAUTO_COLORS="$(usex gtk)"
		# https://github.com/JoseExposito/touchegg/issues/481
		-DUSE_SYSTEMD="$(usex systemd)"
	)

	cmake_src_configure
}

src_install() {
	default

	cmake_src_install

	if use daemon; then
		if use systemd; then
			systemd_dounit "${FILESDIR}/touchegg.service"
		else
			newinitd "${FILESDIR}/touchegg.initd" touchegg
		fi
	fi
}

pkg_postinst() {
	if use daemon; then
		elog "On update, don't forget to restart the system daemon and userspace client"
	else
		elog "Not using system daemon; in addition to 'touchegg', you have to manually"
		elog "run 'touchegg --daemon' as root or an user in the 'input' group"
		elog "On update, don't forget to restart both"
	fi
	elog "See https://github.com/JoseExposito/touchegg#configuration for config information"
}
