// Heat-Set Insert Demo
// ヒートセットインサートの使用例
//
// 外形: 60mm x 25mm x 10mm
// 依存: heat_insert.scad
//
// ビルド (マルチカラー):
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o insert_demo.3mf insert_demo.scad

use <../heat_insert.scad>

// ===== パラメータ =====
base_width = 60;
base_depth = 25;
base_height = 2;
boss_h = 8;
spacing = 20;

label_depth = 0.6;
label_font_size = 4;
label_font = "Liberation Sans:style=Bold";

// ===== デモ: 複数サイズ比較 =====
sizes = ["M2", "M2.5", "M3"];

// ラベルテキスト（凹み用、少し大きめ）
module label_cutout(txt) {
    linear_extrude(height = label_depth + 0.1)
        offset(delta = 0.05)
            text(txt, size = label_font_size, font = label_font, halign = "center", valign = "top");
}

// ラベルテキスト（本体）
module label_text(txt) {
    linear_extrude(height = label_depth)
        text(txt, size = label_font_size, font = label_font, halign = "center", valign = "top");
}

// ベース板 + ボス（白）
color("white") difference() {
    union() {
        // ベース板
        cube([base_width, base_depth, base_height]);

        // ボス
        for (i = [0:len(sizes)-1]) {
            size = sizes[i];
            boss_d = insert_boss_d(size);
            translate([spacing/2 + i * spacing, base_depth/2, base_height])
                cylinder(h = boss_h, d = boss_d, $fn = 24);
        }
    }

    // インサート穴
    for (i = [0:len(sizes)-1]) {
        size = sizes[i];
        translate([spacing/2 + i * spacing, base_depth/2, base_height + boss_h])
            insert_hole(size);
    }

    // ラベル凹み
    for (i = [0:len(sizes)-1]) {
        size = sizes[i];
        boss_d = insert_boss_d(size);
        translate([spacing/2 + i * spacing, base_depth/2 - boss_d/2 - 2, base_height - label_depth])
            label_cutout(size);
    }
}

// ラベル（黒、凹みに埋め込み）
color("black") {
    for (i = [0:len(sizes)-1]) {
        size = sizes[i];
        boss_d = insert_boss_d(size);
        translate([spacing/2 + i * spacing, base_depth/2 - boss_d/2 - 2, base_height - label_depth])
            label_text(size);
    }
}

// ===== カメラ設定（上から） =====
$vpr = [0, 0, 0];
$vpt = [base_width/2, base_depth/2, 0];
$vpd = 120;
