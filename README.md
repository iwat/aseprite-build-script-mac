# Aseprite-Build-Script-Mac

**Created by [Chasnah](https://chasnah.com/)**
**Modified by [Chaiwat](https://github.com/iwat/)**

## An automated macOS Zsh script for easily compiling Aseprite

This script was tested in macOS Tahoe on an M4 Macbook Air. This script will detect either Intel x86_64 or Apple Silicon arm64, then build Aseprite for the detected CPU architecture.

As long as all dependencies are met and all paths are correct this script will automatically download and extract
both the Aseprite source code and a pre-built package of Skia then run the build process.

## Dependencies

* The latest version of [Cmake](https://cmake.org)
* [Curl](https://curl.se/) (Bundled with macOS)
* [Ninja](https://ninja-build.org/) build system
* Minimum [Xcode 16.3](https://apps.apple.com/us/app/xcode/id497799835?mt=12) and macOS 15.4 SDK
* Installing [Homebrew](<https://homebrew.sh/>) is recommended to install several dependencies:

         brew install ninja cmake

* Note that Homebrew requires Xcode's Command Line Tools which can be installed with the following command:

         xcode-select --install

## Selecting version

1. Visit https://github.com/aseprite/aseprite/releases
2. Find the version you want. It would be wise to not select a beta version
3. Expand **Assets** if it's not already expanded
4. Find `Aseprite-v#.##.##-Source.zip`, copy the URL. It should look like `https://github.com/aseprite/aseprite/releases/download/v{TAG_VERSION}/Aseprite-v{PKG_VERSION}-Source.zip`
5. Modify the first few lines of `aseprite-build-script-macos.sh`, set `TAG_VERSION` and `PKG_VERSION` accordingly.
5. Run the script

## Building

After adjusting version identifiers, simply execute the script and it will run completely hands off. Creating your specified working directory and all subdirectories if they do not already exist.

Aseprite source code and a pre-built copy of Skia are curled into the temp directory and extracted into their respective subdirectories.

The script will then begin the build process based on instructions from [INSTALL.md](https://github.com/aseprite/aseprite/blob/v1.3.14.4/INSTALL.md).

Upon completion the script will output a DIR command displaying the newly compiled Aseprite located in the `$PROJECT_DIR/build/aseprite-{PKG_VERSION}/build/bin/Aseprite.app` directory. You can copy that folder to your `/Applications` and run it just like a normal macOS application.

Enjoy using Aseprite!
