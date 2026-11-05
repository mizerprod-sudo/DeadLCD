TARGET := iphone:clang:latest:14.0
ARCHS = arm64
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DeadLCDPrefs
DeadLCDPrefs_FILES = DLRootListController.m
DeadLCDPrefs_FRAMEWORKS = UIKit
DeadLCDPrefs_LDFLAGS = -undefined dynamic_lookup
DeadLCDPrefs_INSTALL_PATH = /Library/PreferenceBundles
DeadLCDPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
