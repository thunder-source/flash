# Flash Compiler Makefile
# For Windows x64 with NASM

NASM = nasm
LINK = link
NASMFLAGS = -f win64
LINKFLAGS = /subsystem:console /entry:main /out:test_lexer.exe

SRC_DIR = src
BUILD_DIR = build

LEXER_OBJ = $(BUILD_DIR)/lexer.obj
TEST_OBJ = $(BUILD_DIR)/test_lexer.obj

.PHONY: all clean test

all: $(BUILD_DIR) test_lexer.exe

$(BUILD_DIR):
	if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)

$(BUILD_DIR)/lexer.obj: $(SRC_DIR)/lexer.asm
	$(NASM) $(NASMFLAGS) $(SRC_DIR)/lexer.asm -o $(BUILD_DIR)/lexer.obj

$(BUILD_DIR)/test_lexer.obj: $(SRC_DIR)/test_lexer.asm
	$(NASM) $(NASMFLAGS) $(SRC_DIR)/test_lexer.asm -o $(BUILD_DIR)/test_lexer.obj

test_lexer.exe: $(LEXER_OBJ) $(TEST_OBJ)
	$(LINK) $(LINKFLAGS) $(LEXER_OBJ) $(TEST_OBJ) kernel32.lib

test: test_lexer.exe
	test_lexer.exe

clean:
	if exist $(BUILD_DIR) rmdir /s /q $(BUILD_DIR)
	if exist test_lexer.exe del test_lexer.exe
