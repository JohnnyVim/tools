#!/usr/bin/env bash

cd "$(dirname "$0")"
rm -rf temp
mkdir temp
cd temp

cp ../PKGBUILD .
makepkg -scfC
