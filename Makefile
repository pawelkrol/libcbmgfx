DEBUG := 0
# DEBUG := 1

CURRENT_DIR := $(shell pwd)

ifeq ($(DEBUG),1)
ARGS := -ggdb3 -Og
else
ARGS := -O3
endif

PREFIX := $(DESTDIR)/usr

CBMGFX    := cbmgfx
LIBCBMGFX := lib$(CBMGFX)
VERSION   := 1.1.0

DIRS  := $(CURRENT_DIR) $(PREFIX)/lib64
INC   := $(foreach DIR,$(DIRS),-I$(DIR))
LIB   := $(foreach DIR,$(DIRS),-L$(DIR))
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
LD_LIBRARY_PATH := $(subst $(SPACE),:,$(DIRS))

DEBUG_SUFFIX := $(if $(findstring 1,$(DEBUG)),D,)

CBMGFX_LDFLAGS := -lboost_filesystem -lcbmgfx$(DEBUG_SUFFIX) -lpng

CC      := g++
CFLAGS  := -g -m64 -std=c++2c -Wextra
CC_OPTS := $(INC) -m64 -Wall -Werror $(ARGS)
CC_LIBS := $(LIB) -m64 -rdynamic -lc -lm $(CBMGFX_LDFLAGS)

INSTALL_INC := $(PREFIX)/include
INSTALL_LIB := $(PREFIX)/lib64

SRCS := $(shell ls *.s) $(CBMGFX).cpp

TEST     := test
TEST_CPP := $(TEST).cpp

RPMBUILD         := $(HOME)/rpmbuild
RPMBUILD_SOURCES := $(RPMBUILD)/SOURCES
RPMBUILD_SPECS   := $(RPMBUILD)/SPECS

DIST        := $(LIBCBMGFX)-$(VERSION)
DIST_SPEC   := $(LIBCBMGFX).spec
DIST_TAR_GZ := $(DIST).tar.gz

LOCAL_DEBUG_SUFFIX := $(if $(findstring 1,$(LOCAL_DEBUG)),D,)

define define_rules
$(eval LOCAL_DEBUG := $(1))
$(eval LOCAL_DEBUG_SUFFIX := $(if $(findstring 1,$(LOCAL_DEBUG)),D,))

$(eval LIBCBMGFX$(LOCAL_DEBUG_SUFFIX)_SO_VERSION := $(LIBCBMGFX)$(LOCAL_DEBUG_SUFFIX).so.$(VERSION))
$(eval LIBCBMGFX$(LOCAL_DEBUG_SUFFIX)_SO         := $(LIBCBMGFX)$(LOCAL_DEBUG_SUFFIX).so)

ifeq ($(LOCAL_DEBUG),$(DEBUG))
all: $(LIBCBMGFX$(LOCAL_DEBUG_SUFFIX)_SO) $(LIBCBMGFX$(LOCAL_DEBUG_SUFFIX)_SO_VERSION)
else
all: $(LIBCBMGFX_SO) $(LIBCBMGFX_SO_VERSION)
endif

$(LIBCBMGFX$(LOCAL_DEBUG_SUFFIX)_SO_VERSION): $(SRCS)
	$(CC) $(CC_OPTS) -fPIC -shared -o $$@ $$^
ifneq ($(LOCAL_DEBUG),1)
	strip $$@
endif

$(LIBCBMGFX$(LOCAL_DEBUG_SUFFIX)_SO): $(LIBCBMGFX$(LOCAL_DEBUG_SUFFIX)_SO_VERSION)
	ln -nfrs $$< $$@

$(eval DISTCLEAN_NAMES += $(LIBCBMGFX$(LOCAL_DEBUG_SUFFIX)_SO_VERSION) $(LIBCBMGFX$(LOCAL_DEBUG_SUFFIX)_SO))
endef

.PHONY: check clean dist distclean install uninstall

# Define rules in a normal mode:
$(eval $(call define_rules,0))
# Define rules in a debug mode:
$(eval $(call define_rules,1))

$(TEST): $(TEST_CPP)
	$(CC) $(CFLAGS) $(CC_OPTS) -o $@ $< $(CC_LIBS)
	strip $@

check: $(TEST)
	./$<

dist: $(DIST_SPEC)
	cp -v $(word 1,$^) $(RPMBUILD_SPECS)/$(DIST_SPEC)
	mkdir -vp $(DIST)
	cp Makefile cbmgfx.cpp cbmgfx.h *.s $(DIST)
	tar --create --file $(RPMBUILD_SOURCES)/$(DIST_TAR_GZ) --gzip --verbose $(DIST)
	rm -rf $(DIST)
	rpmbuild -ba $(RPMBUILD_SPECS)/$(DIST_SPEC)

$(INSTALL_INC) $(INSTALL_LIB):
	mkdir -vp $@

install: $(INSTALL_INC) $(INSTALL_LIB)
	install -m 0644 cbmgfx.h $(INSTALL_INC)
	install -m 0755 $(LIBCBMGFX$(DEBUG_SUFFIX)_SO_VERSION) $(INSTALL_LIB)
ifeq ($(DESTDIR),)
	ln -nfrs $(INSTALL_LIB)/$(LIBCBMGFX$(DEBUG_SUFFIX)_SO_VERSION) $(INSTALL_LIB)/$(LIBCBMGFX$(DEBUG_SUFFIX)_SO)
else
	install -m 0755 $(LIBCBMGFX$(DEBUG_SUFFIX)_SO) $(INSTALL_LIB)
endif

uninstall:
	$(RM) $(INSTALL_INC)/cbmgfx.h
	$(RM) $(INSTALL_LIB)/$(LIBCBMGFX$(DEBUG_SUFFIX)_SO)
	$(RM) $(INSTALL_LIB)/$(LIBCBMGFX$(DEBUG_SUFFIX)_SO_VERSION)

clean:
	$(RM) desolate.png frighthof83.png
	$(RM) $(TEST)

distclean: clean
	$(RM) $(DISTCLEAN_NAMES)
