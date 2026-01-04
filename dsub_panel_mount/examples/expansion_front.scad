// D-SUB 拡張フロント
// 既存エンクロージャーの前面パネル（メスコネクタ）に接続する拡張ボックス
// オスコネクタで前面パネルに嵌合し、D-SUBのネジで固定
//
// 外形: 120mm x 80mm x 36mm（幅 x 奥行き x 高さ）
// 構造: 背面パネルにポケット構造（メスコネクタ突出部を収容）
//   - 背面からポケット（メスコネクタ本体が入る）
//   - ポケット奥からパネル構造（コネクタ取付）
//   - ブラケット凹みはポケット奥側（背面）
//   - ナットポケットはパネル内側（内部）
// 使用コネクタ: DE-9 x3（オス）
// 固定: D-SUBコネクタのネジ（M3）のみ
// 蓋: 手前側からスライド
// 印刷: コネクタ面（背面）を下に造形
// 依存: dsub_panel_mount.scad, BOSL2, NopSCADlib
//
// ビルド:
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o expansion_front.3mf expansion_front.scad

include <../dsub_panel_mount.scad>
include <BOSL2/std.scad>
include <NopSCADlib/core.scad>
include <NopSCADlib/vitamins/d_connectors.scad>

// 蓋を include（show_lid_only が定義済みなら出力抑制）
show_lid_only = true;
include <expansion_front_lid.scad>

/* [Preview] */
// Show male plugs for fit checking
show_plugs = true;
// Show lid preview
show_lid = true;

// ===== タイトル・ラベル（カスタマイズ用） =====
panel_title = "Expansion Front v0.1";

// DE-9 x3
front_label_1 = "EXT9";
front_label_2 = "EXT10";
front_label_3 = "EXT11";
front_labels = [front_label_1, front_label_2, front_label_3];

// ===== ラベル設定 =====
label_font_size = 5;
label_depth = 1.0;
label_font = "Liberation Sans:style=Bold";

// ===== ボックスパラメータ =====
exp_front_width = 120;       // 幅（エンクロージャーと同じ）
exp_front_depth = 80;        // 奥行き
exp_front_height = 36;       // 高さ
exp_front_wall = 3;          // 壁厚
exp_front_corner_r = 3;      // 角丸半径

// 蓋スロットパラメータ（手前側からスライドして差し込む）
lid_thickness = 3;           // 蓋の厚さ（PLA強度確保）
lid_slot_depth = 2;          // 溝の深さ（壁への食い込み量）
lid_slot_clearance = 0.3;    // スライド用クリアランス
lid_slot_front_offset = 2;   // 前壁端から溝端までの距離

// 背面パネルパラメータ
exp_front_plate = 8;         // パネル構造厚

// ポケット深さの計算
// 前面パネルのメスコネクタ突出量 = d_front_height - flange_recess_depth
// DCONN9: d_front_height = 6.693mm, flange_recess_depth = 1.5mm
// 突出量 ≈ 6.693 - 1.5 = 5.2mm
// 余裕を加えて 6mm
exp_front_pocket = 6;        // ポケット深さ（メスコネクタ突出量 + 余裕）

// ===== コネクタ配置 =====
tolerance = 0.3;             // 3Dプリント公差
db9_w = 30.81;               // DE-9 ブラケット幅
bracket_h = 12.55;           // ブラケット高さ
h_spacing = 5;               // 横方向間隔
label_height = 6;            // ラベル用スペース

// レイアウト計算
row_width = db9_w * 3 + h_spacing * 2;  // DE-9 x3 の幅

// コネクタ中心のZ位置（ボックス高さの中央）
conn_z = exp_front_height / 2;

// ラベル位置（コネクタ上部）
// ブラケット上端 + フォント半分 + マージン
label_offset_z = bracket_h / 2 + label_font_size / 2 + 2;

// タイトル位置（左上、ボックス左端から余白5mm）
title_x = -exp_front_width / 2 + 5;
title_z = conn_z + label_offset_z + label_font_size + 3;

// ===== 背面パネル構造パラメータ =====
// 構造（Y=0 から Y+ 方向へ）:
//   Y=0: 背面（エンクロージャー前面に接触）
//   Y=0〜6: ポケット（メスコネクタ突出部が入る）
//   Y=0〜1.5: ブラケット凹み（ポケット背面から、ブラケットが座る）
//   Y=6〜14: パネル構造（D穴貫通）
//   Y=11.5〜14: ナットポケット（パネル内側から）
//   Y=14〜80: 側壁（内部空間）

// dsub_panel_mount.scad と同じ値
flange_recess_depth = 1.5;   // ブラケット凹み深さ
flange_corner_r = 0.5;       // ブラケット角R
m3_nut_width = 5.5;          // M3ナット二面幅
m3_nut_depth = 2.5;          // ナット厚

// 背面パネルの合計厚さ
exp_front_back_total = exp_front_plate + exp_front_pocket;

