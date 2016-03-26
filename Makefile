#--------------------------------------------------------------------------
#- The AVR-Ada Library is free software;  you can redistribute it and/or --
#- modify it under terms of the  GNU General Public License as published --
#- by  the  Free Software  Foundation;  either  version 2, or  (at  your --
#- option) any later version.  The AVR-Ada Library is distributed in the --
#- hope that it will be useful, but  WITHOUT ANY WARRANTY;  without even --
#- the  implied warranty of MERCHANTABILITY or FITNESS FOR A  PARTICULAR --
#- PURPOSE. See the GNU General Public License for more details.         --
#--------------------------------------------------------------------------

# This Makefile builds the ESP8266 run time system (RTS)

###############################################################
#
#  Top
#
all: build_rts
install: install_rts
uninstall: uninstall_rts

.PHONY: all clean install uninstall


###############################################################
#
#  Config
#
-include config

config:
	-./configure


###############################################################
#
#  Settings
#
# Ada source files
ADASRC = system.ads \
   s-maccod.ads \
   s-stoele.ads s-stoele.adb \
   s-unstyp.ads \
   s-bitops.ads s-bitops.adb \
   s-stalib.ads \
   s-parame.ads \
   s-secsta.ads s-secsta.adb \
   s-memory.ads s-memory.adb \
   interfac.ads i-c.ads \
   i-cstrin.ads i-cstrin.adb \
   ada.ads \
   unchconv.ads a-unccon.ads \
   a-charac.ads a-chlat1.ads a-chlat9.ads \
   a-except.ads a-except.adb \
   gnat.ads g-souinf.ads

#   s-gccbui.ads \
#   s-intimg.ads \
#   a-tags.ads a-tags.adb \
#   a-stream.ads a-stream.adb \
#   s-stratt.ads s-stratt.adb \
#   a-calend.ads \

#   s-htable.ads s-htable.adb
#   a-stream.ads
#   s-finroo.ads s-finroo.adb a-finali.ads a-finali.adb
#   a-reatim.adb a-reatim.ads
#   a-interr.ads a-intnam.ads a-intsig.ads s-interr.adb s-interr.ads

INCSRC := $(ADASRC:%=gcc/$(VER)/%)
RTSSRC := $(ADASRC:%=rts/adainclude/%)

# Library to build
LIB := libgnat.a
RTS_LIB := adalib/$(LIB)

# Objects needed in library
OBJS = s-bitops.o \
       a-except.o \
       s-memory.o \
       s-secsta.o \

# keep the blank line above
#       a-tags.o \


# .ali for all specs
ALIS = $(ADASRC:.ads=.ali)


# Sources do not exist in rts/adalib but in rts/adainclude
vpath %.ads ../adainclude
vpath %.adb ../adainclude
#vpath %.S   ../../asm

# Includes relative to $(VER)/adalib
INC = -I- -I../adainclude

# Compile flags
ADAFLAGS = -g -Os -gnatn -gnatpg
# -fdata-sections -ffunction-sections
ASMFLAGS = -c -I. -x assembler-with-cpp -mmcu=$(MCU)

# Modes for installed items
INSTALL_FILE_MODE := u=rw,go=r
INSTALL_SRC_MODE := ugo=r
INSTALL_DIR_MODE := u=rwx,go=rx


###############################################################
#
#  Tools
#
# target prefix
TP      = xtensa-lx106-elf
CC      = $(TP)-gcc
RM      = rm -f
CP      = cp
INSTALL = install
AR      = $(TP)-ar
RANLIB  = $(TP)-ranlib
MKDIR   = mkdir
TAR     = tar
ECHO    = echo
CHMOD   = chmod
RMDIR   = rmdir


###############################################################
#
#  Build
#
build_rts: rts/adalib/$(LIB)

rts/adalib/$(LIB): rts/adalib rts/adainclude $(RTSSRC)
	$(MAKE) -C rts/adalib -f ../../Makefile $(ALIS)
	cd rts/adalib; $(AR) cr $(LIB) $(OBJS); $(RANLIB) $(LIB); $(RM) *.o; cd ../..

rts/adalib:
	$(MKDIR) -p $@

rts/adainclude:
	$(MKDIR) -p $@

$(LIB): $(OBJS)
	$(AR) cr $@ $^
	$(RANLIB) $@


###############################################################
#
#  Clean
#
clean:
	$(RM) -r rts

.PHONY: clean


###############################################################
#
#  Install
#
ifndef RTS_BASE
install_rts:
	$(error cannot install until 'configure' has been run)
else
install_rts: build_rts uninstall_rts
	$(CP) -a rts/adainclude $(RTS_BASE)
	$(CP) -a rts/adalib $(RTS_BASE)
#	-$(MKDIR) $(RTS_BASE)/adainclude
#	-$(MKDIR) $(RTS_BASE)/adalib
#	-$(CP) adainclude/system.ads $(RTS_BASE)/adainclude
#	-$(CP) README.gnatlink_inst  $(RTS_BASE)/adainclude
#	-$(CP) README.gprconfig      $(RTS_BASE)/adalib
endif

.PHONY: install_rts


###############################################################
#
#  Uninstall
#
ifndef RTS_BASE
uninstall_rts:
	$(error cannot uninstall until 'configure' has been run)
else
uninstall_rts:
	$(RM) -r $(RTS_BASE)/adainclude
	$(RM) -r $(RTS_BASE)/adalib
endif

.PHONY: uninstall_rts


###############################################################
#
#  Implicit rules
#

# Copy source files into rts/adainclude directory if they have
# changed.  Write access is removed because we need to discourage
# modification of these copies (mods that won't be retained).
rts/adainclude/%: gcc/$(VER)/adainclude/%
	-$(INSTALL) --preserve-timestamps --mode=$(INSTALL_SRC_MODE) $^ $@

# keep the order of the following two implicit rules.  This way it
# tries to build a .ali first from .adb if available.  Only if there
# is no .adb, it tries to build from .ads.
%.ali %.o : %.adb
	$(CC) -c $(ADAFLAGS) $(INC) $<

%.ali %.o : %.ads
	$(CC) -c $(ADAFLAGS) $(INC) $<

%.o : %.S
	$(CC) -c $(ASMFLAGS) $<

-include Makefile.devel.post
