#!/bin/bash
# Copyright (C) 2018-present Team ua3nbw (https://ua3nbw.ru)

#################################################
# Set variables
#################################################

KODI=18.0b5-Leia
FFMPEG=4.0.3-Leia-Beta5
IPTVSIMPLE=3.5.3-Leia
#PVRHTS=4.4.2-Leia
WAYLAND=1.16.0
WAYLANDPROTOCOLS=1.16
WESTON=4.0.0
LIBDRM=libdrm-2.4.96
WLROOT=$PWD/build/
#################################################
### PKG Vars ###
#################################################
PKG_MANAGER="apt-get"
PKG_CACHE="/var/lib/apt/lists/"
UPDATE_PKG_CACHE="${PKG_MANAGER} update"
PKG_INSTALL="${PKG_MANAGER} --yes install"

TIME_START=$(date +%s)
TIME_STAMP_START=(`date +"%T"`)

DATE_LONG=$(date +"%a, %d %b %Y %H:%M:%S %z")
DATE_SHORT=$(date +%Y%m%d)

#COLORS
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan




clone_or_update() {
    repo=$1
    dest=$(basename $repo)

    cd ${WLROOT}
    if [ $? != 0 ]; then
	echo "Error: Could not cd to ${WLROOT}.  Does it exist?"
	exit 1
    fi
    echo
    echo checkout: $dest
    if [ ! -d ${dest} ]; then
	git clone ${repo} ${dest}
	if [ $? != 0 ]; then
	    echo "Error: Could not clone repository"
	    exit 1
	fi
    fi
    cd ${dest}
    git checkout master
    if [ $? != 0 ]; then
	echo "Error: Problem checking out master"
	exit 1
    fi
    git pull
    if [ $? != 0 ]; then
	echo "Error: Could not pull from upstream"
	exit 1
    fi
    
    if [[ $2 ]]; then
        branch=$2
        git checkout ${branch} -b ${branch}_local
	if [ $? != 0 ]; then
	    git checkout ${branch}_local
	fi
    fi
    cd ${WLROOT}
}

do_deps(){

    update_package_cache

BUILD_KODI_ARM_DEPS_START=( apt-transport-https debconf-utils ruby ruby-dev rubygems build-essential )
BUILD_KODI_ARM_DEPS=( automake autopoint gettext autotools-dev cmake curl default-jre libcurl4-openssl-dev gawk gcc  g++  cpp \
gdc gperf libasound2-dev libass-dev  libavahi-client-dev libavahi-common-dev libbluetooth-dev libbluray-dev libbz2-dev \
libcdio-dev libp8-platform-dev libcrossguid-dev   libcwiid-dev libdbus-1-dev libegl1-mesa-dev libenca-dev libflac-dev \
libfontconfig-dev libfmt-dev libfreetype6-dev libfribidi-dev libfstrcmp-dev libgcrypt-dev libgif-dev  libgl-dev libglew-dev \
libglu1-mesa-dev libgnutls28-dev libgpg-error-dev libiso9660-dev libjpeg-dev liblcms2-dev liblirc-dev libltdl-dev liblzo2-dev \
libmicrohttpd-dev libmysqlclient-dev libnfs-dev libogg-dev  libpcre3-dev libplist-dev  libpng-dev libpulse-dev  libsmbclient-dev \
libsqlite3-dev libssl-dev libtag1-dev  libtiff-dev  libtinyxml-dev libtool libudev-dev libva-dev libvdpau-dev libvorbis-dev \
libxkbcommon-dev libxmu-dev libxrandr-dev  libxslt-dev libxt-dev  netcat  wipe lsb-release  python-dev python-pil \
python-minimal rapidjson-dev swig scons unzip uuid-dev yasm zip zlib1g-dev libgbm-dev ccache libinput-dev \
libgles2-mesa-dev libwayland-dev libwayland-egl1-mesa libcec-dev doxygen git autoconf libtool build-essential \
libopencore-amrnb-dev libopencore-amrwb-dev librtmp-dev libtheora-dev libvo-amrwbenc-dev libvpx-dev libx264-dev \
libx265-dev libxvidcore-dev libfdk-aac-dev libavresample-dev libffi-dev libexpat1-dev libxml2-dev xutils-dev \
libpam0g-dev libjpeg-dev libcairo2-dev libxcb-composite0-dev libxcursor-dev libxkbcommon-dev libpixman-1-dev )

install_dependent_packages BUILD_KODI_ARM_DEPS_START[@]
DEBIAN_FRONTEND=noninteractive
install_dependent_packages BUILD_KODI_ARM_DEPS[@]

}

