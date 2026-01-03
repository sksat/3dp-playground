// サンプル: 複数D-SUBコネクタを配置したパネル
// DE-9 x3 (上段) + DE-9 + DA-15 (中段) + DE-9 x3 (下段)
use <../dsub_panel_mount.scad>

// パラメータ (ライブラリと同じ値を設定)
plate_thickness = 8;
plate_margin = 8;

// ブラケット寸法
db9_w = 30.81;   // DE-9 bracket width
db15_w = 39.14;  // DA-15 bracket width
bracket_h = 12.55;

// レイアウト設定
h_spacing = 5;   // 横方向の間隔
v_spacing = 5;   // 縦方向の間隔

// パネルサイズ
row_width = db9_w * 3 + h_spacing * 2;  // DE-9 x3
panel_width = row_width + plate_margin * 2;
panel_height = bracket_h * 3 + v_spacing * 2 + plate_margin * 2;

// Y座標
top_y = bracket_h + v_spacing;
mid_y = 0;
bottom_y = -(bracket_h + v_spacing);

difference() {
    // 板
    translate([-panel_width/2, -panel_height/2, 0])
        cube([panel_width, panel_height, plate_thickness]);

    // 上段: DE-9 x3
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, top_y, 0])
            de9_cutout();
    }

    // 中段: DE-9 x1 (左) + DA-15 x1 (右)
    translate([-row_width/2 + db9_w/2, mid_y, 0])
        de9_cutout();
    translate([row_width/2 - db15_w/2, mid_y, 0])
        da15_cutout();

    // 下段: DE-9 x3
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, bottom_y, 0])
            de9_cutout();
    }
}
