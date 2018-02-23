TOP        = ../..
SWIGEXE    = $(TOP)/../swig
SWIG_LIB_DIR = $(TOP)/../$(TOP_BUILDDIR_TO_TOP_SRCDIR)Lib
CSRCS    = simple.c
TARGET     = simple
INTERFACE  = simple.i
SWIGOPT    =
FORTRANSRCS = runme.f90

check: build
	$(MAKE) -f $(TOP)/Makefile SRCDIR='$(SRCDIR)' fortran_run

build:
	$(MAKE) -f $(TOP)/Makefile SRCDIR='$(SRCDIR)' CSRCS='$(CSRCS)' \
	  SWIG_LIB_DIR='$(SWIG_LIB_DIR)' SWIGEXE='$(SWIGEXE)' \
	  SWIGOPT='$(SWIGOPT)' TARGET='$(TARGET)' INTERFACE='$(INTERFACE)' fortran_c
	$(MAKE) -f $(TOP)/Makefile TARGET='$(TARGET)' SRCDIR='$(SRCDIR)' \
		FORTRANSRCS='$(FORTRANSRCS)' fortran_compile

clean:
	$(MAKE) -f $(TOP)/Makefile SRCDIR='$(SRCDIR)' fortran_clean
