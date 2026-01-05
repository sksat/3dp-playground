// Mabuchi Motor Library
// マブチモーター ライブラリ
//
// 提供モジュール（FA-130）:
//   mabuchi_motor_fa130()             - フィットチェック用モーターモデル
//   mabuchi_motor_fa130_mount(...)    - はめ込み式マウント
//   mabuchi_motor_fa130_cutout(...)   - マウント用カットアウト（difference用）
//   fa130_shaft_coupler(...)          - シャフトカップラー（φ2mm）
//
// 汎用モジュール:
//   shaft_coupler(shaft_d, ...)       - 汎用シャフトカップラー
//
// 対応モーター:
//   FA-130: 20×15×25mm (D形状ハウジング) ※実装済み
//   RE-260: φ24×28mm (円筒ハウジング)    ※TODO: 未実装
//   RE-280: φ24×30.5mm (円筒ハウジング)  ※TODO: 未実装
//
// 使用例:
//   // フィットチェック
//   mabuchi_motor_fa130();
//
//   // マウント作成
//   mabuchi_motor_fa130_mount();

// ===== 定数 =====

default_tolerance = 0.3;
default_shaft_tolerance = 0.1;  // シャフト用（タイトフィット）

// ===== FA-130 モーター =====
// データシート: FA-130RA (MD121009-1)
// https://www.pololu.com/file/0J11/fa_130ra.pdf
//
// 座標系:
//   原点: シャフト根元（軸受けホルダー前面中心）
//   X軸: シャフト方向（+X にシャフト突出、-X にハウジング）
//   Z軸: 端子方向（+Z にフラット面・端子）
//   Y軸: 曲面方向

// FA-130 ハウジング断面（D形状）
// 原点: 中心
// 2D平面でY=曲面方向、X=フラット面方向として定義
// 3D配置時に回転してYZ平面に配置
module _fa130_housing_2d(tolerance = 0) {
    d = 20.1 + tolerance;  // 曲面方向 (φ20.1)
    h = 15 + tolerance;    // フラット面方向
    intersection() {
        circle(d = d, $fn = 48);
        square([h, d], center = true);  // [フラット方向, 曲面方向]
    }
}

// FA-130 フィットチェック用モーターモデル
// +X 方向にシャフト突出
// +Z 方向にフラット面・端子、±Y 方向に曲面
module mabuchi_motor_fa130() {
    // ===== 寸法 =====
    housing_d = 20.1;    // ハウジング直径（曲面方向）
    housing_h = 15.1;    // フラット面間の幅（Z方向）
    cap_len = 5.2;       // プラスチック基部の長さ（X方向）
    body_len = 25.0;     // 全長（プラスチック基部 + 金属ハウジング）
    housing_len = body_len - cap_len;  // 金属ハウジングの長さ = 19.8

    // シャフト
    shaft_d = 2.0;       // シャフト直径
    shaft_len = 38.0;    // シャフト全長
    shaft_protrusion = 9.4;  // 金属ハウジングからの突出量
    // 制約: シャフト先端 = body_len + shaft_protrusion = 34.4
    //       シャフト後端 = シャフト先端 - shaft_len = -3.6
    shaft_tip = body_len + shaft_protrusion;
    shaft_start = shaft_tip - shaft_len;

    // 軸受けホルダー（シャフト側）
    bearing_holder_d = 6.15;
    bearing_holder_len = 1.7;

    // 軸受けホルダー（プラスチック側）
    rear_holder_d = 10.0;
    rear_holder_len = 2.3;

    // 端子用出っ張り（プラスチック基部上面）
    terminal_bump_w = 8.5;   // 幅（Y方向）
    terminal_bump_h = 1.4;   // 高さ（Z方向突出量）

    // 端子
    terminal_x = 3.4;        // X位置
    terminal_w = 0.8;        // 端子幅（X方向）
    terminal_t = 0.1;        // 端子厚み（Y方向）
    terminal_len = 4.0;      // 端子長さ（Z方向）

