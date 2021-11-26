#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
#

# Needed Secret Variable
# DEVICE_CODENAME | Your device codename
# TG_TOKEN | Your telegram bot token
# TG_CHAT_ID | Your telegram private ci chat id

echo "Downloading few Dependecies . . ."
# Kernel Sources
     git clone --depth=1 https://github.com/kentanglu/Rocket_Kernel_MT6768 -b eleven merlin

CloneFourteenGugelClang(){
    ClangPath=clang
    [[ "$(pwd)" != "merlin" ]] && cd "merlin"
    mkdir $ClangPath
    rm -rf $ClangPath/*
    if [ ! -e "${MainPath}/clang-r437112.tar.gz" ];then
        wget -q  https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/3a785d33320c48b09f7d6fcf2a37fed702686fdc/clang-r437112.tar.gz -O "clang-r437112.tar.gz"
    fi
    tar -xf clang-r437112.tar.gz -C $ClangPath
}

# Main Declaration
KERNEL_ROOTDIR=$(pwd)/merlin # IMPORTANT ! Fill with your kernel source root directory.
CLANG_ROOTDIR=$(pwd)/clang # IMPORTANT! Put your clang directory here.
export KERNELNAME=Sea-Kernel
export KBUILD_BUILD_USER=Asyanx # Change with your own name or else.
export KBUILD_BUILD_HOST=#ZpyLab # Change with your own hostname.
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
IMAGE=$(pwd)/merlin/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date +"%F-%S")
START=$(date +"%s")
PATH="${PATH}:${CLANG_ROOTDIR}/bin"

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# Post Main Information
tg_post_msg "<b>xKernelCompiler</b>%0ABuilder Name : <code>${KBUILD_BUILD_USER}</code>%0ABuilder Host : <code>${KBUILD_BUILD_HOST}</code>%0ADevice Defconfig: <code>${DEVICE_DEFCONFIG}</code>%0AClang Version : <code>${KBUILD_COMPILER_STRING}</code>%0AClang Rootdir : <code>${CLANG_ROOTDIR}</code>%0AKernel Rootdir : <code>${KERNEL_ROOTDIR}</code>"

# Compile
compile(){
tg_post_msg "<b>xKernelCompiler:</b><code>Compile Kernel DI Mulai</code>"
cd ${KERNEL_ROOTDIR}
make -j$(nproc) O=out ARCH=arm64 merlin_defconfig
make -j$(nproc) ARCH=arm64 O=out \
    CC=${CLANG_ROOTDIR}/bin/clang \
    NM=${CLANG_ROOTDIR}/bin/llvm-nm \
    CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi
  git clone --depth=1 $ANYKERNEL AnyKernel
	cp $IMAGE AnyKernel
}

# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | <b>${KBUILD_COMPILER_STRING}</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}

# clean
function clean() {
	rm -rf $(pwd)/merlin \
	rm -rf $(pwd)/AnyKernel \
	rm -rf $(pwd)/clang
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 $KERNELNAME-$DATE.zip *
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
clean