// Mabuchi Motor Library
// マブチモーター ライブラリ
//
// 提供モジュール:
//   mabuchi_motor(type)                    - フィットチェック用モーターモデル
//   mabuchi_motor_mount(type, ...)         - はめ込み式マウント
//   mabuchi_motor_mount_cutout(type, ...)  - マウント用カットアウト（difference用）
//   shaft_coupler(shaft_d, ...)            - 汎用シャフトカップラー
//
// 対応モーター:
//   FA-130: 20×15×25mm (D形状ハウジング)
//   RE-260: φ24×28mm (円筒ハウジング)
//   RE-280: φ24×30.5mm (円筒ハウジング)
//
// 参考:
//   https://www.pololu.com/file/0J11/fa_130ra.pdf
//   https://www.hobbyengineering.com/products/h2242
//
// 使用例:
//   // フィットチェック
//   mabuchi_motor("FA-130");
//
//   // マウント作成
//   mabuchi_motor_mount("FA-130");

// ===== 定数 =====

default_tolerance = 0.3;
default_shaft_tolerance = 0.1;  // シャフト用（タイトフィット）

// ===== 寸法ルックアップテーブル =====

// モーター仕様
// 戻り値: [width, height, length, shaft_d, shaft_length, terminal_length]
// width: ハウジング幅（曲面方向）
// height: ハウジング高さ（フラット面方向、FA-130のみ）
// length: ハウジング長さ（シャフト側からキャップまで）
// 参考: FA-130RA データシート (MD121009-1)
// FA-130: プラスチック部底面〜金属部天面（ホルダー除く）= 25.0mm
//         キャップ5.2mm → 金属ハウジング19.8mm
// シャフト: 全長38.0mm, 金属天面から先端まで9.4mm
function mabuchi_motor_specs(type) =
    type == "FA-130" ? [20.1, 15, 19.8, 2, 9.4, 4] :
    type == "RE-260" ? [24, 24, 28, 2, 10, 4] :
    type == "RE-280" ? [24, 24, 30.5, 2, 12.3, 4] :
    undef;

// シャフト径のみ取得
function mabuchi_shaft_d(type) =
    let(specs = mabuchi_motor_specs(type))
    is_undef(specs) ? undef : specs[3];

// ===== 内部2D形状 =====

// FA-130 ハウジング断面（D形状）
// 原点: 中心
// データシート: φ20.1 x 15.0mm
module _fa130_housing_2d(tolerance = 0) {
    w = 20.1 + tolerance;  // 曲面方向 (φ20.1)
    h = 15 + tolerance;    // フラット面方向

    intersection() {
        circle(d = w, $fn = 48);
        square([w, h], center = true);
    }
}

// 円筒ハウジング断面（RE-260/280）
// 原点: 中心
module _cylinder_housing_2d(d, tolerance = 0) {
    circle(d = d + tolerance, $fn = 48);
}

// ===== フィットチェック用モーターモデル =====

// マブチモーター
// 原点: シャフト根元（ハウジング前面中心）
// シャフトは +Z 方向に延伸
// ハウジングは -Z 方向に延伸
module mabuchi_motor(type = "FA-130") {
    specs = mabuchi_motor_specs(type);

