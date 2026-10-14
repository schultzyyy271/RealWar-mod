TARGET := iphone:clang:latest:14.0
ARCHS = arm64
# Process to respawn after `make install`.
INSTALL_TARGET_PROCESSES = RealWar

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RealWarMod

RealWarMod_FILES = Tweak.x GemState.m GemOverlay.m IL2CPPBridge.m
RealWarMod_FRAMEWORKS = UIKit Foundation
RealWarMod_CFLAGS = -fobjc-arc
include $(THEOS_MAKE_PATH)/tweak.mk