// ===== オスコネクタ用カットアウト（背面パネル用、Y方向に掘る） =====
// dsub_panel_mount ライブラリのモジュールを Y 方向パネル用に変換して使用
// base_y: ポケット深さ（メスコネクタ突出部を収容）
module exp_front_dsub_cutout(conn, base_y = 0) {
    // ライブラリから寸法取得
    bracket = db_bracket_table(conn);
    bracket_w = bracket[0];
    bracket_h = bracket[1];
    total_depth = base_y + exp_front_plate;  // ポケット + パネル構造

    // ブラケット形状のポケット（背面からポケット奥まで）
    // メスコネクタの突出部が入るスペース
    // rotate([-90,0,0]): Z+ → +Y（パネル内部へ）
    translate([0, -0.1, 0])
        rotate([-90, 0, 0])
            dsub_flange_recess(bracket_w + tolerance, bracket_h + tolerance,
                              flange_corner_r, base_y + 0.1);

    // ブラケット凹み（背面から、ブラケットが座る）
    translate([0, -0.1, 0])
        rotate([-90, 0, 0])
            dsub_flange_recess(bracket_w + tolerance, bracket_h + tolerance,
                              flange_corner_r, flange_recess_depth + 0.1);

    // D穴 + M3取付穴（背面から内部まで全体を貫通）
    // dsub_opening は D形状穴と取付穴を含む
    // rotate([0,0,180]): D形状を180°回転（広い側を下に）
    translate([0, -0.1, 0])
        rotate([-90, 0, 0])
            rotate([0, 0, 180])
                dsub_opening(conn, tolerance, total_depth + 0.2, taper = false);

    // ナットポケット（パネル内側から掘る）
    // Y=total_depth の位置から -Y 方向に掘る
    // rotate([90,0,0]): Z+ → -Y（パネル内部へ戻る）
    // D形状を180°回転したので、ナット位置も入れ替え
    // ただし回転角度は同じ（左=-20°, 右=+20°）
    conn_dimensions = db_opening_table(conn);
    if (conn_dimensions != "Error") {
        b = conn_dimensions[0];  // 取付穴中心距離/2
        cut_angle = 10;
        nut_rotation = 90 - cut_angle - 60;  // = 20°
        // D形状180°回転後: 左穴は元の右穴位置、右穴は元の左穴位置
        // 左ナット: D左辺(100°)に合わせて -20°
        translate([-b, total_depth + 0.1, 0])
            rotate([90, 0, 0])
                hex_nut_recess(m3_nut_width + tolerance, m3_nut_depth + 0.1, -nut_rotation);
        // 右ナット: D右辺(80°)に合わせて +20°
        translate([b, total_depth + 0.1, 0])
            rotate([90, 0, 0])
                hex_nut_recess(m3_nut_width + tolerance, m3_nut_depth + 0.1, nut_rotation);
    }
}

// ===== コネクタラベル（背面パネル、コネクタ面） =====
// コネクタ側から見た時（-Y方向から）に読めるように配置
module exp_front_conn_label_text(txt) {
    linear_extrude(height = label_depth)
        text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

module exp_front_conn_label_cutout_text(txt) {
    translate([0, 0, -0.1])
        linear_extrude(height = label_depth + 0.1)
            offset(delta = 0.05)
                text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

// ===== 天面タイトル（ボックス上面） =====
// 上から見た時（+Z方向から）に読めるように配置
// コネクタ側（Y-）を上にして読む向き（設置時の自然な見方）
module exp_front_top_title_text(txt) {
    linear_extrude(height = label_depth)
        rotate([0, 0, 180])
            text(txt, size = label_font_size, font = label_font, halign = "left", valign = "bottom");
}

module exp_front_top_title_cutout_text(txt) {
    translate([0, 0, -0.1])
        linear_extrude(height = label_depth + 0.1)
            rotate([0, 0, 180])
                offset(delta = 0.05)
                    text(txt, size = label_font_size, font = label_font, halign = "left", valign = "bottom");
}

// ===== コネクタラベル凹み（背面パネルから引く） =====
module exp_front_conn_label_cutouts() {
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        // 背面（Y=0）から -Y 方向に彫り込む
        translate([x, label_depth + 0.1, conn_z + label_offset_z])
            rotate([90, 0, 0])
                exp_front_conn_label_cutout_text(front_labels[i]);
    }
}

// ===== コネクタラベル本体（背面パネル） =====
module exp_front_conn_labels() {
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        // 背面（Y=0）の表面に配置
        translate([x, label_depth - 0.01, conn_z + label_offset_z])
            rotate([90, 0, 0])
                exp_front_conn_label_text(front_labels[i]);
    }
}

// ===== 天面タイトル凹み（上面から引く） =====
module exp_front_top_title_cutout() {
    // 天面左上（コネクタ側寄り）に配置
    // rotate([0,0,180]) 後、テキストは左に伸びる
    // 右端に十分な余白を確保
    top_title_x = exp_front_width/2 - 10;
    top_title_y = exp_front_back_total + 5;  // 背面パネル構造の奥から
    translate([top_title_x, top_title_y, exp_front_height - label_depth])
        exp_front_top_title_cutout_text(panel_title);
}

