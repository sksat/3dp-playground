// サンプル: 複数D-SUBコネクタを配置したパネル（ラベル付き）
// DE-9 x3 (上段) + DE-9 + DA-15 (中段) + DE-9 x3 (下段)
// マルチカラー印刷対応: 板と文字が別オブジェクト
//
// 出力 (OpenSCAD 2024以降 + lazy-union):
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o output.3mf multi_connector_panel.scad

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

// ラベル設定
label_height = 6;      // ラベル用スペースの高さ
label_font_size = 5;   // フォントサイズ
label_depth = 1.0;     // 文字の埋め込み深さ
label_font = "Liberation Sans:style=Bold";

// パネルサイズ（ラベル用スペースを追加）
row_width = db9_w * 3 + h_spacing * 2;  // DE-9 x3
panel_width = row_width + plate_margin * 2;
row_total_height = bracket_h + label_height;  // コネクタ + ラベル
panel_height = row_total_height * 3 + v_spacing * 2 + plate_margin * 2;

// Y座標（ラベルはコネクタの上）
top_y = row_total_height + v_spacing;
mid_y = 0;
bottom_y = -(row_total_height + v_spacing);

// コネクタのオフセット（ラベル分下にずらす）
conn_offset_y = -label_height / 2;
label_offset_y = bracket_h / 2 + label_height / 2 - 1;  // コネクタの上

// ===== メインパネル =====
module main_panel() {
    difference() {
        // 板
        translate([-panel_width/2, -panel_height/2, 0])
            cube([panel_width, panel_height, plate_thickness]);

        // 上段: DE-9 x3
        for (i = [0:2]) {
            x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
            translate([x, top_y + conn_offset_y, 0])
                de9_cutout();
        }

        // 中段: DE-9 x1 (左) + DA-15 x1 (右)
        translate([-row_width/2 + db9_w/2, mid_y + conn_offset_y, 0])
            de9_cutout();
        translate([row_width/2 - db15_w/2, mid_y + conn_offset_y, 0])
            da15_cutout();

        // 下段: DE-9 x3
        for (i = [0:2]) {
            x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
            translate([x, bottom_y + conn_offset_y, 0])
                de9_cutout();
        }

        // ラベル用の凹み
        label_cutouts();
    }
}

// ===== ラベル（別マテリアル用） =====
module label_text(txt) {
    linear_extrude(height = label_depth)
        text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

// 凹み用（少し大きめ）
module label_cutout_text(txt) {
    linear_extrude(height = label_depth + 0.1)
        offset(delta = 0.05)  // XY方向にわずかに拡大
            text(txt, size = label_font_size, font = label_font, halign = "center", valign = "center");
}

// ラベル用凹み（板から引く）
module label_cutouts() {
    z = plate_thickness - label_depth;

    // 上段
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, top_y + label_offset_y, z])
            label_cutout_text("DE-9");
    }

    // 中段
    translate([-row_width/2 + db9_w/2, mid_y + label_offset_y, z])
        label_cutout_text("DE-9");
    translate([row_width/2 - db15_w/2, mid_y + label_offset_y, z])
        label_cutout_text("DA-15");

    // 下段
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, bottom_y + label_offset_y, z])
            label_cutout_text("DE-9");
    }
}

// ラベル本体（凹みにはまる）
module labels() {
    z = plate_thickness - label_depth;

    // 上段ラベル: DE-9 x3
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, top_y + label_offset_y, z])
            label_text("DE-9");
    }

    // 中段ラベル: DE-9 (左) + DA-15 (右)
    translate([-row_width/2 + db9_w/2, mid_y + label_offset_y, z])
        label_text("DE-9");
    translate([row_width/2 - db15_w/2, mid_y + label_offset_y, z])
        label_text("DA-15");

    // 下段ラベル: DE-9 x3
    for (i = [0:2]) {
        x = -row_width/2 + db9_w/2 + i * (db9_w + h_spacing);
        translate([x, bottom_y + label_offset_y, z])
            label_text("DE-9");
    }
}

// ===== 出力 =====
color("white") main_panel();
color("black") labels();
