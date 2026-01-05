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
default_shaft_tolerance = 0.2;  // シャフト用（3Dプリント検証済み）

// ===== FA-130 モーター =====
// データシート: FA-130RA (MD121009-1)
// https://www.pololu.com/file/0J11/fa_130ra.pdf
//
// 座標系:
//   原点: シャフト根元（軸受けホルダー前面中心）
//   X軸: シャフト方向（+X にシャフト突出、-X にハウジング）
//   Z軸: 端子方向（+Z にフラット面・端子）
//   Y軸: 曲面方向

// ----- FA-130 寸法定数 -----

// ハウジング
fa130_housing_d = 20.1;      // ハウジング直径（曲面方向）
fa130_housing_h = 15.1;      // フラット面間の幅（Z方向）
fa130_cap_len = 5.2;         // プラスチック基部の長さ（X方向）
fa130_body_len = 25.0;       // 全長（プラスチック基部 + 金属ハウジング）
fa130_housing_len = fa130_body_len - fa130_cap_len;  // 金属ハウジングの長さ = 19.8

// シャフト
fa130_shaft_d = 2.0;         // シャフト直径
fa130_shaft_len = 38.0;      // シャフト全長
fa130_shaft_protrusion = 9.4;  // 金属ハウジングからの突出量

// 軸受けホルダー（シャフト側）
fa130_bearing_holder_d = 6.15;
fa130_bearing_holder_len = 1.7;

// 軸受けホルダー（プラスチック側）
fa130_rear_holder_d = 10.0;
fa130_rear_holder_len = 2.3;

// 端子
fa130_terminal_bump_w = 8.5;   // 出っ張り幅（Y方向）
fa130_terminal_bump_h = 1.4;   // 出っ張り高さ（Z方向突出量）

// FA-130 ハウジング断面（D形状）
// 原点: 中心
// 2D平面でY=曲面方向、X=フラット面方向として定義
// 3D配置時に回転してYZ平面に配置
module _fa130_housing_2d(tolerance = 0) {
    d = fa130_housing_d + tolerance;   // 曲面方向
    h = fa130_housing_h + tolerance;   // フラット面方向
    intersection() {
        circle(d = d, $fn = 48);
        square([h, d], center = true);  // [フラット方向, 曲面方向]
    }
}

// FA-130 フィットチェック用モーターモデル
// +X 方向にシャフト突出
// +Z 方向にフラット面・端子、±Y 方向に曲面
module mabuchi_motor_fa130() {
    // ===== 寸法（外部定数を参照） =====
    housing_d = fa130_housing_d;
    housing_h = fa130_housing_h;
    cap_len = fa130_cap_len;
    body_len = fa130_body_len;
    housing_len = fa130_housing_len;

    shaft_d = fa130_shaft_d;
    shaft_len = fa130_shaft_len;
    shaft_protrusion = fa130_shaft_protrusion;
    // 制約: シャフト先端 = body_len + shaft_protrusion = 34.4
    //       シャフト後端 = シャフト先端 - shaft_len = -3.6
    shaft_tip = body_len + shaft_protrusion;
    shaft_start = shaft_tip - shaft_len;

    bearing_holder_d = fa130_bearing_holder_d;
    bearing_holder_len = fa130_bearing_holder_len;

    rear_holder_d = fa130_rear_holder_d;
    rear_holder_len = fa130_rear_holder_len;

    terminal_bump_w = fa130_terminal_bump_w;
    terminal_bump_h = fa130_terminal_bump_h;

    // 端子（モデル用詳細寸法）
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

// ===== FA-130 マウント =====
// 座標系（モーターと同じ方向）:
//   X軸: シャフト方向（+X にシャフト穴）
//   Z軸: フラット面方向（±Z にフラット面）
//   Y軸: 曲面方向
//
// anchor パラメータ:
//   "motor"  - 原点をモーター座標系に揃える（シャフト穴中心）
//   "bottom" - 原点を底面に揃える（Z=0 が底面、印刷向け）

// FA-130 マウント用カットアウト（difference用）
// 原点: モーター挿入口の中心
// +X 方向に掘り込み（モーターを -X から挿入）
module mabuchi_motor_fa130_cutout(depth = undef, tolerance = default_tolerance) {
    actual_depth = is_undef(depth) ? fa130_body_len : depth;