    if (is_undef(specs)) {
        echo(str("ERROR: Unknown motor type: ", type));
        echo("Available types: FA-130, RE-260, RE-280");
        color("red") cube([10, 10, 10], center = true);
    } else {
        w = specs[0];
        h = specs[1];
        len = specs[2];
        shaft_d = specs[3];
        shaft_len = specs[4];
        terminal_len = specs[5];

        // エンドキャップ寸法
        // データシート: 5.2mm
        cap_len = 5.2;

        // ブラシカバー出っ張り寸法（端子側の丸い突起）
        // FA-130: φ9.8mm, 高さ2.3mm
        brush_cover_d = (type == "FA-130") ? 9.8 : 12;
        brush_cover_h = (type == "FA-130") ? 2.3 : 2;

        // 端子出っ張り寸法（端子が出る小さな突起）
        // データシート: 幅8.5mm, 高さ5.2mm, 奥行き1.04mm
        terminal_bump_w = 8.5;   // 幅
        terminal_bump_d = 1.04;  // 突出量（奥行き）
        terminal_bump_h = 5.2;   // 高さ

        // 軸受けホルダー（シャフト側）
        // データシート: 高さ1.7mm, 直径6.15mm
        bearing_holder_h = 1.7;
        bearing_holder_d = 6.15;

        // 軸受けホルダー（プラスチック側）
        // データシート: 直径9.8mm
        rear_bearing_d = 9.8;

        // シャフト（全長38.0mm、本体を貫通）
        // 金属天面（ホルダー除く）から上に9.4mm突出
        // 下部突出 = 38.0 - 9.4 - 25.0(本体) - 2.3(ブラシカバー) = 1.3mm
        shaft_total = 38.0;
        metal_top_z = -bearing_holder_h;  // 金属ハウジング天面
        shaft_tip_z = metal_top_z + shaft_len;  // = -1.7 + 9.4 = 7.7
        shaft_bottom_z = shaft_tip_z - shaft_total;  // = 7.7 - 38.0 = -30.3
        color("silver")
        translate([0, 0, shaft_bottom_z])
            cylinder(h = shaft_total, d = shaft_d, $fn = 24);

        // 軸受けホルダー（シャフト根元の円盤）
        color("silver")
        translate([0, 0, -bearing_holder_h])
            cylinder(h = bearing_holder_h, d = bearing_holder_d, $fn = 32);

        // ハウジング（軸受けホルダーの下から開始）
        housing_top_z = -bearing_holder_h;
        color("silver")
        translate([0, 0, housing_top_z - len])
            if (type == "FA-130") {
                linear_extrude(len)
                    _fa130_housing_2d();
            } else {
                cylinder(h = len, d = w, $fn = 48);
            }

        // 後部軸受けホルダー（金属ハウジング端、ハウジング内側に配置）
        rear_bearing_h = 1.7;
        color("silver")
        translate([0, 0, housing_top_z - len])
            cylinder(h = rear_bearing_h, d = rear_bearing_d, $fn = 32);

        // エンドキャップ（プラスチック、金属ハウジングに直接接続）
        color([1, 0.95, 0.8])  // クリーム色
        translate([0, 0, housing_top_z - len - cap_len])
            if (type == "FA-130") {
                linear_extrude(cap_len)
                    _fa130_housing_2d();
            } else {
                cylinder(h = cap_len, d = w, $fn = 48);
            }

        // ブラシカバー出っ張り（端子側中央の丸い突起）
        cap_bottom_z = housing_top_z - len - cap_len;
        color([1, 0.95, 0.8])  // クリーム色
        translate([0, 0, cap_bottom_z - brush_cover_h])
            cylinder(h = brush_cover_h, d = brush_cover_d, $fn = 32);

        if (type == "FA-130") {
            // FA-130: 端子用出っ張り（フラット面側から突出）
            // データシートより端子はフラット面の片側から外に出ている
            // 上から見て下側（Y-方向）に配置
            cap_center_z = cap_bottom_z + cap_len / 2;  // エンドキャップ中心のZ位置

            // 端子出っ張り（フラット面から1.04mm突出）
            color([1, 0.95, 0.8])  // クリーム色
            translate([0, -h/2 - terminal_bump_d/2, cap_center_z])
                cube([terminal_bump_w, terminal_bump_d, terminal_bump_h], center = true);

            // 端子（出っ張りから斜め外側に出る）
            color("gold")
            translate([0, -h/2 - terminal_bump_d - 0.5, cap_center_z])
                rotate([30, 0, 0]) {  // 斜め下方向（Y-方向に傾斜）
                    for (dx = [-2, 2]) {
                        translate([dx, 0, 0])
                            rotate([90, 0, 0])
                                cylinder(h = terminal_len, d = 1, $fn = 12);
                    }
                }
        } else {
            // RE-260/280: 端子
            color("gold")
            translate([0, 0, -len - cap_len - brush_cover_h - terminal_len]) {
                terminal_spacing = 8;
                for (x = [-terminal_spacing/2, terminal_spacing/2]) {
                    translate([x, 0, 0])
                        cylinder(h = terminal_len, d = 1, $fn = 12);
                }
            }
        }
    }
}

