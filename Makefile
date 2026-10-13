TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
# Process to respawn after `make install` -- set to YOUR app's executable name
INSTALL_TARGET_PROCESSES = GemDebugDemo

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GemDebugDemo

GemDebugDemo_FILES = Tweak.x GemState.m GemOverlay.m
GemDebugDemo_FRAMEWORKS = UIKit Foundation
GemDebugDemo_CFLAGS = -fobjc-arc

# Mirrors the original #if DEBUG: the debug button is compiled out of
# release builds (make package FINALPACKAGE=1).
ifneq ($(FINALPACKAGE),1)
GemDebugDemo_CFLAGS += -DGEM_DEBUG_UI=1
endif

include $(THEOS_MAKE_PATH)/tweak.mk
