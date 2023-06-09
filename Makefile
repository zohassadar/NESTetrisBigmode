WINDOWS := $(shell which wine ; echo $$?)
UNAME_S := $(shell uname -s)

tetris_obj := main.o tetris-ram.o tetris.o
tetris_anydas_obj := main_anydas.o tetris-ram_anydas.o tetris_anydas.o
cc65Path := tools/cc65

# Hack for OSX
ifeq ($(UNAME_S),Darwin)
	SHA1SUM := shasum
else
	SHA1SUM := sha1sum
endif

# Programs
ifeq ($(WINDOWS),1)
  WINE :=
else
  WINE := wine
endif

CA65 := $(WINE) $(cc65Path)/bin/ca65
LD65 := $(WINE) $(cc65Path)/bin/ld65

nesChrEncode := python3 tools/nes-util/nes_chr_encode.py
pythonExecutable := python

tetris.nes: tetris.o main.o tetris-ram.o

tetris:= tetris.nes

.SUFFIXES:
.SECONDEXPANSION:
.PRECIOUS:
.SECONDARY:
.PHONY: clean compare tools genie

FLAG_PREFIX := -D
BUILD_FLAGS = $(foreach val,$(subst $(shell echo " "), ,$(strip $(CA65_FLAGS))),$(FLAG_PREFIX) $(val))

CAFLAGS := -g $(BUILD_FLAGS)
LDFLAGS =

compare: $(tetris)
	$(SHA1SUM) -c tetris.sha1

clean:
	rm -f  $(tetris_obj) $(tetris) *.d tetris.dbg tetris.lbl gfx/*.chr gfx/nametables/*.bin
	$(MAKE) clean -C tools/cTools/

tools:
	$(MAKE) -C tools/cTools/

# Build tools when building the rom.
# This has to happen before the rules are processed, since that's when scan_includes is run.
ifeq (,$(filter clean tools/cTools/,$(MAKECMDGOALS)))
$(info $(shell $(MAKE) -C tools/cTools/))
endif

genie: tetris.nes tetris.lbl
	python ggcodes.py > ggcodes.txt

%.o: dep = $(shell tools/cTools/scan_includes $(@D)/$*.asm)
$(tetris_obj): %.o: %.asm $$(dep)
		$(CA65) $(CAFLAGS) $*.asm -o $@
		$(CA65) $(CAFLAGS) -D ANYDAS $*.asm -o $(basename $@)_anydas$(suffix $@)

%: %.cfg
		$(LD65) $(LDFLAGS) -Ln $(basename $@).lbl --dbgfile $(basename $@).dbg -o $@ -C $< $(tetris_obj)
		$(LD65) $(LDFLAGS) -Ln $(basename $@)_anydas.lbl --dbgfile $(basename $@)_anydas.dbg -o $(basename $@)_anydas$(suffix $@) -C $< $(tetris_anydas_obj)

%.bin: %.py
		$(pythonExecutable) $?

%.chr: %.png
		$(nesChrEncode) $< $@




