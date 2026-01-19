// Jフック穴デモ
//
// マジッククロス8 Jフック用の穴を持つサンプル壁
// フィットチェック用にJフックモデルを表示可能
//
// 外形: 30mm x 30mm x 壁厚
//
// ビルド:
//   openscad -o j_hook_hole_demo.stl j_hook_hole_demo.scad

include <../magic_cross_8_hook.scad>

/* [表示設定] */
show_wall = true;
show_hook = true;       // フィットチェック用

/* [壁設定] */
wall_width = 30;        // [20:5:50]
wall_height = 30;       // [20:5:50]
// 基本壁厚は body_depth + needle_h (= 4mm) 以上が必要
wall_thickness = 4;     // [4:0.5:10]

/* [穴設定] */
// 3Dプリント公差（垂直面は0.4-0.5mm推奨）
hole_tolerance = 0.4;   // [0.2:0.05:0.6]
// 本体埋め込み深さ（フック本体高さ3mm）
body_depth = 3;         // [1:0.5:5]
// 純正カバーを使用する場合はtrue
use_cover = false;

/* 実装 */

// 座標系:
//   Z=0: 構造底面 = 針穴底 = 実際の壁に接する面
//   Z=needle_h: 針穴上端 = 本体凹み底
//   Z=needle_h + body_depth: 本体凹み上端 = 構造表面（カバーなし時）
//   Z=needle_h + cover_h: 構造表面（カバーあり時、カバー上端と一致）

// カバー用の追加厚さ = カバー高さ - 本体深さ
cover_extra = j_hook_cover_h - body_depth;  // 5 - 3 = 2mm
effective_thickness = j_hook_needle_h + body_depth + (use_cover ? cover_extra : 0);

// サンプル壁（穴付き）
module sample_wall() {
    difference() {
        // 壁本体
        translate([-wall_width/2, -wall_height/2, 0])
            cube([wall_width, wall_height, effective_thickness]);

        // Jフック用穴（壁表面から埋め込み + 針穴貫通）
        translate([0, 0, effective_thickness])
            magic_cross_8_j_hook_hole(
                tolerance = hole_tolerance,
                body_depth = body_depth,
                wall_thickness = effective_thickness,
                cover_thickness = use_cover ? j_hook_cover_thickness : 0
            );
    }
}

// 組み立て
if (show_wall) {
    color("WhiteSmoke")
        sample_wall();
}

if (show_hook) {
    // フックを配置（フィットチェック用）
    // Z=0: 針出口底面（実際の壁に接する）
    // Z=needle_h: 本体底面（凹み底に接する）
    translate([0, 0, j_hook_needle_h])
        if (use_cover)
            magic_cross_8_j_hook_with_cover();
        else
            magic_cross_8_j_hook();
}
