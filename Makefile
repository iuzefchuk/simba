APP        := Simba
PROJECT    := $(APP).xcodeproj
SCHEME     := $(APP)
BUILD      := build
DERIVED    := $(BUILD)/DerivedData
DEBUG_APP  := $(DERIVED)/Build/Products/Debug/$(APP).app
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) -quiet

.PHONY: all build test release run run-fast stop install icons masters layers clean open help

all: build

build: ## Debug build
	$(XCODEBUILD) -configuration Debug build

test: ## Run the unit tests
	$(XCODEBUILD) -configuration Debug test

release: ## Release build into build/Simba.app
	$(XCODEBUILD) -configuration Release CONFIGURATION_BUILD_DIR=$(abspath $(BUILD)) build
	@echo "built $(BUILD)/$(APP).app"

run: build ## Launch the debug build
	open "$(DEBUG_APP)"

run-fast: build ## Launch the debug build with a prompt every 30 seconds
	open "$(DEBUG_APP)" --args -promptInterval 30

stop: ## Quit a running Simba
	-pkill -x $(APP)

install: release stop ## Copy the release build into /Applications and launch it
	rm -rf "/Applications/$(APP).app"
	cp -R "$(BUILD)/$(APP).app" /Applications/
	open "/Applications/$(APP).app"

icons: ## Compose the app icon, mark and menu bar images from tools/artwork/masters (ICON_BG=white|olive|khaki|light)
	./tools/artwork/build.sh

masters: ## Rebuild the masters in tools/artwork from the photos in tools/artwork/sources, then the icons
	./tools/artwork/build.sh --masters

layers: ## Check src/ against the layout: folders, names, imports, and the dependency rules
	./tools/check-layers.sh

clean: ## Remove build products
	rm -rf $(BUILD)

open: ## Open the project in Xcode
	open $(PROJECT)

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{ printf "  %-12s %s\n", $$1, $$2 }'
