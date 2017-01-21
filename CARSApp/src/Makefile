TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

# For Kate Feng's implementation of devScaler.c, which uses Till
# Straumann's basicIoOps.h to bridge any mismatch between endianness
# of Joerger scaler hardware and endianness of processor.
#USR_CFLAGS += -DHAS_IOOPS_H

#==================================================
# build a support library that some other application can use

#LIBRARY_IOC += CARSSupport

# CARSRecord.h will be created from CARSRecord.dbd
#DBDINC += CARSRecord
# install support-library .dbd into <top>/dbd
#DBD += CARSSupport.dbd

# The following are compiled and added to the Support library
#CARSSupport_SRCS += CARSRecord.c
CARS_SRCS += mirror.st
CARS_SRCS += Hmirror.st
CARS_SRCS += Mount_sample.st
CARS_SRCS += 14ID-EPS_adm.st
#CARS_SRCS += gentecDuo.st
CARS_SRCS += keithley6485st.st
CARS_SRCS += sigmaMeter.st
CARS_SRCS += MSShutterMono.st
CARS_SRCS += beamCheck.st
CARS_SRCS += beamCheckTbl.st
CARS_SRCS += MS7023Shutter.st
CARS_SRCS += beamCheckMono.st
CARS_SRCS += fpga.st
CARS_SRCS += IDB_MAD.st
CARS_SRCS += laserpower.st
CARS_SRCS += lasershutter.st
CARS_SRCS += M6VALCOpump.st
#CARS_SRCS += lxd.st

#CARSSupport_LIBS += $(EPICS_BASE_IOC_LIBS)
#CARS_Common_LIBS += CARSSupport

#=============================
# build an ioc application

PROD_IOC = CARS

# Note that the order in which .dbd files are added to a list variable
# doesn't matter, but the order of libraries does.

# <name>.dbd will be created from <name>Include.dbd
ifeq ($(OS_CLASS), WIN32)
	DBD  += iocCARSWin32.dbd
	iocCARSWin32_DBD += CARSCommonInclude.dbd

	# If your host supports libpcap and libnet and you want to build Canberra network
	# support uncomment the following line
	#iocCARSWin32_DBD += mcaCanberraSupport.dbd

	# If you want to build parallel port or USB interfaces to Saturn and/or xMAP DXP
	# then uncomment the following two lines
	iocCARSWin32_DBD += dxpSupport.dbd
	CARS_LIBS_WIN32 += dxp handel
endif

ifeq ($(EPICS_HOST_ARCH), cygwin-x86)
	DBD  += iocCARSCygwin.dbd
	iocCARSCygwin_DBD += CARSCommonInclude.dbd

	# If you want to build parallel port or USB interfaces to Saturn and/or xMAP DXP
	# then uncomment the following two lines
	iocCARSCygwin_DBD += dxpSupport.dbd
	CARS_LIBS_cygwin32 += dxp handel
endif

ifeq (vxWorks,$(findstring vxWorks, $(T_A)))
	DBD  += iocCARSVX.dbd
	#iocCARSVX_DBD += iocCARSVXInclude.dbd

	iocCARSVX_DBD += CARSCommonInclude.dbd

	iocCARSVX_DBD += vmeVXSupport.dbd
	iocCARSVX_DBD += stdVXSupport.dbd
	iocCARSVX_DBD += ipVXSupport.dbd
	iocCARSVX_DBD += SIS38XXSupport.dbd
	iocCARSVX_DBD += ipUnidigSupport.dbd
	iocCARSVX_DBD += dac128VSupport.dbd
	iocCARSVX_DBD += ip330Support.dbd

	iocCARSVX_DBD += camacSupport.dbd
	iocCARSVX_DBD += devCamacSupport.dbd
	iocCARSVX_DBD += dxpSupport.dbd
ifdef ALLEN_BRADLEY
	iocCARSVX_DBD += allenBradley.dbd
endif
	iocCARSVX_DBD += quadEMSupport.dbd
	iocCARSVX_DBD += mcaCanberraSupport.dbd
	iocCARSVX_DBD += devLove.dbd
	# from ipac
	iocCARSVX_DBD += tyGSOctal.dbd
	iocCARSVX_DBD += drvIpac.dbd
	# from asyn
	iocCARSVX_DBD += drvGsIP488.dbd
#	iocCARSVX_DBD += vxStats.dbd
	iocCARSVX_DBD += softGlueSupport.dbd
	# from motor
	iocCARSVX_DBD += devDeltaTau.dbd
	iocCARSVX_DBD += devOms.dbd
	iocCARSVX_DBD += dvx2502.dbd
endif

ifeq ($(OS_CLASS), Linux)
	DBD  += iocCARSLinux.dbd
	iocCARSLinux_DBD += CARSCommonInclude.dbd

	# If your host supports libpcap and libnet and you want to build Canberra network
	# support, set LINUX_NET_INSTALLED to YES in <synApps>/configure/CONFIG_SITE.
	ifeq ($(LINUX_NET_INSTALLED), YES)
		iocCARSLinux_DBD += mcaCanberraSupport.dbd
		CARS_LIBS_Linux += mcaCanberra
	endif
	# If your host supports parallel port or USB interfaces to Saturn DXP, set
	# LINUX_USB_INSTALLED to YES in <synApps>/configure/CONFIG_SITE.
	ifeq ($(LINUX_USB_INSTALLED), YES)
		iocCARSLinux_DBD += dxpSupport.dbd
		CARS_LIBS_Linux  += dxp handel
	endif
endif

