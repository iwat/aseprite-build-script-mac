#!/bin/zsh
emulate -LR zsh

# 1.3.17
TAG_VERSION=1.3.17
PKG_VERSION=1.3.17

run() {
    >&2 echo "+ $@"
    "$@"
}

readonly RED='\e[0;31m'
readonly GREEN='\e[0;32m'
readonly YELLOW='\e[0;33m'
readonly NC='\e[0m' # No Color (reset)

readonly INFO_EMOJI='ℹ️'
readonly CHECK_EMOJI='✅'
readonly CROSS_EMOJI='❌'
readonly WARN_EMOJI='⚠️'

echo_info() {
    echo "${INFO_EMOJI} $1"
}

echo_check() {
    echo -e "${GREEN}${CHECK_EMOJI} $1${NC}"
}

echo_cross() {
    echo -e "${RED}${CROSS_EMOJI} $1${NC}"
}

echo_warn() {
    echo -e "${YELLOW}${WARN_EMOJI} $1${NC}"
}

# REMEMBER TO CONSULT README.MD FIRST!
# IF YOU RECIEVED THIS SCRIPT FROM ANYWHERE OTHER THAN https://github.com/Chasnah7/aseprite-build-script-mac OR https://codeberg.org/Chasnah/aseprite-build-script-mac
# DOUBLE CHECK TO MAKE SURE IT HAS NOT BEEN MALICIOUSLY EDITED.
# THE AUTHOR CLAIMS NO LIABILITY NOR WARRANTY FOR THIS SCRIPT
# USE AT YOUR OWN RISK.

# Paths

SCRIPT_DIR="$( cd "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

export DEPS=$SCRIPT_DIR/build

export ASEPRITE=$DEPS/aseprite-${PKG_VERSION} #DO NOT MODIFY!

export SKIA=$DEPS/skia #DO NOT MODIFY!

export ASEZIP=https://github.com/aseprite/aseprite/releases/download/v${TAG_VERSION}/Aseprite-v${PKG_VERSION}-Source.zip

if [[ $(uname -m) == "arm64" ]]; then
    echo_info "Running on Apple Silicon (ARM)"
    export SKIAZIP=https://github.com/aseprite/skia/releases/download/m124-08a5439a6b/Skia-macOS-Release-arm64.zip
    export ARCH=arm64
else
    echo_info "Running on Intel (x86_64)"
    export SKIAZIP=https://github.com/aseprite/skia/releases/download/m124-08a5439a6b/Skia-macOS-Release-x64.zip
    export ARCH=intel
fi

#Everything below this comment is automated and shouldn't normally need to be modified.

#Dependencies check
DUMMY=$( xcode-select -p 2>&1 )
if [ "$?" -eq 0 ]; then
    echo_check "Xcode was found."
else
    echo_cross "Xcode was not found."
    echo "Have you installed it via the App Store?"
    exit 1
fi

if command -v -- "ninja" >/dev/null 2>&1; then
    echo_check "Ninja build system was found."
else
    echo_cross "Ninja build system was not found."
    echo "Did you correctly install it?"
    echo "brew install ninja"
    exit 1
fi

if command -v -- "cmake" >/dev/null 2>&1; then
    echo_check "Cmake was found."
else
    echo_cross "Cmake was not found."
    echo "Did you correctly install it?"
    echo "brew install cmake"
    exit 1
fi

#Beginning directory creation and downloads

if [ -d "$DEPS" ]; then
    echo_check "Deps directory found."
else
    echo_warn "Deps directory was not found."
    echo "Creating deps directory..."
    run mkdir $DEPS
    if [ "$?" -eq 0 ]; then
        echo "Deps directory successfully created."
    else
        echo "Something went wrong in checking for or creating the deps directory."
        echo "Did you set the correct DEPS path for your system?"
        echo "Do you have permission to create a directory in the specified location?"
        exit 1
    fi
fi

if [ -d "$ASEPRITE" ] && [ -n "$(ls -A "$ASEPRITE")" ]; then
    echo_check "Aseprite was found at $ASEPRITE"
