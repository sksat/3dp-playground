// サンプル: multi_connector_panel を天板にした箱
//
// 出力 (OpenSCAD 2024以降 + lazy-union):
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o enclosure.3mf enclosure_with_panel.scad

use <../dsub_panel_mount.scad>
use <multi_connector_panel.scad>

// 箱のパラメータ
box_width = 120;       // パネルと同じ
box_depth = 110;       // パネルと同じ
box_height = 50;       // 箱の高さ（天板除く）
wall_thickness = 3;    // 壁の厚さ

// パネルパラメータ（multi_connector_panel.scadと同じ）
plate_thickness = 8;

// 前面コネクタ配置
db9_w = 30.81;
bracket_h = 12.55;
front_h_spacing = 5;
front_conn_z = 25;     // コネクタの高さ位置
front_row_width = db9_w * 3 + front_h_spacing * 2;

// ラベル設定
label_font_size = 5;
label_depth = 1.0;
label_font = "Liberation Sans:style=Bold";
front_label_z = front_conn_z + bracket_h/2 + 4;  // コネクタの上

// ===== 前面ラベル用モジュール =====
module front_label_text(txt) {
    linear_extrude(height = label_depth)
        text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

module front_label_cutout_text(txt) {
    linear_extrude(height = label_depth + 0.1)
        offset(delta = 0.05)
            text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

// ===== 箱本体 =====
module box_body() {
    difference() {
        // 外側
        cube([box_width, box_depth, box_height]);

        // 内側をくり抜き
        translate([wall_thickness, wall_thickness, wall_thickness])
            cube([
                box_width - wall_thickness * 2,
                box_depth - wall_thickness * 2,
                box_height  // 上は開放
            ]);

        // 前面 DE-9 x3 (広い側が上、ナットは内側)
        // 変換順序: Z軸反転でナット位置入替 → Z軸回転でD形状反転 → X軸回転で壁向き
        for (i = [0:2]) {
            x = box_width/2 - front_row_width/2 + db9_w/2 + i * (db9_w + front_h_spacing);
            translate([x, -0.1, front_conn_z])
                rotate([-90, 0, 0])
                    translate([0, 0, plate_thickness/2])
                        rotate([0, 180, 0])
                            translate([0, 0, -plate_thickness/2])
                                rotate([0, 0, 180])
                                    de9_cutout();
        }

        // 前面ラベル凹み
        for (i = [0:2]) {
            x = box_width/2 - front_row_width/2 + db9_w/2 + i * (db9_w + front_h_spacing);
            translate([x, label_depth, front_label_z])
                rotate([90, 0, 0])
                    front_label_cutout_text("DE-9");
        }
    }
}

// 前面ラベル本体
module front_labels() {
    for (i = [0:2]) {
        x = box_width/2 - front_row_width/2 + db9_w/2 + i * (db9_w + front_h_spacing);
        translate([x, label_depth, front_label_z])
            rotate([90, 0, 0])
                front_label_text("DE-9");
    }
}

// ===== 組み立て =====
// 箱本体
color("white") box_body();

// 前面ラベル
color("black") front_labels();

// 天板（multi_connector_panel）
translate([box_width/2, box_depth/2, box_height]) {
    color("white") main_panel();
    color("black") labels();
}
