// サンプル: DE-9 と DA-15 を横に並べたテスト用パネル
use <../dsub_panel_mount.scad>

// パラメータ (ライブラリと同じ値を設定)
plate_thickness = 8;
plate_margin = 8;

// ブラケット寸法
db9_w = 30.81;   // DE-9 bracket width
db15_w = 39.14;  // DA-15 bracket width
bracket_h = 12.55;
h_spacing = 5;

// パネルサイズ
test_width = db9_w + db15_w + h_spacing + plate_margin * 2;
test_height = bracket_h + plate_margin * 2;

difference() {
    // 板
    translate([-test_width/2, -test_height/2, 0])
        cube([test_width, test_height, plate_thickness]);

    // DE-9
    translate([-(db15_w + h_spacing) / 2, 0, 0])
        de9_cutout();

    // DA-15
    translate([(db9_w + h_spacing) / 2, 0, 0])
        da15_cutout();
}
