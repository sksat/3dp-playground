// FA-130 Mount Demo
// FA-130 マウントデモ
//
// 横向きマウントの例（モーターを側面から挿入）
//
// 外形: 40mm x 33mm x 25mm
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
base_w = 35;  // タミヤユニバーサルプレート対応
base_d = mount_len + 4;  // マウント長 + 余裕
base_h = 5;

// 取付穴（M3）- タミヤユニバーサルプレート 5mm ピッチ対応
mount_hole_d = 3.4;  // M3 クリアランス
mount_hole_pitch_x = 30;  // X方向ピッチ (5mm x 6)
mount_hole_pitch_y = 25;  // Y方向ピッチ (5mm x 5)

// ===== 組み立て =====

// マウント配置（横向き: シャフトが -Y 方向、モーターは +Y から挿入）
// rotate([180, 0, 90]) で端子側を上、シャフトを Y 方向に
// マウント位置（中央配置）
mount_x = base_w / 2;
mount_y = 0;  // シャフト側をベース前端（Y=0）に揃える
mount_z = base_h + mount_outer_h / 2;

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

        // 取付穴（4隅）- 中央基準でピッチ配置
        for (dx = [-1, 1], dy = [-1, 1]) {
            translate([base_w/2 + dx * mount_hole_pitch_x/2,
                       base_d/2 + dy * mount_hole_pitch_y/2,
                       -0.1])
                cylinder(h = base_h + 0.2, d = mount_hole_d, $fn = 24);
        }
    }
}

// モーターマウント（横向き、端子が上、シャフトが -Y 方向）
// rotate([180, 0, 90]) でマウントを反転し、端子開口を上に、シャフトを Y 方向に
if (show_mount) {
    color("white")
    translate([mount_x, mount_y, mount_z])
        rotate([180, 0, 90])
            mabuchi_motor_fa130_mount(wall = wall, base = base, tolerance = tolerance,
                                       anchor = "motor");
}

// フィットチェック用モーター（マウントと同じ変換）
if (show_motor) {
    translate([mount_x, mount_y, mount_z])
        rotate([180, 0, 90])
            mabuchi_motor_fa130_in_mount(base = base);
}

// カップラー
if (show_coupler) {
    // show_mount=true: 組み立て位置（シャフト先端）、false: 印刷用（Z=0）
    // シャフトは -Y 方向に突出（マウントのシャフト側が Y=0 にあり、そこから -Y へ）
    shaft_tip_y = mount_y - (fa130_shaft_protrusion + fa130_bearing_holder_len);

    color("orange")
    if (show_mount) {
        translate([mount_x, shaft_tip_y, mount_z])
            rotate([90, 0, 0])
                fa130_shaft_coupler(outer_d = coupler_outer_d, length = coupler_length,
                                    with_slit = coupler_with_slit);
    } else {
        fa130_shaft_coupler(outer_d = coupler_outer_d, length = coupler_length,
                            with_slit = coupler_with_slit);
    }
}