install_dependent_packages() {

  declare -a argArray1=("${!1}")

  if command -v debconf-apt-progress &> /dev/null; then
    $SUDO debconf-apt-progress -- ${PKG_INSTALL} "${argArray1[@]}"
  else
    for i in "${argArray1[@]}"; do
      echo -n ":::    Checking for $i..."
      $SUDO package_check_install "${i}" &> /dev/null
      echo " installed!"
    done
  fi
}



do_checkout(){

    wget_ffmpeg
    clone_or_update git://anongit.freedesktop.org/wayland/wayland ${WAYLAND}
    clone_or_update git://anongit.freedesktop.org/wayland/wayland-protocols ${WAYLANDPROTOCOLS}
    clone_or_update git://anongit.freedesktop.org/git/mesa/drm ${LIBDRM}
    clone_or_update git://anongit.freedesktop.org/wayland/weston ${WESTON} 
    clone_or_update https://github.com/NilsBrause/waylandpp
    wget_kodi
#    wget_hts
    wget_iptvsimple

}



wget_hts(){

    cd ${WLROOT}
    if [ ! -d "${WLROOT}pvr.hts" ]; then
        echo -e "$Green \n wget pvr.hts$Color_Off \n"
        wget https://github.com/kodi-pvr/pvr.hts/archive/${PVRHTS}.tar.gz
        echo -e "$Green \n untar hts$Color_Off \n"
        tar -xzf ${PVRHTS}.tar.gz -C ${WLROOT}
        mv -f pvr.hts-${PVRHTS} pvr.hts       

        cd ${WLROOT}pvr.hts
	if [ $? != 0 ]; then
	    echo -e "$Red \n Wget Error pvr.hts  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_gen
    fi


}

build_hts(){

    cd ${WLROOT}pvr.hts
    mkdir -p build
    cd build

    if [ ! -f ".done_make" ]; then
    cmake -DADDONS_TO_BUILD=pvr.hts -DADDON_SRC_PREFIX=../.. -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=../../xbmc/kodi-build/addons -DPACKAGE_ZIP=1 ../../xbmc/cmake/addons

    make -j4

	if [ $? != 0 ]; then
  	    echo -e "$Red \n Build Error pvr.hts.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_make
        echo build done...
    fi

}




wget_iptvsimple(){

    cd ${WLROOT}
    if [ ! -d "${WLROOT}pvr.iptvsimple" ]; then
        echo -e "$Green \n wget iptvsimple$Color_Off \n"
        wget https://github.com/kodi-pvr/pvr.iptvsimple/archive/${IPTVSIMPLE}.tar.gz
        echo -e "$Green \n untar iptvsimple$Color_Off \n"
        tar -xzf ${IPTVSIMPLE}.tar.gz -C ${WLROOT}
        mv -f pvr.iptvsimple-${IPTVSIMPLE} pvr.iptvsimple       

        cd ${WLROOT}pvr.iptvsimple
	if [ $? != 0 ]; then
	    echo -e "$Red \n Wget Error.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_gen
    fi


}

build_iptvsimple(){

    cd ${WLROOT}pvr.iptvsimple
    mkdir -p build
    cd build

    if [ ! -f ".done_make" ]; then
    cmake -DADDONS_TO_BUILD=pvr.iptvsimple -DADDON_SRC_PREFIX=../.. -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=../../xbmc/addons -DPACKAGE_ZIP=1 ../../xbmc/cmake/addons

#    make -C ../../pvr.iptvsimple/build
    make -j4
	if [ $? != 0 ]; then
  	    echo -e "$Red \n Build Error iptvsimple.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_make
        echo build done...
    fi

}

