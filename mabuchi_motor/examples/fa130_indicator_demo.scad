// FA-130 Rotation Indicator Demo
// FA-130 回転インジケータデモ
//
// モーターシャフトに取り付ける回転確認用ディスク
// マルチカラー印刷対応（白ディスク + 黒渦巻き）
//
// 外形: 直径 25mm x 厚さ 3mm
// 使用モーター: FA-130 x1
//
// ビルド:
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o fa130_indicator_demo.3mf fa130_indicator_demo.scad

include <../mabuchi_motor.scad>

// ===== Customizer パラメータ =====

/* [ディスク設定] */
// ディスク直径
disc_d = 25; // [20:5:50]

// ディスク厚さ
disc_h = 3; // [2:0.5:5]

// ハブ直径（シャフト穴周囲の補強）
hub_d = 10; // [8:1:15]

// シャフト穴クリアランス（3Dプリント検証済み）
shaft_tolerance = 0.2; // [0.1:0.1:0.5]

/* [渦巻き設定] */
// 渦巻きの幅
spiral_w = 1.5; // [1:0.5:3]

// 渦巻きの深さ（インレイ用）
spiral_depth = 0.6; // [0.4:0.1:1.0]

// 渦巻きの巻き数
spiral_turns = 2; // [1:0.5:4]

// ===== モジュール =====

// 渦巻き形状（2Dポリゴン）
// アルキメデスの螺旋: r = a + b * θ
module spiral_2d(r_inner, r_outer, width, turns, steps_per_turn = 36) {
    total_steps = turns * steps_per_turn;
    // 螺旋の成長率（1回転あたり幅 + 間隔分だけ成長）
    growth = (r_outer - r_inner) / turns;

    // 外側の螺旋点
    outer_points = [for (i = [0:total_steps])
        let(theta = i * 360 / steps_per_turn,
            r = r_inner + (i / steps_per_turn) * growth)
        [r * cos(theta), r * sin(theta)]
    ];

    // 内側の螺旋点（幅分だけ内側、逆順）
    inner_points = [for (i = [total_steps:-1:0])
        let(theta = i * 360 / steps_per_turn,
            r = max(r_inner - width/2, width/2) + (i / steps_per_turn) * growth - width/2)
        [r * cos(theta), r * sin(theta)]
    ];

    polygon(concat(outer_points, inner_points));
}

// ディスク本体（白）
module indicator_disc(d = 25, h = 3, hub_d = 10, shaft_tolerance = 0.2,
                      spiral_w = 1.5, spiral_depth = 0.6, spiral_turns = 2) {
    shaft_hole_r = (fa130_shaft_d + shaft_tolerance) / 2;
    r_inner = shaft_hole_r + 0.5;  // シャフト穴のすぐ外側から開始
    r_outer = d / 2 - 1;           // 外周より少し内側まで

    difference() {
        cylinder(h = h, d = d, $fn = 48);
        // シャフト穴
        translate([0, 0, -0.1])
            cylinder(h = h + 0.2, d = fa130_shaft_d + shaft_tolerance, $fn = 24);
        // 渦巻きのくり抜き（上面）
        translate([0, 0, h - spiral_depth])
            linear_extrude(height = spiral_depth + 0.1)
                spiral_2d(r_inner, r_outer, spiral_w, spiral_turns);
    }
}

// 渦巻きパターン（黒）
module indicator_spiral(d = 25, h = 3, hub_d = 10, shaft_tolerance = 0.2,
                        spiral_w = 1.5, spiral_depth = 0.6, spiral_turns = 2) {
    shaft_hole_r = (fa130_shaft_d + shaft_tolerance) / 2;
    r_inner = shaft_hole_r + 0.5;  // シャフト穴のすぐ外側から開始
    r_outer = d / 2 - 1;

    translate([0, 0, h - spiral_depth])
        linear_extrude(height = spiral_depth)
            spiral_2d(r_inner, r_outer, spiral_w, spiral_turns);
}

// ===== 出力 =====

// 白ディスク
color("white")
indicator_disc(d = disc_d, h = disc_h, hub_d = hub_d, shaft_tolerance = shaft_tolerance,
               spiral_w = spiral_w, spiral_depth = spiral_depth, spiral_turns = spiral_turns);

// 黒渦巻き
color("black")
indicator_spiral(d = disc_d, h = disc_h, hub_d = hub_d, shaft_tolerance = shaft_tolerance,
                 spiral_w = spiral_w, spiral_depth = spiral_depth, spiral_turns = spiral_turns);
