APP_NAME = TeamsMacro
APP_DIR = dist/$(APP_NAME).app
CONTENTS = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
PRODUCT = .build/release/$(APP_NAME)
INSTALL_DIR ?= /Applications
INSTALLED_APP = $(INSTALL_DIR)/$(APP_NAME).app

.PHONY: build app install uninstall run open clean

build:
	swift build -c release --product $(APP_NAME)

app: build
	rm -rf "$(APP_DIR)"
	mkdir -p "$(MACOS_DIR)"
	cp "$(PRODUCT)" "$(MACOS_DIR)/$(APP_NAME)"
	cp App/Info.plist "$(CONTENTS)/Info.plist"
	codesign -s - --force --deep "$(APP_DIR)"
	@echo "App créée : $(APP_DIR)"

install: app
	-pkill -x "$(APP_NAME)" 2>/dev/null || true
	rm -rf "$(INSTALLED_APP)"
	cp -R "$(APP_DIR)" "$(INSTALLED_APP)"
	xattr -cr "$(INSTALLED_APP)" 2>/dev/null || true
	@echo "Installé : $(INSTALLED_APP)"
	@echo "Important : autorise UNIQUEMENT $(INSTALLED_APP) dans Accessibilité, puis relance."

uninstall:
	-pkill -x "$(APP_NAME)" 2>/dev/null || true
	rm -rf "$(INSTALLED_APP)"
	rm -rf "$(APP_DIR)"

run: install
	open "$(INSTALLED_APP)"

open: run

clean:
	swift package clean
	rm -rf .build dist
