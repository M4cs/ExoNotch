ARCHS = arm64 arm64e
TARGET = iphone:11.2:8.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ExoNotch
ExoNotch_FILES = Tweak.xm EXNTheme.m
ExoNotch_FRAMEWORKS += UIKit QuartzCore WebKit
ExoNotch_LIBRARIES = exo
ExoNotch_EXTRA_FRAMEWORKS = Cephei

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += exonotch
include $(THEOS_MAKE_PATH)/aggregate.mk
