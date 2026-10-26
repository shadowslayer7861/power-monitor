ifeq ($(OS),Windows_NT)
CC := /mingw64/bin/gcc.exe
else
CC := gcc
endif
CFLAGS ?= -std=c11 -Wall -Wextra -I src
BUILD_DIR := build
EXE_EXT :=
ifeq ($(OS),Windows_NT)
EXE_EXT := .exe
endif

TARGET := $(BUILD_DIR)/main$(EXE_EXT)
TEST_TARGET := $(BUILD_DIR)/test_ina219$(EXE_EXT)

.PHONY: all test run clean

all: $(TARGET)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(TARGET): $(BUILD_DIR) src/main.c src/ina219.c src/sim_i2c.c src/sim_load.c src/sim_pwm.c src/sim_uart.c src/vcd_writer.c
	$(CC) $(CFLAGS) -o $@ src/main.c src/ina219.c src/sim_i2c.c src/sim_load.c src/sim_pwm.c src/sim_uart.c src/vcd_writer.c

test: $(TEST_TARGET)

$(TEST_TARGET): $(BUILD_DIR) tests/test_ina219.c src/ina219.c src/sim_i2c.c
	$(CC) $(CFLAGS) -o $@ tests/test_ina219.c src/ina219.c src/sim_i2c.c

run: $(TARGET)
	./$(TARGET)

clean:
	rm -rf $(BUILD_DIR)
