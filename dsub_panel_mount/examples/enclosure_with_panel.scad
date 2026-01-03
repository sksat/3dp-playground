// サンプル: multi_connector_panel を天板にした箱
//
// 出力 (OpenSCAD 2024以降 + lazy-union):
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o enclosure.3mf enclosure_with_panel.scad

use <../dsub_panel_mount.scad>
use <multi_connector_panel.scad>
include <BOSL2/std.scad>
include <NopSCADlib/core.scad>
include <NopSCADlib/vitamins/d_connectors.scad>

// ===== フィットチェック用 =====
show_connectors = true;  // false にすると非表示
show_top_panel = true;   // 天板プレビュー

// ===== タイトル・ラベル（カスタマイズ用） =====
front_title = "D-SUB Enclosure v0.1";

// 前面 DE-9 x3
front_label_1 = "COM9";
front_label_2 = "COM10";
front_label_3 = "COM11";
front_labels = [front_label_1, front_label_2, front_label_3];

// 箱のパラメータ
box_width = 120;       // パネルと同じ
box_depth = 110;       // パネルと同じ
box_height = 50;       // 箱の高さ（天板除く）
wall_thickness = 3;    // 壁の厚さ
corner_r = 3;          // 角のフィレット半径

// パネルパラメータ（multi_connector_panel.scadと同じ）
plate_thickness = 8;

// インサートナット用パラメータ（M3ヒートセットインサート）
// 一般的なM3インサート: 外径4-5mm、長さ5mm
insert_hole_d = 4.2;   // 穴径（インサート外径より少し小さめ）
insert_hole_depth = 6; // 穴深さ（インサート長さ5mm + 余裕1mm）
boss_d = 8;            // ボス（柱）の直径（インサート穴 + 肉厚）
boss_inset = boss_d / 2;  // ボス中心の端からの距離

// PCBマウント用パラメータ（M2.5ネジ + ナット）
pcb_screw_d = 2.7;        // M2.5通し穴（少し余裕）
pcb_screw_len = 8;        // M2.5x8ネジの長さ
pcb_nut_width = 5.0;      // M2.5ナット二面幅
pcb_nut_depth = 2.5;      // ナットの厚さ（2mm + 余裕）
pcb_post_d_top = 6;       // ポスト上部の直径
pcb_post_d_base = 10;     // ポスト底部の直径（円錐形、ナット収容）
pcb_post_h = 10;          // ポストの高さ（基板の浮き）
pcb_hole_x = 88;          // 基板固定穴の横幅
pcb_hole_y = 81;          // 基板固定穴の縦幅

// 前面コネクタ配置
db9_w = 30.81;
bracket_h = 12.55;
front_h_spacing = 5;
front_conn_z = 35;     // コネクタの高さ位置（上寄り）
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

// タイトル用テキスト
module front_title_text(txt) {
    linear_extrude(height = label_depth)
        text(txt, size = label_font_size, font = label_font, halign = "left", valign = "bottom");
}

module front_title_cutout_text(txt) {
    linear_extrude(height = label_depth + 0.1)
        offset(delta = 0.05)
            text(txt, size = label_font_size, font = label_font, halign = "left", valign = "bottom");
}

// タイトル位置（左下）
front_title_x = -front_row_width/2;
front_title_y = -front_conn_z + wall_thickness + 5;  // パネル下端 + 余白

// 前面パネル（板 + コネクタ穴 + ラベル凹み）
// ラベル本体は組み立てセクションで別途追加
module front_panel() {
    front_panel_height = box_height - wall_thickness;  // 底面を除く高さ
    front_panel_width = box_width;

    difference() {
        // 板（コネクタ中心が原点、箱本体の角丸と一体化）
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
                front_label_cutout_text(front_labels[i]);
        }

        // タイトル凹み
        translate([front_title_x, front_title_y, wall_thickness - label_depth])
            front_title_cutout_text(front_title);
    }

}

// ===== 箱本体（シンプル、ボスなし、角丸） =====
module box_body() {
    difference() {
        // 外形（垂直エッジのみ角丸）
        cuboid([box_width, box_depth, box_height],
               rounding=corner_r, edges="Z", anchor=BOTTOM+LEFT+FRONT);

        // 内側をくり抜き（角丸）
        inner_r = max(corner_r - wall_thickness, 0);
        translate([wall_thickness, wall_thickness, wall_thickness])
            cuboid([box_width - wall_thickness * 2,
                    box_depth - wall_thickness * 2,
                    box_height],
                   rounding=inner_r, edges="Z", anchor=BOTTOM+LEFT+FRONT);

        // 前面壁をくり抜き（前面パネルが入る場所）
        translate([0, -0.1, wall_thickness])
            cube([box_width, wall_thickness + 0.2, box_height]);
    }
}

