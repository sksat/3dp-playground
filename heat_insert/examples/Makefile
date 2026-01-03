# OpenSCAD build rules

OPENSCAD := openscad

# Multi-color 3MF (OpenSCAD 2024+)
%.3mf: %.scad
	$(OPENSCAD) --enable=lazy-union -O export-3mf/material-type=color -o $@ $<

# Simple STL
%.stl: %.scad
	$(OPENSCAD) -o $@ $<

# Clean generated files
clean:
	find . -name "*.stl" -delete
	find . -name "*.3mf" -delete

.PHONY: clean