    translate([-0.1, 0, 0])
        rotate([0, 90, 0])
            linear_extrude(actual_depth + 0.2)
                _fa130_housing_2d(tolerance);
}

// FA-130 はめ込み式マウント
// anchor = "motor": モーター座標系と揃う（配置が簡単）
// anchor = "bottom": 底面が Z=0（印刷向け）
// retention = true: リテンションクリップ（カエシ）を追加
//   clip_length: クリップアーム長さ（挿入口から突き出す長さ）
//   clip_width: アーム幅
//   slit_width: アームを分離するスリット幅
//   tab_depth: 爪の掛かり深さ（内側への突出量）
//   tab_thickness: 爪の厚さ
module mabuchi_motor_fa130_mount(wall = 2, base = 3, tolerance = default_tolerance,
                                  anchor = "motor", retention = true,
                                  clip_length = 2, clip_width = 6,
                                  slit_width = 1.5, tab_depth = 1,
                                  tab_thickness = 1.5) {
    // マウント外形（D形状）
    outer_d = fa130_housing_d + tolerance + wall * 2;
    outer_h = fa130_housing_h + tolerance + wall * 2;
    mount_len = fa130_body_len + base;  // モーター全長 + ベース

    // アンカーによる Z オフセット
    z_offset = (anchor == "bottom") ? -outer_h/2 : 0;

    // クリップ関連の寸法
    inner_d = fa130_housing_d + tolerance;  // モーター収納部の直径
    slit_depth = 10;  // スリットがマウント内に入り込む深さ（弾性確保）

    translate([0, 0, z_offset]) {
        difference() {
            union() {
                // マウント本体
                difference() {
                    // 外形（+X方向に延伸）
                    rotate([0, 90, 0])
                        linear_extrude(mount_len)
                            intersection() {
                                circle(d = outer_d, $fn = 48);
                                square([outer_h, outer_d], center = true);
                            }

                    // モーター収納部（+X から）
                    translate([base, 0, 0])
                        mabuchi_motor_fa130_cutout(fa130_body_len + 0.1, tolerance);

                    // シャフト穴（軸受けホルダーを避ける）
                    translate([-0.1, 0, 0])
                        rotate([0, 90, 0])
                            cylinder(h = base + 0.2, d = fa130_bearing_holder_d + tolerance, $fn = 24);

                    // 端子用開口（-Z 側、挿入口付近を完全オープン）
                    // モーターは180°回転して挿入されるため、端子は -Z 側に来る
                    terminal_slot_len = fa130_cap_len + 2;  // 端子領域 + 余裕
                    translate([mount_len - terminal_slot_len, -outer_d/2, -(fa130_housing_h + tolerance)/2 - wall - 0.1])
                        cube([terminal_slot_len + 0.1, outer_d, wall + 0.2]);
                }

                // リテンションクリップ（カエシ）
                // マウント外形の曲面部分が伸びた形で自然に見える
                if (retention) {
                    for (dy = [-1, 1]) {
                        // クリップアーム（マウント曲面部分の延長、爪の手前まで）
                        // 円弧形状でマウント外形と連続する
                        arm_len = clip_length - tab_thickness;  // 爪の手前まで
                        translate([mount_len - 0.1, 0, 0])
                            rotate([0, 90, 0])
                                linear_extrude(arm_len + 0.1)
                                    intersection() {
                                        // 外側円弧（壁部分）
                                        difference() {
                                            circle(d = outer_d, $fn = 48);
                                            circle(d = inner_d, $fn = 48);
                                        }
                                        // 曲面部分のみ（±Y 側、壁の中心位置）
                                        // 2D: X→Z(3D), Y→Y(3D)
                                        translate([0, dy * (inner_d/2 + wall/2)])
                                            square([clip_width, wall * 2], center = true);
                                    }

                        // 爪（アームから爪先端まで滑らかに繋ぐ）
                        // hull() でアーム先端の円弧断面と爪先端を接続
                        tab_inner_y = dy * (inner_d/2 - tab_depth);  // 爪の内側面
                        tab_outer_y = dy * (inner_d/2);              // 爪の外側面（アーム内側と同じ）
                        hull() {
                            // アーム先端の断面（薄いスライス）
                            translate([mount_len + arm_len - 0.1, 0, 0])
                                rotate([0, 90, 0])
                                    linear_extrude(0.1)
                                        intersection() {
                                            difference() {
                                                circle(d = outer_d, $fn = 48);
                                                circle(d = inner_d, $fn = 48);
                                            }
                                            translate([0, dy * (inner_d/2 + wall/2)])
                                                square([clip_width, wall * 2], center = true);
                                        }
                            // 爪先端（直方体）
                            translate([mount_len + clip_length - 0.1, tab_inner_y + (dy < 0 ? 0 : -tab_depth), -clip_width/2])
                                cube([0.1, tab_depth, clip_width]);
                        }
                    }
                }
            }

            // スリット（アームをマウント本体から分離して弾性を持たせる）
            if (retention) {
                for (dy = [-1, 1]) {
                    // アームの両側（±Z 側）にスリット
                    for (dz = [-1, 1]) {
                        slit_z = dz * (clip_width/2 + slit_width/2);
                        translate([mount_len - slit_depth, dy * (inner_d/2 + wall/2) - wall/2 - 0.1, slit_z - slit_width/2])
                            cube([slit_depth + clip_length - tab_thickness + 0.2, wall + 0.2, slit_width]);
                    }
                }
            }
        }
    }
}

// FA-130 マウント内のモーター位置にモーターモデルを表示
// フィットチェック用（マウントと同じ変換を適用して使用）
// base: マウントの base パラメータと同じ値を指定
module mabuchi_motor_fa130_in_mount(base = 3) {
    translate([base + fa130_body_len, 0, 0])
        rotate([0, 180, 0])
            mabuchi_motor_fa130();
}

// 便利モジュール（エイリアス）
module fa130_motor() { mabuchi_motor_fa130(); }
module fa130_mount(wall = 2, base = 3, tolerance = default_tolerance,
                   anchor = "motor", retention = true,
                   clip_length = 2, clip_width = 6,
                   slit_width = 1.5, tab_depth = 1,
                   tab_thickness = 1.5) {
    mabuchi_motor_fa130_mount(wall, base, tolerance, anchor, retention,
                               clip_length, clip_width, slit_width,
                               tab_depth, tab_thickness);
}
module fa130_motor_in_mount(base = 3) { mabuchi_motor_fa130_in_mount(base); }
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
    shaft_coupler(fa130_shaft_d, outer_d, length, tolerance, with_slit, slit_width);
}

// ===== デモ表示 =====
// ライブラリとして使用するためデモ表示なし
// 単体で確認したい場合は以下をコメント解除：
// mabuchi_motor_fa130();
