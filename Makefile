LTO ?= 1
DEBUG ?= 0

rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

CXX ?= clang++

SRCS := $(call rwildcard, src/, *cpp)
OBJS := $(filter %.o,$(SRCS:.cpp=.o))
DEPS := $(filter %.d,$(SRCS:.cpp=.d))

# for identifying architecture and OS when compiling
# see https://stackoverflow.com/a/12099167/3007166 for original post
ifeq ($(OS),Windows_NT)
    CCFLAGS += -D WIN32
    ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
        CCFLAGS += -D AMD64
    else
        ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
            CCFLAGS += -D AMD64
        endif
        ifeq ($(PROCESSOR_ARCHITECTURE),x86)
            CCFLAGS += -D IA32
        endif
    endif
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        CCFLAGS += -D LINUX
    endif
    ifeq ($(UNAME_S),Darwin)
        CCFLAGS += -D OSX
    endif
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P),x86_64)
        CCFLAGS += -D AMD64
    endif
    ifneq ($(filter %86,$(UNAME_P)),)
        CCFLAGS += -D IA32
    endif
    ifneq ($(filter arm%,$(UNAME_P)),)
        CCFLAGS += -D ARM
    endif
endif

# agnostic compilation flags
CXXFLAGS := -std=c++17
CXXFLAGS += -Iinc
CXXFLAGS += `sdl2-config --cflags`

ifeq ($(LTO),1)
	CXXFLAGS += -flto
endif

ifeq ($(DEBUG),1)
	CXXFLAGS += -DRX_DEBUG
	CXXFLAGS += -O0
	CXXFLAGS += -g
else
	# enable assertions for release builds temporarily
	CXXFLAGS += -DRX_DEBUG
	CXXFLAGS += -O3

	# disable things we don't want in release
	CXXFLAGS += -fno-exceptions
	CXXFLAGS += -fno-rtti
	CXXFLAGS += -fno-stack-protector
	CXXFLAGS += -fno-asynchronous-unwind-tables
	CXXFLAGS += -fno-stack-check

	ifeq ($(CXX),g++)
		CXXFLAGS += -fno-stack-clash-protection
	endif
endif

# linker flags
LDFLAGS := -lpthread
LDFLAGS += `sdl2-config --libs`
ifeq ($(LTO),1)
	LDFLAGS += -flto
endif

BIN := rex

all: $(BIN)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BIN): $(OBJS)
	$(CXX) $(OBJS) $(LDFLAGS) -o $@

clean:
	rm -rf $(OBJS) $(DEPS) $(BIN)

.PHONY: clean

-include $(DEPS)
