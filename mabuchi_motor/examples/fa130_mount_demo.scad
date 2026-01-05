// FA-130 Mount Demo
// FA-130 マウントデモ
//
// シンプルな取付ベースの例
//
// 外形: 60mm x 40mm x 35mm
// 使用モーター: FA-130 x1
// 使用ネジ: M3 x4（ベース固定用）
//
// ビルド:
//   openscad -o fa130_mount_demo.stl fa130_mount_demo.scad

include <../mabuchi_motor.scad>

// ===== Customizer パラメータ =====

/* [表示設定] */
// モーターモデルを表示（フィットチェック用）
show_motor = false;

// カップラーを表示
show_coupler = true;

// マウントを表示
show_mount = true;

// ベースを表示
show_base = true;

/* [マウント設定] */
// 嵌合クリアランス
tolerance = 0.3; // [0.1:0.05:0.5]

// 壁厚
wall = 2.5; // [1.5:0.5:4]

// ベース厚
base = 4; // [2:1:6]

/* [カップラー設定] */
// カップラー外径
coupler_outer_d = 10; // [6:1:16]

// カップラー長さ
coupler_length = 12; // [8:1:20]

// スリット追加
coupler_with_slit = true;

// ===== 定数 =====

// マウント外形（外部定数から計算）
mount_outer_d = fa130_housing_d + tolerance + wall * 2;
mount_outer_h = fa130_housing_h + tolerance + wall * 2;
mount_len = fa130_body_len + base;

// ベース寸法
base_w = 60;
base_d = 40;
base_h = 5;

// 取付穴
mount_hole_d = 3.4;  // M3 クリアランス
mount_hole_inset = 8;

// ===== 組み立て =====

// ベースプレート
if (show_base) {
    color("white")
    difference() {
        // 角丸プレート
        hull() {
            for (x = [5, base_w - 5], y = [5, base_d - 5]) {
                translate([x, y, 0])
                    cylinder(h = base_h, r = 5, $fn = 24);
            }
        }

        // 取付穴（4隅）
        for (x = [mount_hole_inset, base_w - mount_hole_inset],
             y = [mount_hole_inset, base_d - mount_hole_inset]) {
            translate([x, y, -0.1])
                cylinder(h = base_h + 0.2, d = mount_hole_d, $fn = 24);
        }
    }
}

// モーターマウント（ベース中央、シャフトが上向き）
// rotate([0, 90, 0]) で X+ → Z-、シャフト側（X=0）が上になる
// 回転後の Z 範囲: [-mount_len, 0]、translate で持ち上げる
if (show_mount) {
    color("white")
    translate([base_w/2, base_d/2, base_h + mount_len])
        rotate([0, 90, 0])
            mabuchi_motor_fa130_mount(wall = wall, base = base, tolerance = tolerance,
                                       anchor = "motor");
}

// フィットチェック用モーター（マウントと同じ変換を適用）
if (show_motor) {
    translate([base_w/2, base_d/2, base_h + mount_len])
        rotate([0, 90, 0])
            mabuchi_motor_fa130_in_mount(base = base);
}

// カップラー
if (show_coupler) {
    // show_mount=true: 組み立て位置、false: 印刷用（Z=0）
    coupler_z = show_mount ? base_h + mount_len + fa130_shaft_protrusion + fa130_bearing_holder_len - coupler_length : 0;

    color("orange")
    translate([show_mount ? base_w/2 : 0, show_mount ? base_d/2 : 0, coupler_z])
        fa130_shaft_coupler(outer_d = coupler_outer_d, length = coupler_length,
                            with_slit = coupler_with_slit);
}