    // ===== 部品 =====

    // 1. プラスチック基部
    //    X=0 ~ cap_len (5.2)
    color([1, 0.95, 0.8])  // クリーム色
    difference() {
        rotate([0, 90, 0])
            cylinder(h = cap_len, d = housing_d, $fn = 96);

        // +Z側を削る（Z > housing_h/2）
        translate([cap_len/2, 0, housing_h/2 + housing_d/2])
            cube([cap_len + 0.2, housing_d + 0.2, housing_d], center = true);

        // -Z側を削る（Z < -housing_h/2）
        translate([cap_len/2, 0, -housing_h/2 - housing_d/2])
            cube([cap_len + 0.2, housing_d + 0.2, housing_d], center = true);
    }

    // 2. 金属ハウジング
    //    X=cap_len (5.2) ~ body_len (25.0)
    color("silver")
    translate([cap_len, 0, 0])
    difference() {
        rotate([0, 90, 0])
            cylinder(h = housing_len, d = housing_d, $fn = 96);

        // +Z側を削る（Z > housing_h/2）
        translate([housing_len/2, 0, housing_h/2 + housing_d/2])
            cube([housing_len + 0.2, housing_d + 0.2, housing_d], center = true);

        // -Z側を削る（Z < -housing_h/2）
        translate([housing_len/2, 0, -housing_h/2 - housing_d/2])
            cube([housing_len + 0.2, housing_d + 0.2, housing_d], center = true);
    }

    // 3. シャフト
    //    X=shaft_start (-3.6) ~ shaft_tip (34.4)
    color("silver")
    translate([shaft_start, 0, 0])
        rotate([0, 90, 0])
            cylinder(h = shaft_len, d = shaft_d, $fn = 32);

    // 4. 軸受けホルダー（シャフト側）
    //    X=body_len (25.0) ~ body_len + bearing_holder_len (26.7)
    color("silver")
    translate([body_len, 0, 0])
        rotate([0, 90, 0])
            cylinder(h = bearing_holder_len, d = bearing_holder_d, $fn = 32);

    // 5. 軸受けホルダー（プラスチック側）
    //    X=-rear_holder_len (-2.3) ~ 0
    //    -Z側に平面あり（Z < -4.0 を削る）
    rear_holder_flat = 4.0;  // 平面位置（-Z方向）
    color([1, 0.95, 0.8])  // クリーム色
    difference() {
        rotate([0, -90, 0])
            cylinder(h = rear_holder_len, d = rear_holder_d, $fn = 32);

        // -Z側を削る（Z < -rear_holder_flat）
        translate([-rear_holder_len/2, 0, -rear_holder_flat - rear_holder_d/2])
            cube([rear_holder_len + 0.2, rear_holder_d + 0.2, rear_holder_d], center = true);
    }

    // 6. 端子用出っ張り（プラスチック基部上面）
    color([1, 0.95, 0.8])  // クリーム色
    translate([cap_len/2, 0, housing_h/2 + terminal_bump_h/2])
        cube([cap_len, terminal_bump_w, terminal_bump_h], center = true);

    // 7. 端子（出っ張りの付け根から斜めに伸びる）
    //    付け根 = 出っ張りの外側の段差部分（Y = ±terminal_bump_w/2）
    //    平たい形状（厚み 0.1mm）
    //    先端高さ = terminal_bump_h (1.4mm)、端子長 = terminal_len (4.0mm)
    //    傾き角度 = acos(terminal_bump_h / terminal_len)（Z軸からの角度）
    //    外側に傾けるには -dy * angle
    terminal_angle = acos(terminal_bump_h / terminal_len);
    color("gold")
    for (dy = [-1, 1])
        translate([terminal_x, dy * terminal_bump_w/2, housing_h/2])
            rotate([-dy * terminal_angle, 0, 0])
                translate([0, 0, terminal_len/2])
                    cube([terminal_w, terminal_t, terminal_len], center = true);
}

