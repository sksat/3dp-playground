# OpenSCAD build rules

OPENSCAD := openscad

# Simple STL
%.stl: %.scad
	$(OPENSCAD) -o $@ $<

# Clean generated files
clean:
	find . -name "*.stl" -delete

.PHONY: clean
