APP      := Simba
DERIVED  := build/DerivedData
GENERATE := xcodegen generate --quiet --use-cache --cache-path build/xcodegen-cache
BUILD    := xcodebuild -project $(APP).xcodeproj -scheme $(APP) -derivedDataPath $(DERIVED) -quiet build

.PHONY: dev package

dev:
	$(GENERATE)
	$(BUILD) -configuration Debug -destination 'platform=macOS,arch=$(shell uname -m)'
	pkill -x $(APP); while pgrep -x $(APP) >/dev/null; do sleep 0.1; done
	open $(DERIVED)/Build/Products/Debug/$(APP).app

package:
	$(GENERATE)
	$(BUILD) -configuration Release -destination 'generic/platform=macOS'
	rm -rf build/dmg build/$(APP).dmg
	mkdir build/dmg
	cp -R $(DERIVED)/Build/Products/Release/$(APP).app build/dmg/
	ln -s /Applications build/dmg/Applications
	hdiutil create -volname $(APP) -srcfolder build/dmg -format UDZO -quiet build/$(APP).dmg
	rm -rf build/dmg
