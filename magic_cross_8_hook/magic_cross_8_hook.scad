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
// 3Dプリント公差: 水平面 0.3mm、垂直面 0.4-0.5mm 推奨
default_tolerance = 0.4;  // 垂直壁への穴を想定

// Jフックモデル（フィットチェック用）
//
// 原点: 本体底面中心（壁表面に接する面）
// Z+方向: 本体 → 円錐（部屋内側へ）
// Z-方向: 針出口（壁穴の中へ）
//
// 層構成:
//   Z=-1〜0: 針出口（壁穴に入る）
//   Z=0〜3: メイン円柱（壁表面から上）
//   Z=3〜4.5: 円錐
module magic_cross_8_j_hook() {
    color("LightGray") {
        // 底部針出口（壁穴に入る部分、Z-方向）
        translate([0, 0, -j_hook_needle_h])
            cylinder(h = j_hook_needle_h, d = j_hook_needle_d, $fn = 24);

        // メイン円柱
        cylinder(h = j_hook_body_h, d = j_hook_body_d, $fn = 48);

        // 上部円錐
        translate([0, 0, j_hook_body_h])
            cylinder(h = j_hook_cone_h,
                     d1 = j_hook_body_d,
                     d2 = j_hook_cone_top_d,
                     $fn = 48);
    }
}

// Jフック用穴（取り付け穴）
//
// 原点: 壁表面（Z=0）、穴はZ-方向に掘られる
// body_depth: 本体埋め込み深さ（デフォルトは本体高さ）
// wall_thickness: 壁厚（針穴の貫通用）
//
// 構造:
//   壁表面 → 本体用凹み(8mm) → 針用穴(3mm) → 壁裏面
module magic_cross_8_j_hook_hole(
    tolerance = default_tolerance,
    body_depth = j_hook_body_h,
    wall_thickness = 5
) {
    // 本体埋め込み用凹み
    translate([0, 0, -body_depth - 0.1])
        cylinder(h = body_depth + 0.2,
                 d = j_hook_body_d + tolerance * 2,
                 $fn = 48);

    // 針出口用貫通穴
    translate([0, 0, -wall_thickness - 0.1])
        cylinder(h = wall_thickness + 0.2,
                 d = j_hook_needle_d + tolerance * 2,
                 $fn = 24);
}

// スタンドアロン実行時のプレビュー
magic_cross_8_j_hook();
