pkg:extract
export CFLAGS="-I${PKG_DEST}/${PKG_TAPF}/include"
export LDFLAGS="-L${PKG_DEST}/${PKG_TAPF}/lib"


url='https://dl.bintray.com/xquartz/downloads/XQuartz-2.7.11.dmg'
# wget ${url}
cp ~/*.dmg .
mkdir host
hdiutil attach ${url##*/}
x=${url##*/}; x=${x%%.dmg}
pkgutil --expand /Volumes/${x}/XQuartz.pkg tmp
gzip -dc < tmp/x11.pkg/Payload > cpio.tmp; cpio -i < cpio.tmp; mv opt host

export DYLD_FALLBACK_LIBRARY_PATH=${PWD}/host/opt/X11/lib
export PATH=${PWD}/host:${PATH}
for exe in mkfontdir mkfontscale bdftopcf bdftruncate ucs2any; do
    echo -e "#!/bin/bash\nDYLD_FALLBACK_LIBRARY_PATH=${PWD}/host/opt/X11/lib ${PWD}/host/opt/X11/bin/${exe} \$@" > host/${exe}
    chmod +x host/${exe}
done

pkg: mkdir -p ${PKG_TAPF}/lib/pkgconfig
for dir in $(grep -v '^#' ${PKG_DATA}/legacy.md5 | awk '{print $2}'); do
    dir=${dir%.tar.bz2}
    pushd ${dir}
    cp -f ${PKG_BASE}/util/config.sub . || :
    pkg:configure --enable-malloc0returnsnull PKG_CONFIG="${PKG_DATA}/pkg-config.sh"
    make -j4 UTIL_DIR=${PKG_WORK}/host/opt/X11/share/fonts/util/
    pkg:install
    popd
done
