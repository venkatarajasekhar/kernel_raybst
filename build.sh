#!/bin/bash
###################################
#Functions			  #
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
	cp ../initramfs/* .
	find . | cpio -o > ../initramfs.cpio | gzip ../initramfs.cpio
	rm * -rf
	cp ../initramfs.cpio.gz .	
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
echo "RAMADDR"
read RAMADDR
echo "--base is set to $RAMADDR"
####################################
$TOOLS/mkbootimg --cmdline "$CMDLINE" --kernel $OUT/zImage --ramdisk $WORK/ramdisk.cpio.gz --pagesize $PAGE --base $BASE --ramdiskaddr $RAMADDR -o $OUT/boot.img
cp $OUT/boot.img $ZIP/
}
MODULES() {
echo "Copying kernel modules"
find -name '*.ko' -exec cp -av {} $MODULES/ \;
cp $MODULES/ $ZIP/system/lib/modules -r
}
MKZIP() {
echo "Creating update.zip..."
cd zip
zip -rq kernel_update-$DATE.zip .
mv -f kernel_update-$DATE.zip $HOME
echo "Kernel located at $HOME/kernel_update-$DATE.zip"
}
####################################
#Variables			   #
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
        [Yy]* ) TRY MKBOOTIMG; MODULES; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo "Thanks for running my script!!!! :D"
echo "Thanks to Shabbypenguin, Kanerix and jt1134"
echo "For help/input on this script"

