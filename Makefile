export CARABOOT_RELEASE=v2.8
TARGET_NAME=Caraboot-$(CARABOOT_RELEASE)
TARGET_DIR=/work/srv/tftp/caramb
TARGET_FILE=$(TARGET_NAME)_Rev.$(SVN).bin

export BUILD_TOPDIR=$(PWD)
export STAGING_DIR=$(BUILD_TOPDIR)/tmp
export UBOOTDIR=$(BUILD_TOPDIR)/u-boot

### Toolchain config ###
OPENWRT_PATH=/work/projects/OpenWrt/Carambola/ImageBuilder/BarrierBreaker-14.07
CONFIG_TOOLCHAIN_PREFIX=$(OPENWRT_PATH)/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux-

#buildroot
#CONFIG_TOOLCHAIN_PREFIX=/opt/build/toolchain-mipsbe-4.7.3/bin/mips-linux-

#openwrt NOT YET
#CONFIG_TOOLCHAIN_PREFIX=mips-openwrt-linux-uclibc-
#export PATH:=$(BUILD_TOPDIR)/toolchain/bin/:$(PATH)
########################

URL=http://server/svn/ARM-Linux/platforms/Carambola/Caraboot
REVISIONFILE = revision.txt
SVNCMD = LC_ALL=C svn info $(URL) | grep "Rev:" | cut -b 19- | tr -d "\n" > $(REVISIONFILE); \
	if [ ! -s $(REVISIONFILE) ]; then echo -n Unknown > $(REVISIONFILE); fi
SVN:=$(shell  if [ ! -s $(REVISIONFILE) ]; then  $(SVNCMD) fi; cat $(REVISIONFILE) )

EXTRAVERSION := "-$(CARABOOT_RELEASE) SVN Rev.$(SVN)"

export CROSS_COMPILE=$(CONFIG_TOOLCHAIN_PREFIX)
export UBOOT_GCC_4_3_3_EXTRA_CFLAGS=-fPIC
export BUILD_TYPE=squashfs
export STAGING_DIR=$(PWD)/tmp

export COMPRESSED_UBOOT=0
export FLASH_SIZE=16
export NEW_DDR_TAP_CAL=1
export CONFIG_HORNET_XTAL=40
export CONFIG_HORNET_1_1_WAR=1

UBOOT_BINARY=u-boot.bin
BOARD_TYPE=carambola2

UBOOTFILE=$(BOARD_TYPE)_u-boot.bin

MAKECMD=$(MAKE) --no-print-directory ARCH=mips EXTRAVERSION=$(EXTRAVERSION) -C $(UBOOTDIR)


.PHONY: all
all:
	@$(MAKE) --no-print-directory svn
	@$(MAKE) --no-print-directory install

install: $(UBOOTDIR)/$(UBOOT_BINARY)
	@echo Install $(TARGET_FILE) to  $(TARGET_DIR)
	@cp -f $(UBOOTDIR)/$(UBOOT_BINARY) $(BUILD_TOPDIR)/$(TARGET_FILE)
	@rm -f $(BUILD_TOPDIR)/$(UBOOT_BINARY)
	@ln -s $(TARGET_FILE) $(UBOOT_BINARY)
	@cp -f $(BUILD_TOPDIR)/$(TARGET_FILE) $(TARGET_DIR)
	@echo Install done

.PHONY: svn
svn:
	@rm -f $(REVISIONFILE)
	@$(SVNCMD) 
	@echo "$(TARGET_NAME) SVN Rev.:$(SVN)"


.PHONY: bin
bin: 
	@rm -f $(UBOOTDIR)/$(UBOOT_BINARY)
	$(MAKE) $(UBOOTDIR)/$(UBOOT_BINARY)

$(UBOOTDIR)/$(UBOOT_BINARY): $(UBOOTDIR)/include/config.h $(REVISIONFILE) Makefile
	@echo Build [$(TARGET_NAME)] SVN Rev.:$(SVN)
	@$(MAKECMD) all
	@echo Build done

.PHONY: config	
config: $(UBOOTDIR)/include/config.h

$(UBOOTDIR)/include/config.h:
	@echo "Configure $(NAME)"
	@$(MAKECMD) $(BOARD_TYPE)_config
	
	
$(REVISIONFILE):
	$(MAKE) --no-print-directory svn
	
clean:
	@rm -f $(REVISIONFILE) $(BUILD_TOPDIR)/$(TARGET_FILE)
	@$(MAKECMD) distclean
