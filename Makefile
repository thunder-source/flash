# Flash Compiler Makefile
# For Windows x64 with NASM

NASM = nasm
LINK = link
NASMFLAGS = -f win64

BIN_DIR = bin
BUILD_DIR = build
BIN_OBJ = $(BUILD_DIR)\flash_bin.obj

.PHONY: all clean build-bin release

# Build the CLI flash.exe binary
all: build-bin

$(BUILD_DIR):
	if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)

build-bin: $(BUILD_DIR) $(BIN_OBJ)
	$(LINK) /subsystem:console /entry:main /out:$(BUILD_DIR)\flash.exe $(BIN_OBJ)
	@echo Built flash.exe

$(BUILD_DIR)\flash_bin.obj: $(BIN_DIR)\flash.asm
	$(NASM) $(NASMFLAGS) $(BIN_DIR)\flash.asm -o $(BUILD_DIR)\flash_bin.obj

clean:
	if exist $(BUILD_DIR) rmdir /s /q $(BUILD_DIR)
	if exist test_lexer.exe del test_lexer.exe
	if exist dist rmdir /s /q dist

# Release packaging
VERSION = 0.1.0
DIST_DIR = dist

.PHONY: release
release: build-bin
	if not exist $(DIST_DIR) mkdir $(DIST_DIR)
	if exist $(DIST_DIR)\flash rmdir /s /q $(DIST_DIR)\flash
	mkdir $(DIST_DIR)\flash\bin
	copy $(BUILD_DIR)\flash.exe $(DIST_DIR)\flash\bin\flash.exe
	if exist include xcopy /E /I /Y include $(DIST_DIR)\flash\include >nul
	if exist lib xcopy /E /I /Y lib $(DIST_DIR)\flash\lib >nul
	if exist share xcopy /E /I /Y share $(DIST_DIR)\flash\share >nul
	powershell -NoProfile -Command "Compress-Archive -Path '$(DIST_DIR)\\flash\\*' -DestinationPath '$(DIST_DIR)\\flash-v$(VERSION)-windows-x64.zip' -Force"
	powershell -NoProfile -Command "Write-Output 'Release created: $(DIST_DIR)\\flash-v$(VERSION)-windows-x64.zip'"

.PHONY: update-manifests
update-manifests: release
	powershell -NoProfile -ExecutionPolicy Bypass -File packaging\update-manifests.ps1 -Version $(VERSION) -ZipPath $(DIST_DIR)\flash-v$(VERSION)-windows-x64.zip
	@echo Manifests updated for version $(VERSION)