ifeq ($(OS_CLASS), solaris)
	DBD  += iocCARS_solaris.dbd
	iocCARS_solaris_DBD += CARSCommonInclude.dbd
endif




# <name>_registerRecordDeviceDriver.cpp will be created from <name>.dbd
CARS_SRCS_vxWorks  += iocCARSVX_registerRecordDeviceDriver.cpp
CARS_SRCS_Linux    += iocCARSLinux_registerRecordDeviceDriver.cpp     CARSMain.cpp
CARS_SRCS_WIN32    += iocCARSWin32_registerRecordDeviceDriver.cpp     CARSMain.cpp
CARS_SRCS_cygwin32 += iocCARSCygwin_registerRecordDeviceDriver.cpp    CARSMain.cpp
CARS_SRCS_solaris  += iocCARS_solaris_registerRecordDeviceDriver.cppa CARSMain.cpp

CARS_Common_LIBS += mca
CARS_Common_LIBS += calc
CARS_Common_LIBS += busy
CARS_Common_LIBS += sscan
CARS_Common_LIBS += autosave
CARS_Common_LIBS += optics
CARS_Common_LIBS += std
CARS_Common_LIBS += ip
CARS_Common_LIBS += Acs acsTech80 Aerotech Attocube Faulhaber Ims KohzuMotor Mclennan
CARS_Common_LIBS += Micos MicroMo NewFocus Newport Oriel PI PIJena Parker SmartMotor
CARS_Common_LIBS += ThorLabs softMotor motorSimSupport motor
#CARS_Common_LIBS += ADBase NDPlugin netCDF
###CARS_Common_LIBS += simDetector NDPlugin netCDF ADBase
CARS_Common_LIBS += ADBase
CARS_Common_LIBS += asyn
CARS_Common_LIBS += stream streamSynApps
CARS_Common_LIBS += seq pv
CARS_Common_LIBS += devIocStats
CARS_Common_LIBS += delaygen
CARS_Common_LIBS += dliEpcrSupport
CARS_Common_LIBS += imcalibSupport
CARS_Common_LIBS += pmacAsynIPPort pmacAsynMotor pmacAsynCoord
CARS_Common_LIBS += aliogSupport ## for now just to compile
CARS_Common_LIBS += quadEM
#CARS_Common_LIBS += caPutLog
CARS_Common_LIBS += $(EPICS_BASE_IOC_LIBS)

ifdef ALLEN_BRADLEY
CARS_LIBS_vxWorks += allenBradley
endif
CARS_LIBS_vxWorks += SIS38XX
CARS_LIBS_vxWorks += mcaCanberra
CARS_LIBS_vxWorks += ip330
CARS_LIBS_vxWorks += ipUnidig
CARS_LIBS_vxWorks += dac128V
CARS_LIBS_vxWorks += quadEM
CARS_LIBS_vxWorks += camac devCamac
CARS_LIBS_vxWorks += dxp handel
CARS_LIBS_vxWorks += love
#CARS_LIBS_vxWorks += vxStats
CARS_LIBS_vxWorks += vme
CARS_LIBS_vxWorks += TyGSOctal Ipac
CARS_LIBS_vxWorks += oms DeltaTau
CARS_LIBS_vxWorks += softGlue
CARS_LIBS_vxWorks += analogic

#The following adds support from base/src/vxWorks
CARS_OBJS_vxWorks += $(EPICS_BASE_BIN)/vxComLibrary

##added 05/16 IK
include $(ADCORE)/ADApp/commonDriverMakefile

CARS_LIBS_vxWorks  += $(CARS_Common_LIBS)
CARS_LIBS_Linux    += $(CARS_Common_LIBS)
CARS_LIBS_solaris  += $(CARS_Common_LIBS)
CARS_LIBS_cygwin32 += $(CARS_Common_LIBS)
CARS_LIBS_WIN32    += $(CARS_Common_LIBS)

# If the host has libnet and libpcap for mca/Canberra support
# uncomment the following line.
#CARS_SYS_LIBS_Linux += net pcap

# For USB support on Saturn uncomment the following line
CARS_SYS_LIBS_Linux += usb

# This is needed (and provided) by areaDetector on Linux and WIN32
#CARS_LIBS_WIN32        += PvAPI ImageLib
#CARS_LIBS_Linux        += PvAPI ImageLib

# This is needed by dxp on cygwin and WIN32
CARS_SYS_LIBS_cygwin32 += DLPORTIO PlxApi setupapi
CARS_LIBS_WIN32        += DLPORTIO PlxApi
CARS_SYS_LIBS_WIN32    += setupapi

# This is needed by saveData and asyn VXI-11 on cygwin
CARS_SYS_LIBS_cygwin32 += rpc

# areaDetector needs these
#CARS_SYS_LIBS_solaris   += tiff
#CARS_LIBS_solaris   += jpeg sz z
#CARS_LIBS_solaris += NeXus hdf5_cpp hdf5

# areaDetector needs (and provides) these
#CARS_LIBS_WIN32    += libtiff jpeg libNeXus.dll
#CARS_LIBS_cygwin32 += libtiff jpeg libNeXus.dll


# To use versions of these libraries supplied with areaDetector use this line
#CARS_LIBS_Linux        += NeXus mfhdf df hdf5 mxml
# To use system versions of these libraries use this line
#CARS_SYS_LIBS_Linux    += NeXus mfhdf df hdf5 mxml

# To use versions of these libraries supplied with areaDetector use this line
#CARS_LIBS_Linux        += tiff jpeg z
# To use system versions of these libraries use this line
#CARS_SYS_LIBS_Linux    += tiff jpeg z

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE
