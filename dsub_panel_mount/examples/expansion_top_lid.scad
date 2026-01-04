// Expansion Top 天板（スライド式）
// 後方からスライドして差し込む天板
//
// 外形: 117.4mm x 108.7mm x 3mm
// 使用: expansion_top.scad の溝に差し込む
//
// ビルド (マルチカラー):
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o expansion_top_lid.3mf expansion_top_lid.scad
// ビルド (単色):
//   openscad -o expansion_top_lid.stl expansion_top_lid.scad

include <BOSL2/std.scad>

// ===== パラメータ（expansion_top.scad と同じ値） =====
// 単体で開いた時用のデフォルト値
// include された場合は呼び出し側の値で上書きされる

// ボックスパラメータ
exp_top_width = 120;        // 幅（天板と同じ）
exp_top_depth = 110;        // 奥行（天板と同じ）
exp_top_wall = 3;           // 壁厚

// 天板スロットパラメータ
lid_thickness = 3;          // 天板の厚さ（PLA強度確保）
lid_slot_depth = 2;         // 溝の深さ（壁への食い込み量）
lid_slot_clearance = 0.3;   // スライド用クリアランス

// ===== タイトル・ラベル =====
lid_title = "Expansion Top v0.1";

// ラベル設定
lid_label_font_size = 5;
lid_label_depth = 1.0;
lid_label_font = "Liberation Sans:style=Bold";

// タイトル位置（天板上面から見て左上）
// 天板サイズを計算して位置決め
function lid_calc_width() = exp_top_width - (exp_top_wall - lid_slot_depth) * 2 - lid_slot_clearance * 2;
function lid_calc_depth() = exp_top_depth - (exp_top_wall - lid_slot_depth) - lid_slot_clearance;
lid_title_margin = 5;  // 端からの余白

// ===== タイトルテキストモジュール =====
module lid_title_text(txt) {
    linear_extrude(height = lid_label_depth)
        text(txt, size = lid_label_font_size, font = lid_label_font, halign = "left", valign = "top");
}

module lid_title_cutout_text(txt) {
    linear_extrude(height = lid_label_depth + 0.1)
        offset(delta = 0.05)
            text(txt, size = lid_label_font_size, font = lid_label_font, halign = "left", valign = "top");
}

// ===== 天板（スライド式） =====
module expansion_top_lid() {
    // 天板サイズの計算
    lid_width = lid_calc_width();
    lid_depth = lid_calc_depth();

    // Y方向のオフセット（背面開口に合わせる）
    y_offset = (exp_top_wall - lid_slot_depth + lid_slot_clearance) / 2;

    // タイトル位置（左上、上面から見て）
    title_x = -lid_width/2 + lid_title_margin;
    title_y = lid_depth/2 - lid_title_margin + y_offset;

    difference() {
        // 背面を開口方向に合わせて配置（Y中心をずらす）
        translate([0, y_offset, 0])
            cube([lid_width, lid_depth, lid_thickness], center=true);

        // タイトル凹み（上面から）
        translate([title_x, title_y, lid_thickness/2 - lid_label_depth])
            lid_title_cutout_text(lid_title);
    }
}

// ===== 天板ラベル（別マテリアル用） =====
module expansion_top_lid_label() {
    lid_width = lid_calc_width();
    lid_depth = lid_calc_depth();
    y_offset = (exp_top_wall - lid_slot_depth + lid_slot_clearance) / 2;

    title_x = -lid_width/2 + lid_title_margin;
    title_y = lid_depth/2 - lid_title_margin + y_offset;

    translate([title_x, title_y, lid_thickness/2 - lid_label_depth])
        lid_title_text(lid_title);
}

// ===== 出力 =====
// show_lid_only が未定義 = 単体で開いている → 出力
if (is_undef(show_lid_only)) {
    color("lightgray") expansion_top_lid();
    color("black") expansion_top_lid_label();
}
