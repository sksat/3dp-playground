// Expansion Front 蓋（スライド式）
// 手前側からスライドして差し込む蓋
//
// 外形: 117.4mm x 33.4mm x 3mm
// 使用: expansion_front.scad の溝に差し込む
//
// ビルド (マルチカラー):
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o expansion_front_lid.3mf expansion_front_lid.scad
// ビルド (単色):
//   openscad -o expansion_front_lid.stl expansion_front_lid.scad

include <BOSL2/std.scad>

// ===== パラメータ（expansion_front.scad と同じ値） =====
// 単体で開いた時用のデフォルト値
// include された場合は呼び出し側の値で上書きされる

// ボックスパラメータ
exp_front_width = 120;       // 幅（エンクロージャーと同じ）
exp_front_height = 36;       // 高さ
exp_front_wall = 3;          // 壁厚

// 蓋スロットパラメータ
lid_thickness = 3;           // 蓋の厚さ（PLA強度確保）
lid_slot_depth = 2;          // 溝の深さ（壁への食い込み量）
lid_slot_clearance = 0.3;    // スライド用クリアランス

// ===== タイトル・ラベル =====
lid_title = "Expansion Front v0.1";

// ラベル設定
lid_label_font_size = 5;
lid_label_depth = 1.0;
lid_label_font = "Liberation Sans:style=Bold";

// タイトル位置（蓋上面から見て左上）
lid_title_margin = 5;  // 端からの余白

// ===== 蓋サイズ計算 =====
// 幅: 左右壁の溝に入る分を確保
function lid_calc_width() = exp_front_width - (exp_front_wall - lid_slot_depth) * 2 - lid_slot_clearance * 2;
// 高さ: 上下壁の溝に入る分を確保
function lid_calc_height() = exp_front_height - (exp_front_wall - lid_slot_depth) * 2 - lid_slot_clearance * 2;

// ===== タイトルテキストモジュール =====
// Y+面に配置、正面（Y+方向）から見て読めるように
// rotate([90,0,0]) 後: 押出が -Y 方向（蓋内部へ）になり、
// 見える面は押出の裏側なので mirror([1,0,0]) で補正
module lid_title_text(txt) {
    linear_extrude(height = lid_label_depth)
        mirror([1, 0, 0])
            text(txt, size = lid_label_font_size, font = lid_label_font, halign = "right", valign = "top");
}

module lid_title_cutout_text(txt) {
    linear_extrude(height = lid_label_depth + 0.1)
        mirror([1, 0, 0])
            offset(delta = 0.05)
                text(txt, size = lid_label_font_size, font = lid_label_font, halign = "right", valign = "top");
}

// ===== 蓋（スライド式） =====
module expansion_front_lid() {
    // 蓋サイズの計算
    lid_width = lid_calc_width();
    lid_height = lid_calc_height();

    // タイトル位置（左上、Y+面から見て）
    title_x = -lid_width/2 + lid_title_margin;
    title_z = lid_height/2 - lid_title_margin;

    difference() {
        // 蓋本体（XZ平面、Y方向に厚み）
        cube([lid_width, lid_thickness, lid_height], center=true);

        // タイトル凹み（Y+面から）
        // rotate([90,0,0]) で XY平面のテキストを XZ平面に変換、-Y方向に彫り込み
        translate([title_x, lid_thickness/2 + 0.1, title_z])
            rotate([90, 0, 0])
                lid_title_cutout_text(lid_title);
    }
}

// ===== 蓋ラベル（別マテリアル用） =====
module expansion_front_lid_label() {
    lid_width = lid_calc_width();
    lid_height = lid_calc_height();

    title_x = -lid_width/2 + lid_title_margin;
    title_z = lid_height/2 - lid_title_margin;

    translate([title_x, lid_thickness/2 - lid_label_depth + 0.01, title_z])
        rotate([90, 0, 0])
            lid_title_text(lid_title);
}

// ===== 出力 =====
// show_lid_only が未定義 = 単体で開いている → 出力
if (is_undef(show_lid_only)) {
    color("lightgray") expansion_front_lid();
    color("black") expansion_front_lid_label();
}