wget_kodi(){

    cd ${WLROOT}
    if [ ! -d "${WLROOT}xbmc" ]; then
        echo -e "$Green \n wget kodi$Color_Off \n"
        wget https://github.com/xbmc/xbmc/archive/${KODI}.tar.gz
        echo -e "$Green \n untar kodi$Color_Off \n"
        tar -xzf ${KODI}.tar.gz -C ${WLROOT}
        mv -f xbmc-${KODI} xbmc
#        rm ${KODI}.tar.gz

        cp -PRv ../kodi-patches/* ${WLROOT}xbmc
        cd ${WLROOT}xbmc
        echo -e "$Green \n patch kodi$Color_Off \n"
        patch -p1 <*.patch

	if [ $? != 0 ]; then
	    echo -e "$Red \n Wget Error.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_gen
    fi
}


build_kodi(){

    cd ${WLROOT}xbmc
    mkdir -p  kodi-build
    cd kodi-build
    if [ ! -f ".done_make" ]; then
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCORE_SYSTEM_NAME=linux  -DCPU=cortex-a7 \
    -DWITH_ARCH=arm -DENABLE_INTERNAL_FLATBUFFERS=ON  -DFFMPEG_PATH=/usr/local -DENABLE_INTERNAL_FFMPEG=OFF \
    -DENABLE_VAAPI=OFF -DENABLE_VDPAU=OFF -DENABLE_CEC=ON -DENABLE_X=OFF -DCORE_PLATFORM_NAME=wayland -DWAYLAND_RENDER_SYSTEM=gles

    cmake --build . -- -j4

	if [ $? != 0 ]; then
  	    echo -e "$Red \n Build Error.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_make
        echo build done...
    fi

    if [ ! -f ".done_install" ]; then

    gem install --no-ri --no-rdoc fpm
    make -j4 install DESTDIR=/tmp/${KODI}

#    mkdir -p /tmp/${KODI}/root
    mkdir -p /tmp/${KODI}/root/.config
    cp -av ../../../.asoundrc /tmp/${KODI}/root
#    cp -av ../../../after-install.sh /tmp/${KODI}/root
    cp -av ../../waylandpp/build/lib* /tmp/${KODI}/usr/local/lib
    cp -av  ../../../weston.ini /tmp/${KODI}/root/.config






    mkdir -p  /tmp/${KODI}/root/.kodi/addons
    cp -a  ../addons/pvr.iptvsimple  /tmp/${KODI}/root/.kodi/addons

    fpm -s dir -t deb -n kodi -v ${KODI} --after-install $HOME/kodi-build/after-install.sh -C /tmp/${KODI}
#    --depends weston,libavahi-client3,libbluray2,libcec4,liblirc-client0,libmicrohttpd12,libnfs11,libpulse0,libpython2.7,libsmbclient,libxslt1.1,libass9,libcdio17,libva2,libvpx5,libopencore-amrwb0,libopencore-amrnb0,libtheora0,libvo-amrwbenc0,libx264-152,libx265-146,libxvidcore4,libva-drm2,libvdpau1,libfstrcmp0,libpcrecpp0v5,libtag1v5-vanilla,libtinyxml2.6.2v5,libva-x11-2 \
    

    dpkg -i kodi_${KODI}_armhf.deb
    mv -f kodi_${KODI}_armhf.deb ../../kodi_${KODI}_armhf.deb

#apt-mark hold linux-dtb-next-sunxi
#apt-mark hold linux-headers-next-sunxi
#apt-mark hold linux-image-next-sunxi
#apt-mark hold kodi

	if [ $? != 0 ]; then
  	    echo -e "$Red \n Install Error.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_install
        echo install done...
    fi
}



    wget_ffmpeg(){
    cd ${WLROOT}
    if [ ! -d "${WLROOT}ffmpeg" ]; then
        echo -e "$Green \n wget ffmpeg$Color_Off \n"
        wget https://github.com/xbmc/FFmpeg/archive/${FFMPEG}.tar.gz
        echo -e "$Green \n untar ffmpeg$Color_Off \n"
        tar -xzf ${FFMPEG}.tar.gz -C ${WLROOT}
        mv -f FFmpeg-${FFMPEG} ffmpeg
#        rm ${FFMPEG}.tar.gz
        cd ${WLROOT}ffmpeg 

cat > ${WLROOT}ffmpeg/autogen.sh << _EOF_
./configure --prefix=/usr/local --enable-nonfree --enable-gpl --enable-v4l2_m2m --disable-debug --enable-bzlib --enable-libx264 \
--enable-libvpx --enable-vaapi --enable-libtheora --enable-openssl --enable-lzma --enable-libvorbis --enable-avresample \
--enable-postproc --enable-swscale --enable-swresample --enable-avformat --enable-avcodec --enable-avfilter --enable-avdevice \
--enable-librtmp --enable-libfreetype --enable-libbluray --enable-protocol=bluray --enable-muxers --enable-encoders --enable-decoders \
--enable-demuxers --enable-parsers --enable-bsfs --enable-protocols --enable-indevs --enable-outdevs --enable-filters --enable-neon \
--enable-vfp --pkg-config=pkg-config --enable-zlib --enable-ffprobe --enable-libxvid --enable-libx265 --enable-libfdk-aac \
--enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-version3 --enable-libdrm 
_EOF_
        chmod 755  autogen.sh

	if [ $? != 0 ]; then
	      	    echo -e "$Red \n Configure Error.  Terminating$Color_Off \n"
	    exit 1
	fi
#	touch .done_gen
    fi
}


gen(){                                                                                                                                                                    
    pkg=$1
    shift
    echo
    echo autogen $pkg
    cd $WLROOT/$pkg
    if [ ! -f ".done_gen" ]; then
	echo "./autogen.sh $*"
        echo -e "$Green \n autogen$Color_Off \n"
	./autogen.sh $*
	if [ $? != 0 ]; then
	      	    echo -e "$Red \n Configure Error.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_gen
    fi
}

compile(){                                                                                                                                                                
    if [ ! -f ".done_make" ]; then
	make -j4
	if [ $? != 0 ]; then
  	    echo -e "$Red \n Build Error.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_make
        echo -e "$Green \n build done...$Color_Off \n"
    fi

    if [ ! -f ".done_install" ]; then
        sudo make install
        if [ $? != 0 ]; then
            echo "Install Error.  Terminating"
            exit 1
        fi
        touch .done_install
        echo -e "$Green \n install done... $Color_Off \n"
    fi
}


build_waylandpp(){
    cd ${WLROOT}/waylandpp
    if [ ! -f ".done_gen" ]; then
        echo
        echo "autogen waylandpp"
        mkdir -p build
        cd build
	if [ $? != 0 ]; then
	      	    echo -e "$Red \n Configure Error.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_gen
    fi

    if [ ! -f ".done_make" ]; then
        cmake ..
        make -j4
	if [ $? != 0 ]; then
  	    echo -e "$Red \n Build Error.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_make
        echo -e "$Green \n build done...$Color_Off \n".
    fi

    if [ ! -f ".done_install" ]; then
	sudo make install
	if [ $? != 0 ]; then
  	    echo -e "$Red \n Install Error.  Terminating$Color_Off \n"
	    exit 1
	fi
	touch .done_install
        echo -e "$Green \n install done... $Color_Off \n"
    fi
}

do_build(){

#echo -e "- For the user management, Line Out and DAC  to $Cyan 100% unmute $Color_Off"
#amixer -c 0 -q set "Line Out"  100%+ unmute
#amixer -c 0 -q set "DAC"  100%+ unmute

#amixer -c 1 -q set "Line Out"  100%+ unmute
#amixer -c 1 -q set "DAC"  100%+ unmute

    gen ffmpeg 
    compile

    gen wayland --disable-documentation
    compile

    gen wayland-protocols
    compile

    build_waylandpp

    gen drm
    compile

    gen weston \
        --with-cairo=image \
        --enable-clients --enable-headless-compositor \
        --enable-demo-clients-install --enable-drm-compositor \
        --disable-xwayland --enable-setuid-install=no \
        --disable-x11-compositor
    compile

#    build_hts

    build_iptvsimple

    build_kodi

    do_mali

}

do_mali(){
cd ${WLROOT}
cd ../mali-blobs-418f55585e76f375792dbebb3e97532f0c1c556d
        echo
        echo -e "$Green \n install mali... $Color_Off \n"
  mkdir -p /usr/include/
    cp -av include/wayland/* /usr/include

  mkdir -p /usr/lib/pkgconfig
    cp -PRv pkgconfig/*.pc /usr/lib/pkgconfig

  MALI="r6p2/arm/wayland/libMali.so"

  mkdir -p /usr/lib/mali
    cp -v $MALI /usr/lib/mali
        echo -e "$Green \n install libMali.so... $Color_Off \n"
    for lib in libEGL.so \
               libEGL.so.1 \
               libEGL.so.1.4 \
               libGLESv2.so \
               libGLESv2.so.2 \
               libGLESv2.so.2.0 \
               libgbm.so \
               libgbm.so.1; do
      ln -sfv libMali.so /usr/lib/mali/${lib}
        
    done

echo "/usr/lib/mali" > /etc/ld.so.conf.d/1-mali.conf
ldconfig
sleep 5
cd ..
cd DX910-SW-99002-r9p0-01rel0/driver/src/devicedrv/mali
export CROSS_COMPILE=arm-linux-gnueabihf-
export KDIR=/lib/modules/$(uname -r)/build
        echo
        echo -e "$Green \n make mali modules... $Color_Off \n"
make MALI_PLATFORM_FILES=platform/sunxi/sunxi.c \
    EXTRA_CFLAGS="-DCONFIG_MALI_DVFS \
    -DMALI_FAKE_PLATFORM_DEVICE=1 \
    -DCONFIG_MALI_DMA_BUF_MAP_ON_ATTACH" \
    CONFIG_MALI400=m USING_DVFS=1 

mkdir -p /lib/modules/$(uname -r)/extra
cp -PR mali.ko /lib/modules/$(uname -r)/extra/mali.ko

depmod
modprobe mali
sleep 5
chmod 666 /dev/mali
sleep 5
chgrp video /dev/mali
        echo
        echo -e "$Cyan \n load modules... $Color_Off \n"

ls -l  /dev/mali

}

update_package_cache() {
  timestamp=$(stat -c %Y ${PKG_CACHE})
  timestampAsDate=$(date -d @"${timestamp}" "+%b %e")
  today=$(date "+%b %e")

  if [ ! "${today}" == "${timestampAsDate}" ]; then
    #update package lists
    echo ":::"
    if command -v debconf-apt-progress &> /dev/null; then
        $SUDO debconf-apt-progress -- ${UPDATE_PKG_CACHE}
    else
        $SUDO ${UPDATE_PKG_CACHE} &> /dev/null
    fi
  fi
}



pkg_uninstl(){
    pkg=$1
    shift
    echo
    echo uninstall $pkg
    cd $WLROOT/$pkg
    sudo make uninstall
    rm .done_install
}

do_uninstall(){
    pkg_uninstl wayland
    pkg_uninstl wayland-protocols
    pkg_uninstl weston

    cd $WLROOT/glmark2.git
    sudo ./waf uninstall
    rm .done_install
}

pkg_distc(){
    pkg=$1
    shift
    echo
    echo clean $pkg
    cd $WLROOT/$pkg
    git clean -dxf
}

do_distclean(){
    pkg_distc wayland
    pkg_distc wayland-protocols
    pkg_distc libinput
    pkg_distc drm
    pkg_distc mesa
    pkg_distc libxkbcommon
    pkg_distc pixman
    pkg_distc cairo
    pkg_distc weston
    pkg_distc glmark2.git
}

if [ "$1" = "" ]; then                                                                                                                                                       
    echo "$0 commands are:  "
    echo "    all           "
    echo "    deps          "
    echo "    checkout      "
    echo "    build         "
    echo "    uninstall     "
    echo "    distclean     "
else
    if [ ! -d ${WLROOT} ]; then
        mkdir -p ${WLROOT}
        if [ $? != 0 ]; then
            echo "Error: Could not create dir ${WLROOT}"
            exit 1
        fi
    fi

    while [ "$1" != "" ]
    do
        case "$1" in
            all)
                do_deps
                do_checkout
                do_build
                ;;
            deps)
                do_deps
                ;;
            checkout)
                do_checkout
                ;;
            build)
                do_build
                ;;
            uninstall)
                do_uninstall
                ;;
            distclean)
                do_uninstall
                do_distclean
                ;;
            *)
                echo -e "$0 \033[47;31mUnknown CMD: $1\033[0m"
                exit 1
                ;;
        esac
        shift 1
    done
    cd $WLROOT
fi


    #################################################
    # Cleanup
    #################################################

    # clean up dirs

    # note time ended
    time_end=$(date +%s)
    time_stamp_end=(`date +"%T"`)
    runtime=$(echo "scale=2; ($time_end-$TIME_START) / 60 " | bc)

    # output finish
    echo -e "\nTime started: ${TIME_STAMP_START}"
    echo -e "Time started: ${time_stamp_end}"
    echo -e "Total Runtime (minutes): $Red $runtime\n $Color_Off "

exit 0
