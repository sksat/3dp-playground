# Gridfinity Examples Makefile

OPENSCAD = openscad

# パターンルール
%.stl: %.scad
	$(OPENSCAD) -o $@ $<

%.3mf: %.scad
	$(OPENSCAD) -o $@ $<

# デフォルトターゲット
all: baseplate_2x2.stl bin_1x1x3.stl

# ベースプレート
baseplate_2x2.stl: baseplate_demo.scad ../gridfinity.scad
	$(OPENSCAD) -o $@ -D 'units_x=2' -D 'units_y=2' $<

baseplate_3x3.stl: baseplate_demo.scad ../gridfinity.scad
	$(OPENSCAD) -o $@ -D 'units_x=3' -D 'units_y=3' $<

baseplate_4x4.stl: baseplate_demo.scad ../gridfinity.scad
	$(OPENSCAD) -o $@ -D 'units_x=4' -D 'units_y=4' $<

# ビン
bin_1x1x3.stl: bin_demo.scad ../gridfinity.scad
	$(OPENSCAD) -o $@ -D 'units_x=1' -D 'units_y=1' -D 'units_z=3' $<

bin_2x1x3.stl: bin_demo.scad ../gridfinity.scad
	$(OPENSCAD) -o $@ -D 'units_x=2' -D 'units_y=1' -D 'units_z=3' $<

bin_2x2x3.stl: bin_demo.scad ../gridfinity.scad
	$(OPENSCAD) -o $@ -D 'units_x=2' -D 'units_y=2' -D 'units_z=3' $<

# クリーン
clean:
	rm -f *.stl *.3mf

.PHONY: all clean
