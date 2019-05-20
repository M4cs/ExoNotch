ARCHS = arm64 arm64e
TARGET = iphone:11.2:8.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ExoNotch
ExoNotch_FILES = Preferences.m Themes.m ../EXNTheme.m
ExoNotch_INSTALL_PATH = /Library/PreferenceBundles
ExoNotch_FRAMEWORKS = UIKit
ExoNotch_PRIVATE_FRAMEWORKS = Preferences
$(BUNDLE_NAME)_EXTRA_FRAMEWORKS = Cephei CepheiPrefs

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ExoNotch.plist$(ECHO_END)
