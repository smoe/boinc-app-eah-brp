###########################################################################
#   Copyright (C) 2011 by Oliver Bock                                     #
#   oliver.bock[AT]aei.mpg.de                                             #
#                                                                         #
#   This file is part of Einstein@Home (Radio Pulsar Edition).            #
#                                                                         #
#   Einstein@Home is free software: you can redistribute it and/or modify #
#   it under the terms of the GNU General Public License as published     #
#   by the Free Software Foundation, version 2 of the License.            #
#                                                                         #
#   Einstein@Home is distributed in the hope that it will be useful,      #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with Einstein@Home. If not, see <http://www.gnu.org/licenses/>. #
#                                                                         #
###########################################################################

# path settings
EINSTEIN_RADIO_SRC?=$(PWD)
EINSTEIN_RADIO_INSTALL?=$(PWD)
NVIDIA_SDK_INSTALL_PATH?=/usr/local/cuda
AMDAPPSDKROOT?=/opt/AMDAPP
ARCH=`uname -m`

# config values
CXX ?= g++

# variables
LIBS += -Wl,-Bstatic
LIBS += -L$(EINSTEIN_RADIO_INSTALL)/lib64 -L$(EINSTEIN_RADIO_INSTALL)/lib
LIBS += $(shell $(EINSTEIN_RADIO_INSTALL)/bin/gsl-config --libs)
LIBS += $(shell export PKG_CONFIG_PATH=$(EINSTEIN_RADIO_INSTALL)/lib/pkgconfig && pkg-config --libs fftw3f)
LIBS += $(shell $(EINSTEIN_RADIO_INSTALL)/bin/xml2-config --libs)
LIBS += -lclfft
LIBS += -lboinc_opencl -lboinc_api -lboinc
LIBS += -lbfd -liberty
LIBS += -L/usr/lib
LIBS += -lstdc++
LIBS += -Wl,-Bdynamic
LIBS += -L$(AMDAPPSDKROOT)/lib/$(ARCH)
LIBS += -lOpenCL
LIBS += -lpthread -lm -lc
LIBS += $(EINSTEIN_RADIO_INSTALL)/lib/libz.a

LDFLAGS += -static-libgcc

CXXFLAGS += -I$(EINSTEIN_RADIO_INSTALL)/include
CXXFLAGS += $(shell $(EINSTEIN_RADIO_INSTALL)/bin/gsl-config --cflags)
CXXFLAGS += $(shell export PKG_CONFIG_PATH=$(EINSTEIN_RADIO_INSTALL)/lib/pkgconfig && pkg-config --cflags fftw3f)
CXXFLAGS += $(shell $(EINSTEIN_RADIO_INSTALL)/bin/xml2-config --cflags)
CXXFLAGS += -I$(EINSTEIN_RADIO_INSTALL)/include/boinc
CXXFLAGS += -I$(NVIDIA_SDK_INSTALL_PATH)/cuda/include -I$(AMDAPPSDKROOT)/include -I../include
CXXFLAGS += -malign-double
CXXFLAGS += -DHAVE_INLINE -DBOINCIFIED
CXXFLAGS += -DUSE_OPENCL

DEPS = Makefile
OBJS = demod_binary.o demod_binary_ocl.o ocl_utilities.o hs_common.o rngmed.o erp_boinc_ipc.o erp_getopt.o erp_getopt1.o erp_utilities.o erp_execinfo_plus.o
EINSTEINBINARY_TARGET ?= einsteinbinary_opencl
TARGET = $(EINSTEINBINARY_TARGET)

# primary role based tagets
default: release
debug: $(TARGET)
profile: clean $(TARGET)
release: clean $(TARGET)

# target specific options (generic)
debug: CXXFLAGS_BASE += -DLOGLEVEL=debug -pg -rdynamic -O0 -Wall
profile: CXXFLAGS_BASE += -DNDEBUG -DLOGLEVEL=info -rdynamic -O3 -Wall
release: CXXFLAGS_BASE += -DNDEBUG -DLOGLEVEL=info -rdynamic -O3 -Wall

# target specific options (gcc)
debug: CXXFLAGS_GCC += $(CXXFLAGS) $(CXXFLAGS_BASE) -ggdb3
profile: CXXFLAGS_GCC += $(CXXFLAGS) $(CXXFLAGS_BASE) -ggdb3 -fprofile-generate
release: CXXFLAGS_GCC += $(CXXFLAGS) $(CXXFLAGS_BASE) -ggdb3 -fprofile-use

# file based targets
profile:
	@echo "Removing previous profiling data..."
	rm -f *_profile.*
	rm -f *.gcda
	@echo "Gathering profiling data (this takes roughly one minute)..."
	./$(TARGET) -t $(EINSTEIN_RADIO_SRC)/../test/templates_400Hz_2_short.bank -l $(EINSTEIN_RADIO_SRC)/data/zaplist_232.txt -A 0.04 -P 4.0 -W -z -i $(EINSTEIN_RADIO_SRC)/../test/J1907+0740_dm_482.binary -c status_profile.cpt -o results_profile.cand
	@echo "Finished gathering profiling data..."

$(TARGET): $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_boinc_wrapper.cpp $(OBJS)
	$(CXX) -g $(CXXFLAGS_GCC) $(LDFLAGS) $(EINSTEIN_RADIO_SRC)/erp_boinc_wrapper.cpp -o $(TARGET) $(OBJS) $(LIBS)

demod_binary.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/demod_binary.c $(EINSTEIN_RADIO_SRC)/demod_binary.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/demod_binary.c

demod_binary_ocl.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/opencl/app/demod_binary_ocl.cpp $(EINSTEIN_RADIO_SRC)/opencl/app/demod_binary_ocl.h $(EINSTEIN_RADIO_SRC)/opencl/app/demod_binary_ocl_kernels.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/opencl/app/demod_binary_ocl.cpp

ocl_utilities.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/opencl/app/ocl_utilities.cpp $(EINSTEIN_RADIO_SRC)/opencl/app/ocl_utilities.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/opencl/app/ocl_utilities.cpp

hs_common.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/hs_common.c $(EINSTEIN_RADIO_SRC)/hs_common.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/hs_common.c

rngmed.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/rngmed.c $(EINSTEIN_RADIO_SRC)/rngmed.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/rngmed.c

erp_boinc_ipc.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_boinc_ipc.cpp $(EINSTEIN_RADIO_SRC)/erp_boinc_ipc.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/erp_boinc_ipc.cpp

erp_getopt.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_getopt.c $(EINSTEIN_RADIO_SRC)/erp_getopt.h $(EINSTEIN_RADIO_SRC)/erp_getopt_int.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/erp_getopt.c

erp_getopt1.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_getopt1.c $(EINSTEIN_RADIO_SRC)/erp_getopt.h $(EINSTEIN_RADIO_SRC)/erp_getopt_int.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/erp_getopt1.c

erp_utilities.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_utilities.cpp $(EINSTEIN_RADIO_SRC)/erp_utilities.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/erp_utilities.cpp

erp_execinfo_plus.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_execinfo_plus.c $(EINSTEIN_RADIO_SRC)/erp_execinfo_plus.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/erp_execinfo_plus.c

install:
	mkdir -p $(EINSTEIN_RADIO_INSTALL)/../dist
	cp $(TARGET) $(EINSTEIN_RADIO_INSTALL)/../dist

clean:
	rm -f $(OBJS) $(TARGET)
