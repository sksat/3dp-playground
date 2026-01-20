// DP100 シンプル台座
//
// DP100 実験用電源を載せる簡単な台座
//
// 外形: 約 108mm x 70mm x 7mm
//
// 依存: BOSL2, NopSCADlib, dp100.scad
//
// ビルド:
//   openscad -o dp100_stand.stl dp100_stand.scad

// include ガード（ライブラリのスタンドアロン実行を防止）
_dp100_included = true;
include <../dp100.scad>

// ========================================
// Customizer パラメータ
// ========================================

/* [表示設定] */
show_dp100 = true;  // フィットチェック用にDP100を表示

/* [台座設定] */
tolerance = 0.3; // [0.1:0.05:0.5] 本体とのクリアランス
wall = 2;        // [1:0.5:4] 側壁の厚さ
base = 2;        // [1:0.5:4] 底板の厚さ
lip_height = 5;  // [3:1:10] 縁の高さ
corner_r = 3;    // [1:0.5:5] 角丸半径

// ========================================
// 組み立て
// ========================================

// 台座
color("white")
    dp100_stand(
        tolerance = tolerance,
        wall = wall,
        base = base,
        lip_height = lip_height,
        corner_r = corner_r
    );

// フィットチェック用DP100
if (show_dp100) {
    dp100_in_stand(
        tolerance = tolerance,
        wall = wall,
        base = base
    );
}
