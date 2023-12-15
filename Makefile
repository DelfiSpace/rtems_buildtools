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
# /* ------------------------------------------------------ */

bsp_install: rtems_source rtems_stm32l4xx_bsp \
	rtems_waf_configure

rtems_source:
	git clone --depth 1 -b master https://github.com/RTEMS/rtems.git $@

# Clone board support package source
# HACK: to be changed later
rtems_stm32l4xx_bsp:
	rm -r ./rtems_source/bsps/arm/stm32l4
	git clone --depth 1 git@gitlab.tudelft.nl:delfispace/twinsat/firmware/rtems/rtems_stm32l4xx_bsp.git \
		./rtems_source/bsps/arm/stm32l4

rtems_stm32l4xx_spec:

# Since the device drivers are meant to be used statically with the board support package,
# they are included as submodules 

# drivers section
#driver_multi_spi_stm32:
#	git clone --depth 1 git@gitlab.tudelft.nl:delfispace/twinsat/firmware/drivers/multi_spi_stm32.git $@

rtems_waf_configure:
	cd ./rtems_source/ && \
		export PATH=$(PREFIX)/bin:"$(PATH)" && \
		rm ./config.ini && \
		echo "[arm/stm32l4]" > config.ini && \
		echo "BUILD_TESTS = True" >> config.ini && \
		./waf configure --prefix=$(PREFIX);

rtems_waf_build:

clean:
	$(RM) rtems

