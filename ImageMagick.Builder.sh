#!/bin/bash

OUTPUT_DIR=/usr
TMP_DIR=/tmp/imagemagick_build_dir

if [[ -d != $TMP_DIR ]]; then
    mkdir -p $TMP_DIR
else
    printf "\n>The specified TMP_DIR of $TMP_DIR already exists, should I clean it up before attempting to build? Y/N: "
    read -r clean_out_tmp_dir
    case $clean_out_tmp_dir in
        n|N)
            printf "\n>Okay, I'll go ahead storing tmp stuff in the TMP_DIR, but I'll overwrite items that have conflicting names with the new incoming things\n"
        ;;
        y|Y)
            printf "\n>Cleaning up the TMP_DIR ...\n"
            rm -rf $TMP_DIR/*
        ;;
    esac
fi

###PLEASE NOTE: The order of these functions matter.  In bash, a function definition MUST preceed its invokation.

function unarchive {
    cd $TMP_DIR
    case $PKG_SRC_ARCHIVE_EXT in
	    'tar.bz')
		    UNARCHIVE_CMD='tar -xvf'
		;;
		'tar.bz2')
		    UNARCHIVE_CMD='tar -xvjf'
		;;
		'tar.gz')
		    UNARCHIVE_CMD='tar -xvf'
		;;
		'tar.xz')
		    UNARCHIVE_CMD='tar -xvf'
		;;
		'zip')
		    UNARCHIVE_CMD='7z x'
		;;
	esac
    $UNARCHIVE_CMD $PKG_NAME-$PKG_VERSION.$PKG_SRC_ARCHIVE_EXT
}

function download {
    printf "\n>Downloading $PKG_NAME ...\n"
    cd $TMP_DIR
    wget --quiet -O $PKG_NAME-$PKG_VERSION.$PKG_SRC_ARCHIVE_EXT - $PKG_SRC_REMOTE_LOCATION
}

function get_src {
  download
  unarchive
}

function ensure_exec_bit {
    if [[ -f autogen.sh ]]; then
        chmod +x autogen.sh
    fi
    if [[ -f bootstrap.sh ]]; then
        chmod +x bootstrap.sh
    fi
    if [[ -f configure ]]; then
        chmod +x configure
    fi
}

# function check_baser_dependencies {
# cmake, wget, curl, gcc, build-depends, p7zip-full, p7zip-rar, pkg-config, autoreconf, intltool, autopoint, bison, libfreetype6-dev etc.
#}


# ALL_MODULES=(bzlib, pstoedit, autotrace, djvu, dps, fftw, flif, flashpix, fontconfig, freetype, ghostscript, graphiz, HEIC, jbig, jpegv1, jpegxl, lcms, lqr, ltdl, lzma, openexr, openjp2, pango, perl, png, raqm, raw, rsvg, tiff, webp, wmf, x11, xml, zip, zlib, zstd jemalloc, tcmalloc, umem)
# Use GETOPTS to allow for args like:
# --heic , --webp, --optipng, --jpeg2000, etc.
# and one final arg for '--all-plugins' which selects all of the plugins to be built
#

# NOTE: to use a discreet library of cached modules -- use the configuration syntax on imagemagic:
# ./configure CFLAGS="-I$OUTPUT_DIR/include" LDFLAGS="-L$OUTPUT_DIR/lib"

###PLEASE NOTE: The order of these functions matter.  In bash, a function definition MUST preceed its invokation.


###TODO: attempt to build and install baser libs and headers first.
# lcms
# bzip
# libpng
# brotli

### ImageMagick v6 -- necesary to be in-place while building dependency modules before compiling IM7
function install_imagemagick_6 {
    PKG_NAME="ImageMagick6"
    PKG_VERSION="main"
    PKG_SRC_REMOTE_LOCATION="https://github.com/ImageMagick/ImageMagick6/archive/refs/heads/main.zip"
    PKG_SRC_ARCHIVE_EXT="zip"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./configure
    make -j 4
    make install
    ldconfig
}

function uninstall_imagemagick_6 {
    PKG_NAME="ImageMagick6"
    PKG_VERSION="main"
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    make uninstall
    ldconfig
}

### libpng
function install_module_libpng {
    PKG_NAME="libpng"
    PKG_VERSION="1.6.37"
    PKG_SRC_REMOTE_LOCATION="https://sourceforge.net/projects/$PKG_NAME/files/libpng16/$PKG_VERSION/$PKG_NAME-$PKG_VERSION.tar.xz"
    PKG_SRC_ARCHIVE_EXT="tar.xz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./configure
    make -j 4
    make install
    ldconfig
}

### gperf
function install_module_gperf {
    PKG_NAME="gperf"
    PKG_VERSION="3.1"
    PKG_SRC_REMOTE_LOCATION="http://ftp.gnu.org/pub/gnu/$PKG_NAME/$PKG_NAME-$PKG_VERSION.tar.gz"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./configure --prefix=$OUTPUT_DIR
    make -j 4
    make install
    ldconfig
}

### Freetype2
function install_module_freetype2 {
    PKG_NAME="freetype"
    PKG_VERSION="2.8.1"
    PKG_SRC_REMOTE_LOCATION="https://sourceforge.net/projects/freetype/files/freetype2/$PKG_VERSION/$PKG_NAME-$PKG_VERSION.tar.xz"
    PKG_SRC_ARCHIVE_EXT="tar.xz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./autogen.sh
    ./configure --prefix=$OUTPUT_DIR
    make -j 4
    make install
    ldconfig
}

### Fontconfig
function install_module_fontconfig {
    #Fontconfig requires gperf
    install_module_gperf
    #Fontconfig requires freetype2
    install_module_freetype2
    PKG_NAME="fontconfig"
    PKG_VERSION="2.13.91"
    PKG_SRC_REMOTE_LOCATION="https://github.com/freedesktop/$PKG_NAME/archive/refs/tags/$PKG_VERSION.tar.gz"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./autogen.sh
    make -j 4
    make install
    ldconfig
}

### Ming
function install_module_ming {
    #Ming requires fontconfig
    install_module_fontconfig
    PKG_NAME="ming"
    PKG_VERSION="0_4_7"
    PKG_SRC_REMOTE_LOCATION="https://github.com/libming/libming/archive/refs/tags/$PKG_NAME-$PKG_VERSION.tar.gz"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd lib$PKG_NAME-$PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./autogen.sh
    ./configure --prefix=$OUTPUT_DIR
    make -j 4
    make install
    ldconfig
}

### pstoedit
function install_module_pstoedit {
    PKG_NAME="pstoedit"
    PKG_VERSION="3.78"
    PKG_SRC_REMOTE_LOCATION="'https://sourceforge.net/projects/$PKG_NAME/files/$PKG_NAME/$PKG_VERSION/$PKG_NAME-$PKG_VERSION.tar.gz'"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./autogen.sh
    ./configure --prefix=$OUTPUT_DIR
    make -j 6
    make install
    ldconfig
}


### Autotrace
function install_module_autotrace {
    #Autotrace Requires - pstoedit
    install_module_pstoedit
    #Autotrace Requires - libpng
    install_module_libpng
    #Autotrace Requires - ming
    install_module_ming
    #Autotrace Requires - Imagemagick -- in order to output libs and headers readable for ...imagemagick
    install_imagemagick_6
    # Now that dependencies are solved, we can install autotrace
    PKG_NAME="autotrace"
    PKG_VERSION="travis-20200219.65"
    PKG_SRC_REMOTE_LOCATION="https://github.com/$PKG_NAME/$PKG_NAME/archive/refs/tags/$PKG_VERSION.tar.gz"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./autogen.sh
    ./configure
    make -j 4
    make install
    ldconfig
}

### BZIP2 - for bzlib module
function install_module_bzip2 {
    PKG_NAME="bzip2"
    PKG_VERSION="latest"
    PKG_SRC_REMOTE_LOCATION="https://www.sourceware.org/pub/$PKG_NAME/$PKG_NAME-$PKG_VERSION.tar.gz"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    make -j 4
    make install PREFIX=$OUTPUT_DIR
    ldconfig
}


### lcms
function install_module_lcms {
    PKG_NAME="lcms"
    PKG_VERSION="2.13.1"
    PKG_SRC_REMOTE_LOCATION="https://github.com/mm2/Little-CMS/archive/refs/tags/$PKG_NAME$PKG_VERSION.tar.gz"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd Little-CMS-$PKG_NAME$PKG_VERSION
    ensure_exec_bit
    ./autogen.sh
    ./configure
    make -j 4
    make install
    ldconfig
}

### jemalloc
function install_module_jemalloc {
    PKG_NAME="jemalloc"
    PKG_VERSION="5.2.1"
    PKG_SRC_REMOTE_LOCATION="https://github.com/$PKG_NAME/$PKG_NAME/archive/refs/tags/$PKG_VERSION.tar.gz"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./autogen.sh
    ./configure
    make -j 4
    make install
    ldconfig
}

### djvulibre - djvu opensource format reader/writer
function install_module_djvulibre {
    PKG_NAME="djvulibre"
    PKG_VERSION="3.5.28"
    PKG_SRC_REMOTE_LOCATION="https://sourceforge.net/projects/djvu/files/DjVuLibre/3.5.28/djvulibre-3.5.28.tar.gz"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./autogen.sh
    ./configure --disable-desktopfiles
    make -j 4
    make install
    ldconfig
}

### fftw
function install_module_fftw {
    PKG_NAME="fftw"
    PKG_VERSION="3.3.10"
    PKG_SRC_REMOTE_LOCATION="https://github.com/FFTW/fftw3/archive/refs/tags/$PKG_NAME-$PKG_VERSION.tar.gz"
    PKG_SRC_ARCHIVE_EXT="tar.gz"
    get_src
    cd $PKG_NAME-$PKG_VERSION
    ensure_exec_bit
    ./bootstrap.sh
}