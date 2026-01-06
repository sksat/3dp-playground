// FA-130 Rotation Indicator Demo
// FA-130 回転インジケータデモ
//
// モーターシャフトに取り付ける回転確認用ディスク
// マルチカラー印刷対応（白ディスク + 黒パターン）
//
// パターン種類:
//   - radial: 放射状ストライプ（デフォルト、最も視認性が高い）
//   - sector: セクターパターン（白黒交互、ストロボ効果）
//   - arrow: 矢印パターン（回転方向識別可能）
//   - spiral: 螺旋パターン（既存、後方互換性）
//
// 推奨設定:
//   - 低速（< 500 RPM）: pattern_type="arrow", mark_count=6-8
//   - 中速（500-2000 RPM）: pattern_type="radial", mark_count=12（デフォルト）
//   - 高速（> 2000 RPM）: pattern_type="sector", mark_count=16-24
//
// 外形: 直径 22mm x 厚さ 3mm（デフォルト）
// 使用モーター: FA-130 x1
//
// ビルド:
//   openscad --enable=lazy-union -O export-3mf/material-type=color \
//     -o fa130_indicator_demo.3mf fa130_indicator_demo.scad

include <../mabuchi_motor.scad>

// ===== Customizer パラメータ =====

/* [ディスク設定] */
// ディスク直径
disc_d = 22; // [20:1:50]

// ディスク厚さ
disc_h = 3; // [2:0.5:5]

// ハブ直径（シャフト穴周囲の補強）
hub_d = 10; // [8:1:15]

// シャフト穴クリアランス（3Dプリント検証済み）
shaft_tolerance = 0.2; // [0.1:0.1:0.5]

/* [パターン設定] */
// パターン種類（デフォルト: radial = 最も視認性が高い）
pattern_type = "radial"; // ["radial":放射状ストライプ, "sector":セクターパターン, "arrow":矢印パターン, "spiral":螺旋]

// パターン深さ（インレイ用）
pattern_depth = 0.6; // [0.4:0.1:1.0]

// マーク数（radial, sector, arrow用）
mark_count = 12; // [6:1:24]

// マーク幅比率（radial用）
mark_width_ratio = 0.4; // [0.2:0.05:0.8]

// 矢印サイズ比率（arrow用）
arrow_size_ratio = 0.3; // [0.2:0.05:0.5]

/* [螺旋設定（spiral用）] */
// 渦巻きの幅
spiral_w = 1.5; // [1:0.5:3]

// 渦巻きの巻き数
spiral_turns = 2; // [1:0.5:4]

// ===== モジュール =====

// ----- ヘルパーモジュール -----

// 扇形（pie slice）生成
// r_inner: 内径、r_outer: 外径、angle: 角度（度）
module pie_slice_2d(r_inner, r_outer, angle) {
    intersection() {
        difference() {
            circle(r = r_outer, $fn = 96);
            circle(r = r_inner, $fn = 48);
        }
        polygon([
            [0, 0],
            [r_outer * cos(-angle/2), r_outer * sin(-angle/2)],
            [r_outer * cos(angle/2), r_outer * sin(angle/2)]
        ]);
    }
}

// 矢印形状生成（シェブロン形状）
// length: 矢印の長さ、width: 矢印の幅
module arrow_2d(length, width) {
    polygon([
        [-length/2, -width/2],
        [length/2, 0],
        [-length/2, width/2]
    ]);
}

// ----- パターン生成モジュール -----

// 放射状ストライプパターン
// r_inner: 内径、r_outer: 外径、count: ストライプ数、width_ratio: 幅比率（0-1）
module radial_stripes_2d(r_inner, r_outer, count, width_ratio) {
    angle_step = 360 / count;
    stripe_angle = angle_step * width_ratio;

    for (i = [0:count-1]) {
        rotate([0, 0, i * angle_step])
            pie_slice_2d(r_inner, r_outer, stripe_angle);
    }
}

// セクターパターン（白黒交互の扇形）
// r_inner: 内径、r_outer: 外径、count: セクター数（偶数推奨）
module sector_pattern_2d(r_inner, r_outer, count) {
    angle_step = 360 / count;

    for (i = [0:count-1]) {
        if (i % 2 == 0) {  // 偶数番目のみ描画（交互配置）
            rotate([0, 0, i * angle_step])
                pie_slice_2d(r_inner, r_outer, angle_step);
        }
    }
}

// 矢印パターン
// r_inner: 内径、r_outer: 外径、count: 矢印数、arrow_size_ratio: 矢印サイズ比率
module arrow_pattern_2d(r_inner, r_outer, count, arrow_size_ratio) {
    angle_step = 360 / count;
    arrow_length = (r_outer - r_inner) * arrow_size_ratio;
    arrow_width = arrow_length * 0.6;

    for (i = [0:count-1]) {
        rotate([0, 0, i * angle_step])
            translate([0, (r_inner + r_outer) / 2, 0])
                arrow_2d(arrow_length, arrow_width);
    }
}

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

// ----- パターンディスパッチャー -----

// パターンタイプに応じて適切なパターンを生成
module indicator_pattern_2d(
    pattern_type,
    r_inner,
    r_outer,
    mark_count,
    mark_width_ratio,
    arrow_size_ratio,
    spiral_w,
    spiral_turns
) {
    if (pattern_type == "radial") {
        radial_stripes_2d(r_inner, r_outer, mark_count, mark_width_ratio);
    } else if (pattern_type == "sector") {
        sector_pattern_2d(r_inner, r_outer, mark_count);
    } else if (pattern_type == "arrow") {
        arrow_pattern_2d(r_inner, r_outer, mark_count, arrow_size_ratio);
    } else if (pattern_type == "spiral") {
        spiral_2d(r_inner, r_outer, spiral_w, spiral_turns);
    }
}

// ----- インジケータディスクモジュール -----

// ディスク本体（白）
module indicator_disc() {
    shaft_hole_r = (fa130_shaft_d + shaft_tolerance) / 2;
    r_inner = shaft_hole_r + 0.5;  // シャフト穴のすぐ外側から開始
    r_outer = disc_d / 2 - 1;      // 外周より少し内側まで

    difference() {
        cylinder(h = disc_h, d = disc_d, $fn = 48);
        // シャフト穴
        translate([0, 0, -0.1])
            cylinder(h = disc_h + 0.2, d = fa130_shaft_d + shaft_tolerance, $fn = 24);
        // パターンのくり抜き（上面）
        translate([0, 0, disc_h - pattern_depth])
            linear_extrude(height = pattern_depth + 0.1)
                indicator_pattern_2d(pattern_type, r_inner, r_outer,
                                     mark_count, mark_width_ratio,
                                     arrow_size_ratio, spiral_w, spiral_turns);
    }
}

// パターン（黒）
module indicator_pattern() {
    shaft_hole_r = (fa130_shaft_d + shaft_tolerance) / 2;
    r_inner = shaft_hole_r + 0.5;  // シャフト穴のすぐ外側から開始
    r_outer = disc_d / 2 - 1;

    translate([0, 0, disc_h - pattern_depth])
        linear_extrude(height = pattern_depth)
            indicator_pattern_2d(pattern_type, r_inner, r_outer,
                                 mark_count, mark_width_ratio,
                                 arrow_size_ratio, spiral_w, spiral_turns);
}

// ===== 出力 =====

// 白ディスク
color("white")
indicator_disc();

// 黒パターン
color("black")
indicator_pattern();