else
    echo_warn "Aseprite was not found."
    if [[ ! -s "$TMPDIR/asesrc-${PKG_VERSION}.zip" ]]; then
        echo_warn "Downloading aseprite..."
        run curl $ASEZIP -L -o $TMPDIR/asesrc-${PKG_VERSION}.zip
    fi
    echo_warn "Unzipping to $ASEPRITE..."
    run mkdir -p $ASEPRITE
    run tar -xf $TMPDIR/asesrc-${PKG_VERSION}.zip -C $ASEPRITE
    if [ "$?" -eq 0 ]; then
        echo_check "Aseprite was successfully downloaded and unzipped."
    else
        echo_cross "Aseprite failed to download and extract."
        echo "Are you connected to the internet?"
        echo "Does ASEZIP point to the correct URL?"
        echo "Fatal error. Aborting..."
        exit 1
    fi
fi

if [ -d "$SKIA" ] && [ -n "$(ls -A "$SKIA")" ]; then
    echo_check "Skia was found"
else
    echo_warn "Skia was not found."
    if [[ ! -s "$TMPDIR/asesrc-${PKG_VERSION}.zip" ]]; then
        echo_warn "Downloading Skia..."
        run curl $SKIAZIP -L -o $TMPDIR/skia.zip
    fi
    echo_warn "Unzipping to $SKIA..."
    run mkdir $SKIA
    run tar -xf $TMPDIR/skia.zip -C $SKIA
    if [ "$?" -eq 0 ]; then
        echo_check "Skia was successfully downloaded and unzipped."
    else
        echo_cross "Skia failed to download and extract."
        echo "Are you connected to the internet?"
        echo "Does SKIAZIP point to the correct URL?"
        echo "Fatal Error. Aborting..."
        exit 1
    fi
fi

echo_check "All checks okay!"

# Compile

echo_warn "Setting system architecture..."
run mkdir -p $ASEPRITE/build
if [[ $(echo $ARCH) == *arm64* ]]; then 
    echo_warn "Beginning build for Apple Silicon."
    run cd $ASEPRITE/build && run cmake \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
        -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
        -DLAF_BACKEND=skia \
        -DSKIA_DIR=$SKIA \
        -DSKIA_LIBRARY_DIR=$SKIA/out/Release-arm64 \
        -DSKIA_LIBRARY=$SKIA/out/Release-arm64/libskia.a \
        -DPNG_ARM_NEON:STRING=on \
        -G Ninja \
        ..
elif [[ $(echo $ARCH) == *intel* ]]; then
    echo_warn "Beginning build for Intel x86_64."
    run cd $ASEPRITE/build && run cmake \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_OSX_ARCHITECTURES=x86_64 \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 \
        -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
        -DLAF_BACKEND=skia \
        -DSKIA_DIR=$SKIA \
        -DSKIA_LIBRARY_DIR=$SKIA/out/Release-x64 \
        -DSKIA_LIBRARY=$SKIA/out/Release-x64/libskia.a \
        -G Ninja \
        ..
else
    echo_cross "Failed to set system architecture."
    echo "This should not be happening"
    echo "Fatal error. Aborting..."
    exit 1
fi

if [ "$?" -eq 0 ]; then
    run ninja aseprite
    if [ "$?" -ne 0 ]; then
        echo_cross "Failed to compile"
        echo "Are you using the correct version of Skia?"
        echo "If you edited aseprite's source code you may have made an error, consult the compiler's output."
        echo "Fatal error. Aborting..."
        exit 1
    fi
else
    echo_cross "Configuring cmake failed"
    echo "Was the aseprite source code properly downloaded?"
    echo "Are you using the correct version of Skia?"
    echo "Is cmake up to date?"
    echo "Fatal error. Aborting..."
    exit 1
fi

ICON_LOC=$ASEPRITE/build/bin/Aseprite.app/Contents/Resources/Aseprite.icns
if [[ ! -s "$ICON_LOC" ]]; then
    run curl -L -o $ICON_LOC https://github.com/dominickjohn/aseprite-big-sur-icon/raw/main/AsepriteSurIcon.icns
fi

echo_check "Build complete!"
echo "Finished build is located in the $ASEPRITE/build/bin directory."
ls -l $ASEPRITE/build/bin
echo_info "Copy Aseprite.app to your /Applications and run it like a standard macOS application."
