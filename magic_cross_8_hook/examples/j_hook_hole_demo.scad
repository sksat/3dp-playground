// Jフック穴デモ
//
// マジッククロス8 Jフック用の穴を持つサンプル壁
// フィットチェック用にJフックモデルを表示可能
//
// 外形: 30mm x 30mm x 壁厚
//
// ビルド:
//   openscad -o j_hook_hole_demo.stl j_hook_hole_demo.scad

use <../magic_cross_8_hook.scad>

/* [表示設定] */
show_wall = true;
show_hook = true;       // フィットチェック用

/* [壁設定] */
wall_width = 30;        // [20:5:50]
wall_height = 30;       // [20:5:50]
wall_thickness = 3;     // [2:0.5:10]

/* [穴設定] */
// 3Dプリント公差（垂直面は0.4-0.5mm推奨）
hole_tolerance = 0.4;   // [0.2:0.05:0.6]
// 本体埋め込み深さ（フック本体高さ3mm）
body_depth = 3;         // [1:0.5:5]

/* 実装 */

// サンプル壁（穴付き）
module sample_wall() {
    difference() {
        // 壁本体
        translate([-wall_width/2, -wall_height/2, 0])
            cube([wall_width, wall_height, wall_thickness]);

        // Jフック用穴（壁表面から埋め込み + 針穴貫通）
        translate([0, 0, wall_thickness])
            magic_cross_8_j_hook_hole(
                tolerance = hole_tolerance,
                body_depth = body_depth,
                wall_thickness = wall_thickness
            );
    }
}

// 組み立て
if (show_wall) {
    color("WhiteSmoke")
        sample_wall();
}

if (show_hook) {
    // フックを穴に埋め込んだ位置に配置（フィットチェック用）
    // フック原点は本体底面なので、壁表面から body_depth 下げる
    translate([0, 0, wall_thickness - body_depth])
        magic_cross_8_j_hook();
}
