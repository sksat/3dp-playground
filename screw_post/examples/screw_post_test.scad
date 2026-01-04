// Screw Post テストピース
// ナットポケットのフィット確認用
//
// 外形: 16mm x 16mm x 18mm (wall 3mm + post 15mm)
// 使用ネジ: M3 x 20mm
//
// ナットポケット: ベース底面から 2.4mm 凹み、上に 0.6mm 残る
// （ベース厚 3mm >= ナット厚 2.4mm + 最低肉厚 0.6mm なので貫通しない）
//
// ビルド:
//   openscad -o screw_post_test.stl screw_post_test.scad

use <../screw_post.scad>

// ===== パラメータ =====
size = "M3";
wall_thickness = 3;
post_h = 15;
pcb_thickness = 1.6;
// 理想的なネジ長さ ≒ post_h + wall_thickness + pcb_thickness = 19.6mm → 20mm
screw_len = 20;

// レイアウト
margin = 2.5;
post_d = screw_post_d(size);
base_size = post_d + margin * 2;

// ===== テストピース =====
difference() {
    union() {
        // ベース板
        cube([base_size, base_size, wall_thickness]);

        // ポスト
        translate([base_size/2, base_size/2, wall_thickness])
            screw_post(size, h = post_h);
    }

    // ネジ穴 + ナットポケット
    translate([base_size/2, base_size/2, wall_thickness])
        screw_post_hole(size, h = post_h,
                        screw_length = screw_len,
                        material_thickness = pcb_thickness,
                        base_thickness = wall_thickness);
}