// FA-130 マウント用カットアウト（difference用）
// 原点: モーター挿入口の中心（シャフト側）
// -X 方向に掘り込み（モーターを +X から挿入）
module mabuchi_motor_fa130_cutout(depth = undef, tolerance = default_tolerance) {
    housing_len = 19.8;
    actual_depth = is_undef(depth) ? housing_len + 4 : depth;

    translate([0.1, 0, 0])
        rotate([0, 90, 0])
            linear_extrude(actual_depth + 0.2)
                _fa130_housing_2d(tolerance);
}

// FA-130 はめ込み式マウント
// 原点: シャフト穴中心（+X面）
// モーターは +X 方向から挿入
module mabuchi_motor_fa130_mount(wall = 2, base = 3, tolerance = default_tolerance) {
    housing_d = 20.1;
    housing_h = 15;
    housing_len = 19.8;
    shaft_d = 2;

    // マウント外形（D形状）
    outer_d = housing_d + tolerance + wall * 2;
    outer_h = housing_h + tolerance + wall * 2;
    mount_len = housing_len + 4 + base;  // ハウジング + キャップ + ベース

    difference() {
        // 外形（-X方向に延伸）
        rotate([0, 90, 0])
            linear_extrude(mount_len)
                intersection() {
                    circle(d = outer_d, $fn = 48);
                    square([outer_h, outer_d], center = true);
                }

        // モーター収納部
        translate([-base, 0, 0])
            mabuchi_motor_fa130_cutout(housing_len + 4 + 0.1, tolerance);

        // シャフト穴（+X方向に貫通）
        translate([-mount_len - 0.1, 0, 0])
            rotate([0, 90, 0])
                cylinder(h = base + 0.2, d = shaft_d + 1, $fn = 24);
    }
}

// 便利モジュール（エイリアス）
module fa130_motor() { mabuchi_motor_fa130(); }
module fa130_mount(wall = 2, base = 3, tolerance = default_tolerance) {
    mabuchi_motor_fa130_mount(wall, base, tolerance);
}
module fa130_mount_cutout(depth = undef, tolerance = default_tolerance) {
    mabuchi_motor_fa130_cutout(depth, tolerance);
}

// TODO: RE-260/RE-280 モーター
// 構造が FA-130 と異なるため、データシート確認後に別途実装
// module mabuchi_motor_re260() { ... }
// module mabuchi_motor_re280() { ... }

// ===== シャフトカップラー =====

// 汎用シャフトカップラー
// 原点: 底面中心
// シャフト穴は上から
module shaft_coupler(shaft_d = 2, outer_d = 8, length = 10,
                     tolerance = default_shaft_tolerance,
                     with_slit = false, slit_width = 1) {
    difference() {
        // 外形
        cylinder(h = length, d = outer_d, $fn = 32);

        // シャフト穴
        translate([0, 0, -0.1])
            cylinder(h = length + 0.2, d = shaft_d + tolerance, $fn = 24);

        // スリット（締め付け用）
        if (with_slit) {
            translate([0, -slit_width/2, length * 0.3])
                cube([outer_d/2 + 0.1, slit_width, length * 0.7 + 0.1]);
        }
    }
}

// FA-130 用シャフトカップラー（シャフト径φ2mm）
module fa130_shaft_coupler(outer_d = 8, length = 10,
                           tolerance = default_shaft_tolerance,
                           with_slit = false, slit_width = 1) {
    shaft_coupler(2, outer_d, length, tolerance, with_slit, slit_width);
}

// ===== デモ表示 =====
// 単体で開いた場合のみ表示（use/include 時は _mabuchi_motor_lib を定義して非表示に）
if (is_undef(_mabuchi_motor_lib)) {
    mabuchi_motor_fa130();
}
