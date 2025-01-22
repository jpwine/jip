# Makefile for a Go command-line tool project

# Variables
CMD_NAME := jip
SRC_DIR := ./cmd/$(CMD_NAME)
SRCS := $(shell find . -type f -name '*.go' -and -not -name '*_test.go')
BUILD_DIR := ./bin
OUTPUT := $(BUILD_DIR)/$(CMD_NAME)
OUTPUT_OS_SUFFIX := 
OUTPUT_ARCH_SUFFIX := 
PKG_LIST := $(shell go list ./...)

# Set SUFFIX if specified
ifdef GOOS
    OUTPUT_OS_SUFFIX := _$(GOOS)
endif
ifdef GOARCH
    OUTPUT_ARCH_SUFFIX := _$(GOARCH)
endif

# Target OS (default to current OS if not specified)
GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)

# Add .exe extension for Windows
ifeq ($(GOOS), windows)
    OUTPUT := $(BUILD_DIR)/$(CMD_NAME)$(OUTPUT_OS_SUFFIX)$(OUTPUT_ARCH_SUFFIX).exe
else
    OUTPUT := $(BUILD_DIR)/$(CMD_NAME)$(OUTPUT_OS_SUFFIX)$(OUTPUT_ARCH_SUFFIX)
endif

# Default target
.PHONY: all
all: build

# Build the binary
.PHONY: build
build: $(OUTPUT)

$(OUTPUT): $(SRCS)
	GOOS=$(GOOS) GOARCH=$(GOARCH) go build -ldflags="-s -w" -trimpath -o $(OUTPUT) $(SRC_DIR)

# Run code
.PHONY: run
run:
	go run $(SRCS)

# Run tests
.PHONY: test
test:
	./test.sh
#	go test -v ./...


# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

# Format code
.PHONY: fmt
fmt:
	go fmt ./...

# Check for outdated dependencies
.PHONY: deps
deps:
	go list -u -m all

# Update dependencies
.PHONY: deps-update
deps-update:
	go get -u ./...

# Install the binary globally
.PHONY: install
install: build
	cp $(OUTPUT) /usr/local/bin/$(CMD_NAME)

# Show help
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make all         - Build the project"
	@echo "  make build       - Build the binary"
	@echo "  make run         - Run code"
	@echo "  make test        - Run tests"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make fmt         - Format the code"
	@echo "  make deps        - Check for outdated dependencies"
	@echo "  make deps-update - Update dependencies"
	@echo "  make install     - Install the binary globally"
	@echo "  make help        - Show this help message"
