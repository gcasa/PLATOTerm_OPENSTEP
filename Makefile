#
# Generated by the NeXT Project Builder.
#
# NOTE: Do NOT change this file -- Project Builder maintains it.
#
# Put all of your customizations in files called Makefile.preamble
# and Makefile.postamble (both optional), and Makefile will include them.
#

NAME = PLATOterm

PROJECTVERSION = 2.6
PROJECT_TYPE = Application
LANGUAGE = English

ICONSECTIONS =	-sectcreate __ICON app /NextLibrary/Frameworks/AppKit.framework/Resources/NSDefaultApplicationIcon.tiff

LOCAL_RESOURCES = NEXTSTEP_PLATOterm.nib WINDOWS_PLATOterm.nib

CLASSES = AppDelegate.m

HFILES = AppDelegate.h

MFILES = PLATOterm_main.m

OTHERSRCS = Makefile.preamble Makefile Makefile.postamble m.template\
            h.template


MAKEFILEDIR = $(NEXT_ROOT)/NextDeveloper/Makefiles/pb_makefiles
CODE_GEN_STYLE = DYNAMIC
MAKEFILE = app.make
NEXTSTEP_INSTALLDIR = $(HOME)/Apps
WINDOWS_INSTALLDIR = /MyApps
LIBS = 
DEBUG_LIBS = $(LIBS)
PROF_LIBS = $(LIBS)


FRAMEWORKS = -framework AppKit -framework Foundation


include $(MAKEFILEDIR)/platform.make

-include Makefile.preamble

include $(MAKEFILEDIR)/$(MAKEFILE)

-include Makefile.postamble

-include Makefile.dependencies
