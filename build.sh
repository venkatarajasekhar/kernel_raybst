#!/bin/bash
###################################
#Functions                        #
###################################
DIE() { LOG "FAILED : $*"; exit 1; }
LOG() { printf "\n$@\n\n"; }
TRY() { "$@" || DIE "$@"; }
COMPILE() {
echo "Starting build"
echo "What is your device codename?"
read codename
export ARCH=arm
make "$codename"_defconfig
make zImage -j"$J"
mkdir zip
mkdir modules
}
MKRAMDISK() {
	mkdir work
	cd work
	rm * -rf
	cp ../initramfs/* .
	find . | cpio -o > ../initramfs.cpio | gzip ../initramfs.cpio
	rm * -rf
	cp ../initramfs.cpio.gz .
	cp ../arch/arm/boot/zImage .
}
MKBOOTIMG() {
#MKBOOTIMG ARGS
echo "CMDLINE ARGS?"
read CMDLINE
echo "--cmdline is set to $CMDLINE"
####################################
echo "PAGESIZE"
read PAGESIZE
echo "--pagesize is set to $PAGESIZE"
####################################
echo "BASE"
read BASE
echo "--base is set to $BASE"
####################################
echo "RAMDISKADDRESS"
read RAMADDR
echo "--ramdiskaddr is set to $RAMADDR"
####################################
cd work
../tools/mkbootimg --cmdline "$CMDLINE" --kernel zImage --ramdisk initramfs.cpio.gz --pagesize $PAGE --base $BASE --ramdiskaddr $RAMADDR -o $ boot.img
cp boot.img ../zip/
}
MODULES() {
cd work
echo "Copying kernel modules"
find -name '*.ko' -exec cp -av {} ../modules/ \;
mkdir ../zip/system
mkdir ../zip/system/lib
cp ../modules ../zip/system/lib/modules -r
}
MKZIP() {
echo "Creating update.zip..."
cd zip
zip -rq kernel_update-$DATE.zip .
mv -f kernel_update-$DATE.zip $HOME
echo "Kernel located at $HOME/kernel_update-$DATE.zip"
}
####################################
#Variables                         #
####################################
J=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
MODULES=modules
TOOLS=bins
OUT=arch/arm/boot/
WORK=work
ZIP=zip
HOME=.
while true; do
    read -p "Compile Kernel? (answer no if zImage already compiled)" yn
    case $yn in
        [Yy]* ) TRY COMPILE; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done
while true; do
    read -p "Make a boot.img?" yn
    case $yn in
        [Yy]* ) TRY MKRAMDISK; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
while true; do
    read -p "Make an update.zip?" yn
    case $yn in
        [Yy]* ) TRY MKBOOTIMG; MODULES; MKZIP; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo "Thanks for running my script!!!! :D"
echo "Thanks to Shabbypenguin, Kanerix and jt1134"
echo "For help/input on this script"