// ===== 組み立て =====
// 四隅のボス位置（天板固定用）
boss_positions = [
    [boss_inset, boss_inset],                           // 左前
    [box_width - boss_inset, boss_inset],               // 右前
    [boss_inset, box_depth - boss_inset],               // 左後
    [box_width - boss_inset, box_depth - boss_inset]    // 右後
];

// PCBマウントポスト位置（底面中央に配置）
// 箱の中心: (box_width/2, box_depth/2) = (60, 55)
// 穴位置: 中心 ± (pcb_hole_x/2, pcb_hole_y/2)
pcb_post_positions = [
    [box_width/2 - pcb_hole_x/2, box_depth/2 - pcb_hole_y/2],  // 左前
    [box_width/2 + pcb_hole_x/2, box_depth/2 - pcb_hole_y/2],  // 右前
    [box_width/2 - pcb_hole_x/2, box_depth/2 + pcb_hole_y/2],  // 左後
    [box_width/2 + pcb_hole_x/2, box_depth/2 + pcb_hole_y/2]   // 右後
];

// 箱本体 + 前面パネル + ボス → インサート穴
color("white") difference() {
    intersection() {
        // 外形で全体をトリミング（角丸を統一）
        cuboid([box_width, box_depth, box_height],
               rounding=corner_r, edges="Z", anchor=BOTTOM+LEFT+FRONT);

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

            // PCBマウントポスト（底面から立ち上がる、円錐形で強度確保）
            for (pos = pcb_post_positions) {
                translate([pos[0], pos[1], wall_thickness])
                    cylinder(h = pcb_post_h, d1 = pcb_post_d_base, d2 = pcb_post_d_top, $fn = 24);
            }
        }
    }

    // インサートナット穴を開ける（天板固定用、上から）
    for (pos = boss_positions) {
        translate([pos[0], pos[1], box_height - insert_hole_depth])
            cylinder(h = insert_hole_depth + 0.1, d = insert_hole_d, $fn = 24);
    }

    // PCBマウント用ネジ穴（貫通）+ ナット凹み（底面から）
    // M2.5x8ネジ: ポスト高さ10mmに対し8mmなので、ナットはポスト底部に埋め込む
    // ナットは底面から挿入し、ポスト底部まで入る
    for (pos = pcb_post_positions) {
        // ネジ穴（ポスト上面から貫通）
        translate([pos[0], pos[1], wall_thickness - 0.1])
            cylinder(h = pcb_post_h + 0.2, d = pcb_screw_d, $fn = 24);
        // 六角ナット凹み（底面から貫通してポスト底部へ）
        translate([pos[0], pos[1], -0.1])
            cylinder(h = wall_thickness + pcb_nut_depth + 0.1, d = pcb_nut_width / cos(30), $fn = 6);
    }
}

// 前面パネルのラベル・タイトル（別色）
translate([box_width/2, wall_thickness, front_conn_z])
    rotate([90, 0, 0])
        color("black") {
            // ラベル
            for (i = [0:2]) {
                x = -front_row_width/2 + db9_w/2 + i * (db9_w + front_h_spacing);
                translate([x, label_offset_y, wall_thickness - label_depth])
                    front_label_text(front_labels[i]);
            }
            // タイトル
            translate([front_title_x, front_title_y, wall_thickness - label_depth])
                front_title_text(front_title);
        }

// ===== 天板プレビュー =====
// 天板は別途印刷してネジ留めする設計
if (show_top_panel) {
    translate([box_width/2, box_depth/2, box_height]) {
        color("white") main_panel();
        color("black") labels();
    }
}

// ===== フィットチェック用コネクタ =====
// 印刷時は show_connectors = false に
if (show_connectors) {
    translate([box_width/2, wall_thickness, front_conn_z])
        rotate([90, 0, 0])
            for (i = [0:2]) {
                x = -front_row_width/2 + db9_w/2 + i * (db9_w + front_h_spacing);
                translate([x, 0, wall_thickness])
                    d_socket(DCONN9);
            }
}

