// マジッククロス8シリーズ Jフック ライブラリ
//
// フィットチェック用モデルと取り付け穴モジュールを提供
// 賃貸でも使えるフック「マジッククロス8」シリーズのJフック用
//
// 依存: なし

/* 寸法定数 */
j_hook_body_d = 8;           // メイン円柱直径
j_hook_body_h = 3;           // メイン円柱高さ
j_hook_cone_h = 1.5;         // 円錐高さ
j_hook_cone_top_d = 2;       // 円錐上面直径
j_hook_needle_d = 3;         // 針出口直径
j_hook_needle_h = 1;         // 針出口高さ（突出量）

/* 公差 */
default_tolerance = 0.3;

// Jフックモデル（フィットチェック用）
//
// 原点: 円柱底面中心（壁に接する面）
// Z+方向: 円柱 → 円錐（部屋内側）
// Z-方向: 針出口（壁内部）
module magic_cross_8_j_hook() {
    color("LightGray") {
        // メイン円柱
        cylinder(h = j_hook_body_h, d = j_hook_body_d, $fn = 48);

        // 上部円錐
        translate([0, 0, j_hook_body_h])
            cylinder(h = j_hook_cone_h,
                     d1 = j_hook_body_d,
                     d2 = j_hook_cone_top_d,
                     $fn = 48);

        // 底部針出口（下方向に突出）
        translate([0, 0, -j_hook_needle_h])
            cylinder(h = j_hook_needle_h, d = j_hook_needle_d, $fn = 24);
    }
}

// Jフック用穴（取り付け穴）
//
// 原点: 穴の開始位置（壁表面）
// depth: 穴の深さ（壁厚以上を指定）
module magic_cross_8_j_hook_hole(tolerance = default_tolerance, depth = 5) {
    // 針出口用の穴
    translate([0, 0, -0.1])
        cylinder(h = depth + 0.2,
                 d = j_hook_needle_d + tolerance * 2,
                 $fn = 24);
}

// スタンドアロン実行時のプレビュー
magic_cross_8_j_hook();
