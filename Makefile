TARGET := iphone:clang:latest:14.0
ARCHS = arm64
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeadLCD
DeadLCD_FILES = Tweak.x
DeadLCD_CFLAGS = -fobjc-arc
DeadLCD_FRAMEWORKS = UIKit QuartzCore

SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