// ===== 天面タイトル本体（上面） =====
module exp_front_top_title() {
    top_title_x = exp_front_width/2 - 10;
    top_title_y = exp_front_back_total + 5;
    translate([top_title_x, top_title_y, exp_front_height - label_depth + 0.01])
        exp_front_top_title_text(panel_title);
}

// ===== 拡張フロント本体 =====
// 一体構造: 外殻シェル + 背面パネル構造
module expansion_front() {
    wall_depth = exp_front_depth - exp_front_back_total;
    slot_y_local = wall_depth - lid_slot_front_offset - lid_thickness;
    slot_width = lid_thickness + lid_slot_clearance;

    difference() {
        intersection() {
            // 外形で全体をトリミング（統一した角丸）
            translate([0, exp_front_depth/2, exp_front_height/2])
                cuboid([exp_front_width, exp_front_depth, exp_front_height],
                       rounding=exp_front_corner_r, edges="Z");

            union() {
                // 外殻（全体）
                translate([0, exp_front_depth/2, exp_front_height/2])
                    cube([exp_front_width, exp_front_depth, exp_front_height], center=true);
            }
        }

        // 内部空洞（背面パネル上面から前面まで）
        // 背面パネル構造（厚さ14mm）の内側から始まる
        translate([0, exp_front_back_total + (exp_front_depth - exp_front_back_total)/2, exp_front_height/2])
            cube([exp_front_width - exp_front_wall * 2,
                  exp_front_depth - exp_front_back_total + 0.1,
                  exp_front_height - exp_front_wall * 2], center=true);

        // コネクタカットアウト（DE-9 x3）
        for (i = [0:2]) {
            x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
            translate([x, 0, conn_z])
                exp_front_dsub_cutout("db9", base_y = exp_front_pocket);
        }

        // コネクタラベル凹み（背面から）
        exp_front_conn_label_cutouts();

        // 蓋スロット（左右・上下の4辺）
        // 左右の溝
        for (side = [-1, 1]) {
            translate([side * (exp_front_width/2 - exp_front_wall + lid_slot_depth/2),
                       exp_front_back_total + slot_y_local - slot_width/2,
                       exp_front_height/2])
                cube([lid_slot_depth + 0.1,
                      slot_width,
                      exp_front_height - exp_front_wall * 2 + lid_slot_depth * 2], center=true);
        }

        // 上の溝
        translate([0,
                   exp_front_back_total + slot_y_local - slot_width/2,
                   exp_front_height - exp_front_wall + lid_slot_depth/2])
            cube([exp_front_width - exp_front_wall * 2 + lid_slot_depth * 2,
                  slot_width,
                  lid_slot_depth + 0.1], center=true);

        // 下の溝
        translate([0,
                   exp_front_back_total + slot_y_local - slot_width/2,
                   exp_front_wall - lid_slot_depth/2])
            cube([exp_front_width - exp_front_wall * 2 + lid_slot_depth * 2,
                  slot_width,
                  lid_slot_depth + 0.1], center=true);

        // 前面開口（蓋スライド入口）
        translate([0, exp_front_depth - exp_front_wall/2, exp_front_height/2])
            cube([exp_front_width - exp_front_wall * 2 + lid_slot_depth * 2,
                  exp_front_wall + 0.2,
                  exp_front_height - exp_front_wall * 2 + lid_slot_depth * 2], center=true);

        // 天面タイトル凹み（上面から彫り込む）
        exp_front_top_title_cutout();
    }
}

// ===== フィットチェック用オスプラグ =====
module expansion_front_plugs() {
    // オスプラグはブラケット座面（ポケット背面 + ブラケット凹み）に配置
    // d_plug() は Z=0 がフランジ面、Z+ 方向にピンが突出
    // rotate([90,0,0]) で Y- 方向（ポケット内）にピンが突出
    // D形状は標準向き（広い側が下）
    plug_y = flange_recess_depth;

    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, plug_y, conn_z])
            rotate([90, 0, 0])
                d_plug(DCONN9);
    }
}

// ===== 出力 =====
// show_expansion_front が未定義 = 単体で開いている → 出力
if (is_undef(show_expansion_front)) {
    color("white") expansion_front();
    color("black") {
        exp_front_conn_labels();  // コネクタラベル（背面）
        exp_front_top_title();    // タイトル（天面）
    }

    if (show_plugs) {
        expansion_front_plugs();
    }

    if (show_lid) {
        // 蓋を装着位置にプレビュー
        wall_depth = exp_front_depth - exp_front_back_total;
        lid_y = exp_front_back_total + wall_depth - lid_slot_front_offset - lid_thickness/2;
        translate([0, lid_y, exp_front_height/2]) {
            color("lightgray") expansion_front_lid();
            color("black") expansion_front_lid_label();
        }
    }
}