// 便利モジュール
module fa130_motor() { mabuchi_motor("FA-130"); }
module re260_motor() { mabuchi_motor("RE-260"); }
module re280_motor() { mabuchi_motor("RE-280"); }

// ===== モーターマウント用カットアウト =====

// マウント用カットアウト（difference用）
// 原点: モーター挿入口の中心（シャフト側）
// +Z 方向に掘り込み
module mabuchi_motor_mount_cutout(type = "FA-130", depth = undef, tolerance = default_tolerance) {
    specs = mabuchi_motor_specs(type);

    if (is_undef(specs)) {
        echo(str("ERROR: Unknown motor type: ", type));
    } else {
        w = specs[0];
        h = specs[1];
        len = specs[2];

        actual_depth = is_undef(depth) ? len + 4 : depth;  // ハウジング + キャップ

        translate([0, 0, -0.1])
        linear_extrude(actual_depth + 0.2)
            if (type == "FA-130") {
                _fa130_housing_2d(tolerance);
            } else {
                _cylinder_housing_2d(w, tolerance);
            }
    }
}

// 便利モジュール
module fa130_mount_cutout(depth = undef, tolerance = default_tolerance) {
    mabuchi_motor_mount_cutout("FA-130", depth, tolerance);
}
module re260_mount_cutout(depth = undef, tolerance = default_tolerance) {
    mabuchi_motor_mount_cutout("RE-260", depth, tolerance);
}
module re280_mount_cutout(depth = undef, tolerance = default_tolerance) {
    mabuchi_motor_mount_cutout("RE-280", depth, tolerance);
}

// ===== はめ込み式モーターマウント =====

// はめ込み式マウント
// 原点: 底面中心
// モーターは上から挿入（-Z 方向）
module mabuchi_motor_mount(type = "FA-130", wall = 2, base = 3, tolerance = default_tolerance) {
    specs = mabuchi_motor_specs(type);

    if (is_undef(specs)) {
        echo(str("ERROR: Unknown motor type: ", type));
    } else {
        w = specs[0];
        h = specs[1];
        len = specs[2];
        shaft_d = specs[3];

        // マウント外形
        outer_w = w + tolerance + wall * 2;
        outer_h = (type == "FA-130") ? h + tolerance + wall * 2 : outer_w;
        mount_height = len + 4 + base;  // ハウジング + キャップ + ベース

        difference() {
            // 外形
            if (type == "FA-130") {
                linear_extrude(mount_height)
                    intersection() {
                        circle(d = outer_w, $fn = 48);
                        square([outer_w, outer_h], center = true);
                    }
            } else {
                cylinder(h = mount_height, d = outer_w, $fn = 48);
            }

            // モーター収納部
            translate([0, 0, base])
                mabuchi_motor_mount_cutout(type, len + 4 + 0.1, tolerance);

            // シャフト穴
            translate([0, 0, -0.1])
                cylinder(h = base + 0.2, d = shaft_d + 1, $fn = 24);
        }
    }
}

// 便利モジュール
module fa130_mount(wall = 2, base = 3, tolerance = default_tolerance) {
    mabuchi_motor_mount("FA-130", wall, base, tolerance);
}
module re260_mount(wall = 2, base = 3, tolerance = default_tolerance) {
    mabuchi_motor_mount("RE-260", wall, base, tolerance);
}
module re280_mount(wall = 2, base = 3, tolerance = default_tolerance) {
    mabuchi_motor_mount("RE-280", wall, base, tolerance);
}

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

// モータータイプ別カップラー
module mabuchi_shaft_coupler(type = "FA-130", outer_d = 8, length = 10,
                              tolerance = default_shaft_tolerance,
                              with_slit = false, slit_width = 1) {
    shaft_d = mabuchi_shaft_d(type);

    if (is_undef(shaft_d)) {
        echo(str("ERROR: Unknown motor type: ", type));
    } else {
        shaft_coupler(shaft_d, outer_d, length, tolerance, with_slit, slit_width);
    }
}
