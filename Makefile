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

# /* ----To be filled by user ----------------------------- */
# Update PREFIX to include the path of the RTEMS installation on your system
# The selelected installation shall contain the rtems generated gcc toolchain
# For example
export PREFIX=$(HOME)/RTEMS/bld/6
#
# /* ----Remote directories configuration ----------------- */

BSP_REPO_URL := git@gitlab.tudelft.nl:delfispace/twinsat/firmware/rtems/rtems_stm32l4xx_bsp.git
BSP_DEST_DIR := ./rtems_source/bsps/arm/stm32l4

SPC_REPO_URL := git@gitlab.tudelft.nl:delfispace/twinsat/firmware/rtems/rtems_stm32l4xx_bsp_spec.git
SPC_DEST_DIR := ./rtems_source/spec/build/bsps/arm/stm32l4

# /* ------------------------------------------------------ */

bsp_install: rtems_source $(BSP_DEST_DIR) $(SPC_DEST_DIR) \
	rtems_waf_configure rtems_waf_build rtems_waf_install

rtems_source:
	git clone --depth 1 -b master https://github.com/RTEMS/rtems.git $@

# Clone board support package source
$(BSP_DEST_DIR):
	git clone $(BSP_REPO_URL) $(BSP_DEST_DIR)

$(SPC_DEST_DIR):
	git clone $(SPC_REPO_URL) $(SPC_DEST_DIR)

# Since the device drivers are meant to be used statically with the board support package,
# they are included as submodules 

# for now tests are not enabled
#echo "BUILD_TESTS = True" >> config.ini &&
rtems_waf_configure:
	cd ./rtems_source/ && \
		export PATH=$(PREFIX)/bin:"$(PATH)" && \
		rm ./config.ini; \
		echo "[arm/stm32l4]" > config.ini && \
		./waf configure --prefix=$(PREFIX);

rtems_waf_build:
	cd ./rtems_source/ && \
		export PATH=$(PREFIX)/bin:"$(PATH)" && \
		./waf;

rtems_waf_install:
	cd ./rtems_source/ && \
		export PATH=$(PREFIX)/bin:"$(PATH)" && \
		./waf install;


clean: 
	$(RM) -r rtems_source

