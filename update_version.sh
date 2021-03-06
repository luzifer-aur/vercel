#!/bin/bash
set -euxo pipefail

# Read pkg name
PKG=$(awk -F '=' '/pkgname=/{ print $2 }' PKGBUILD)

# Get latest version
VER=$(
	curl -s https://api.github.com/repos/vercel/vercel/releases/latest |
		jq -r '.tag_name' |
		sed 's/^vercel@//'
)
[[ -n $VER ]] || exit 1

# Insert latest version into PKGBUILD
sed -i \
	-e "s/^pkgver=.*/pkgver=${VER}/" \
	PKGBUILD

# Check whether this changed anything
if (git diff --exit-code PKGBUILD); then
	echo "Package ${PKG} has most recent version ${VER}"
	exit 0
fi

# Reset pkgrel
sed -i \
	-e 's/pkgrel=.*/pkgrel=1/' \
	PKGBUILD

# Update source hashes
updpkgsums

# Update .SRCINFO
makepkg --printsrcinfo >.SRCINFO

# Commit changes
git add PKGBUILD .SRCINFO
git commit -m "${PKG} v${VER}"
