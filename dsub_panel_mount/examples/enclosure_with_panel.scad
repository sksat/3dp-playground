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

// インサートナット用パラメータ（M3ヒートセットインサート）
// 一般的なM3インサート: 外径4-5mm、長さ5mm
insert_hole_d = 4.2;   // 穴径（インサート外径より少し小さめ）
insert_hole_depth = 6; // 穴深さ（インサート長さ5mm + 余裕1mm）
boss_d = 8;            // ボス（柱）の直径（インサート穴 + 肉厚）
boss_inset = boss_d / 2;  // ボス中心の端からの距離

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
label_offset_y = bracket_h/2 + 4;  // コネクタ中心からラベルまでの距離

// ===== 前面パネル（独立した板として設計） =====
// 水平状態で設計し、回転して配置
// コネクタ中心を原点として設計

// ラベル用テキスト
module front_label_text(txt) {
    linear_extrude(height = label_depth)
        text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

module front_label_cutout_text(txt) {
    linear_extrude(height = label_depth + 0.1)
        offset(delta = 0.05)
            text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

// 前面パネル（板 + コネクタ穴 + ラベル凹み）
// ラベル本体は組み立てセクションで別途追加
module front_panel() {
    front_panel_height = box_height - wall_thickness;  // 底面を除く高さ
    front_panel_width = box_width;

    difference() {
        // 板（コネクタ中心が原点）
        translate([-front_panel_width/2, -front_conn_z + wall_thickness, 0])
            cube([front_panel_width, front_panel_height, wall_thickness]);

        // コネクタカットアウト
        for (i = [0:2]) {
            x = -front_row_width/2 + db9_w/2 + i * (db9_w + front_h_spacing);
            translate([x, 0, 0])
                de9_cutout();
        }

        // ラベル凹み
        for (i = [0:2]) {
            x = -front_row_width/2 + db9_w/2 + i * (db9_w + front_h_spacing);
            translate([x, label_offset_y, wall_thickness - label_depth])
                front_label_cutout_text("DE-9");
        }
    }
}

// ===== 箱本体（シンプル、ボスなし） =====
module box_body() {
    difference() {
        cube([box_width, box_depth, box_height]);

        // 内側をくり抜き
        translate([wall_thickness, wall_thickness, wall_thickness])
            cube([
                box_width - wall_thickness * 2,
                box_depth - wall_thickness * 2,
                box_height
            ]);

        // 前面壁をくり抜き（前面パネルが入る場所）
        translate([0, -0.1, wall_thickness])
            cube([box_width, wall_thickness + 0.2, box_height]);
    }
}

// ===== 組み立て =====
// 四隅のボス位置
boss_positions = [
    [boss_inset, boss_inset],                           // 左前
    [box_width - boss_inset, boss_inset],               // 右前
    [boss_inset, box_depth - boss_inset],               // 左後
    [box_width - boss_inset, box_depth - boss_inset]    // 右後
];

// 箱本体 + 前面パネル + ボス → インサート穴
color("white") difference() {
    union() {
        // 箱本体
        box_body();

        // 前面パネル（回転して配置）
        translate([box_width/2, wall_thickness, front_conn_z])
            rotate([90, 0, 0])
                front_panel();

        // 四隅にボス（柱）を追加
        for (pos = boss_positions) {
            translate([pos[0], pos[1], wall_thickness])
                cylinder(h = box_height - wall_thickness, d = boss_d, $fn = 24);
        }
    }

    // インサートナット穴を開ける
    for (pos = boss_positions) {
        translate([pos[0], pos[1], box_height - insert_hole_depth])
            cylinder(h = insert_hole_depth + 0.1, d = insert_hole_d, $fn = 24);
    }
}

// 前面パネルのラベル（別色）
translate([box_width/2, wall_thickness, front_conn_z])
    rotate([90, 0, 0])
        color("black") for (i = [0:2]) {
            x = -front_row_width/2 + db9_w/2 + i * (db9_w + front_h_spacing);
            translate([x, label_offset_y, wall_thickness - label_depth])
                front_label_text("DE-9");
        }

// 天板（multi_connector_panel）- プレビュー用、印刷時は別ファイルで
// 天板は別途印刷してネジ留めする設計
// translate([box_width/2, box_depth/2, box_height]) {
//     color("white") main_panel();
//     color("black") labels();
// }
