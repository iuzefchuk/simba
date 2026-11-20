APP        := Simba
PROJECT    := $(APP).xcodeproj
SCHEME     := $(APP)
BUILD      := build
DERIVED    := $(BUILD)/DerivedData
DEBUG_APP  := $(DERIVED)/Build/Products/Debug/$(APP).app
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) -quiet

.PHONY: all project build release run run-fast stop install clean open help

all: build

project: ## Generate Simba.xcodeproj from project.yml (needs xcodegen)
	xcodegen generate --quiet --use-cache --cache-path $(BUILD)/xcodegen-cache

build: project ## Debug build
	$(XCODEBUILD) -configuration Debug build

release: project ## Release build into build/Simba.app
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

clean: ## Remove build products and the generated project
	rm -rf $(BUILD) $(PROJECT)

open: project ## Open the project in Xcode
	open $(PROJECT)

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{ printf "  %-12s %s\n", $$1, $$2 }'
