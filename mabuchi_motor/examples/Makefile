OPENSCAD := openscad

%.stl: %.scad
	$(OPENSCAD) -o $@ $<

%.3mf: %.scad
	$(OPENSCAD) --enable=lazy-union -O export-3mf/material-type=color -o $@ $<

all: fa130_fan_demo.3mf fa130_mount_demo.stl

clean:
	rm -f *.stl *.3mf

.PHONY: all clean
