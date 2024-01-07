# Welcome
# This makefile implements the following functions
# 1) Fetch the rtems source 
# 2) Fetch the bsp source for the stm32l4 mcu and its dependancies
# 3) Builds the stm32l4xx bsp for the user selected rtems prefix
#
# WARNING: Currently no version control is implemented for:
# - RTEMS rtems source 
# - CMSIS core headers
# - CMSIS stm32l4 headers
# - Board support package for stm32l4xx
# - Drivers included in the stm32l4xx bsp as submodules

# /* ------------------------------------------------------ */
# /*  CONFIGURATION                                         */
# /* ------------------------------------------------------ */
#
# /* ----To be filled by user ----------------------------- */
# Update PREFIX to include the path of the RTEMS installation on your system
# The selelected installation shall contain the rtems generated gcc toolchain
# For example
export PREFIX=$(HOME)/RTEMS/bld/6
APP_DIR := ../RTEMS/app/rtems_camera_firmware/


# /* ----Remote directories configuration ----------------- */
BSP_NAME := stm32l4_bsp
BSP_REPO_URL := git@gitlab.tudelft.nl:delfispace/twinsat/firmware/rtems/rtems_stm32l4xx_bsp.git
BSP_DEST_DIR := ./bsps/arm/stm32l4
BSP_COMMIT_HASH := HEAD


SPC_NAME := stm32l4_bsp_specs
SPC_REPO_URL := git@gitlab.tudelft.nl:delfispace/twinsat/firmware/rtems/rtems_stm32l4xx_bsp_spec.git
SPC_DEST_DIR := ./spec/build/bsps/arm/stm32l4
SPC_COMMIT_HASH := HEAD

PTCH_REPO_URL := git@gitlab.tudelft.nl:delfispace/twinsat/firmware/rtems/rtems_patches.git
PTCH_COMMIT_HASH := HEAD

# /* ------------------------------------------------------ */
# /*  GENRAL API                                            */
# /* ------------------------------------------------------ */
SRC_DIR := ./src
PTCH_DIR := ./patches
BLD_DIR := ./bld

# Get all patch files in the patch directory
PATCHES := $(shell find $(PTCH_DIR) -type f -name '*.patch' ! -name '_*.patch')
$(warning Value of PATCHES is $(PATCHES))

.PHONY: $(SRC_DIR)/$(BSP_NAME) \
				$(SRC_DIR)/$(SPC_NAME) \
				$(PTCH_DIR) \
				bsp_install 

all: app_waf_compile
clean: makedir_source makedir_build bsp_install

source: makedir_source \
				$(SRC_DIR)/rtems \
				$(SRC_DIR)/$(BSP_NAME) \
				$(SRC_DIR)/$(SPC_NAME) \
				$(PTCH_DIR) 

bsp_prepare:source \
					makedir_build \
					$(BLD_DIR)/bsps \
					$(BLD_DIR)/$(BSP_DEST_DIR) \
					$(BLD_DIR)/$(SPC_DEST_DIR) \
					apply_patches


bsp_install: bsp_prepare \
						bsp_waf_configure \
						bsp_waf_build \
						bsp_waf_install


# /* ------------------------------------------------------ */
# /*  OBTAIN SOURCES                                        */
# /* ------------------------------------------------------ */

makedir_source:
	mkdir -p $(SRC_DIR)

#get rtems source
$(SRC_DIR)/rtems: 
	git clone --depth 1 -b master https://github.com/RTEMS/rtems.git $(SRC_DIR)/rtems

# Clone BSP source and build specifications
$(SRC_DIR)/$(BSP_NAME):
		$(RM) -r $(SRC_DIR)/$(BSP_NAME) && \
		git clone $(BSP_REPO_URL) $(SRC_DIR)/$(BSP_NAME) && \
		cd $(SRC_DIR)/$(BSP_NAME) && \
		git checkout $(BSP_COMMIT_HASH)

$(SRC_DIR)/$(SPC_NAME): 
		$(RM) -r $(SRC_DIR)/$(SPC_NAME) && \
		git clone $(SPC_REPO_URL) $(SRC_DIR)/$(SPC_NAME) && \
		cd $(SRC_DIR)/$(SPC_NAME) && \
		git checkout $(SPC_COMMIT_HASH)

# Clone patches
#$(PTCH_DIR): 
		#$(RM) -r $(PTCH_DIR) && \
		#git clone $(PTCH_REPO_URL) $(PTCH_DIR) && \
		#cd $(PTCH_DIR) && \
		#git checkout $(PTCH_COMMIT_HASH)

# /* ------------------------------------------------------ */
# /*  FILL BUILD DIR                                        */
# /* ------------------------------------------------------ */
makedir_build:
	mkdir -p $(BLD_DIR)

clean_bld:
	$(RM) -r $(BLD_DIR)/*
	$(RM) -r $(BLD_DIR)/.*

# fill the build directory
$(BLD_DIR)/bsps: makedir_build clean_bld
	cp -r $(SRC_DIR)/rtems/* $(BLD_DIR)/
	cp -r $(SRC_DIR)/rtems/.* $(BLD_DIR)/

$(BLD_DIR)/$(BSP_DEST_DIR): makedir_build clean_bld
	cp -r $(SRC_DIR)/$(BSP_NAME) $(BLD_DIR)/$(BSP_DEST_DIR)

$(BLD_DIR)/$(SPC_DEST_DIR): makedir_build clean_bld
	cp -r $(SRC_DIR)/$(SPC_NAME) $(BLD_DIR)/$(SPC_DEST_DIR)

# apply patches
apply_patches:
	cd $(BLD_DIR) && \
	for patch in $(PATCHES); do \
		git apply ../$$patch; \
	done

# /* ------------------------------------------------------ */
# /*  RTEMS BSP BUILD                                       */
# /* ------------------------------------------------------ */

bsp_just_build: bsp_waf_configure bsp_waf_build bsp_waf_install

# for now tests are not enabled
#echo "BUILD_TESTS = True" >> config.ini &&
bsp_waf_configure:
	cd $(BLD_DIR) && \
		export PATH=$(PREFIX)/bin:"$(PATH)" && \
		rm ./config.ini; \
		echo "[arm/stm32l4]" > config.ini && \
		./waf configure --prefix=$(PREFIX);

bsp_waf_build:
	cd $(BLD_DIR) && \
		export PATH=$(PREFIX)/bin:"$(PATH)" && \
		bear -- ./waf;

bsp_waf_install:
	cd $(BLD_DIR) && \
		export PATH=$(PREFIX)/bin:"$(PATH)" && \
		./waf install;

# /* ------------------------------------------------------ */
# /*  APPLICATION BUILD                                     */
# /* ------------------------------------------------------ */

app_waf_compile: bsp_just_build
		cd $(APP_DIR) && \
	./waf clean && \
	./waf  && \
  ./waf configure --rtems=$(PREFIX) --rtems-bs=arm/stm32l4 && \
  ./waf

# /* ------------------------------------------------------ */
# /*  CLEANUP                                               */
# /* ------------------------------------------------------ */

