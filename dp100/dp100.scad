// DP100 実験用安定化電源装置ライブラリ
//
// フィットチェック用モデルと台座・治具作成のためのモジュール群
//
// 依存: BOSL2
//
// 座標系:
//   原点: 底面の左前角（出力端子側・手前）
//   X軸: 長辺方向（+X が入力側へ）
//   Y軸: 短辺方向（+Y が奥）
//   Z軸: 高さ方向（+Z が上）
//
//            Y+（奥）
//            ↑
//            │  ディスプレイ面（斜め）
//            │  ┌─────────────────────┐
//            │  │                     │
//  出力端子 ───│                     │─── 入力端子
//  (バナナ)   ───│                     │─── (Type-C/A)
//            │  │                     │
//            │  └─────────────────────┘
//            原点(0,0,0)              → X+ (100.4mm)

include <BOSL2/std.scad>

// ========================================
// DP100 寸法定数
// ========================================

// 外形寸法
dp100_length = 100.4;  // 長辺（X方向）
dp100_width = 62.2;    // 短辺（Y方向）
dp100_height = 17.2;   // 高さ（Z方向）

// フィレット
dp100_corner_r = 3;    // 四隅の角丸半径

// 斜め面（操作パネル）
// 注意: 角度ではなく寸法で指定することで、実測値との一致を確認しやすい
// - 天面の奥行き（実測）: 51mm
// - 垂直部分の高さ（実測）: 6mm
// これらから切り欠き量と角度を計算で導出する
dp100_top_depth = 51;    // 天面の短辺（Y方向）
dp100_panel_start_z = 6; // 斜め面が始まる高さ（底面から）
// 計算値
dp100_panel_cutback = dp100_width - dp100_top_depth;  // 前面が後退する量 = 11.2mm
dp100_panel_angle = atan(dp100_panel_cutback / (dp100_height - dp100_panel_start_z));  // ≈ 45°

// 端子寸法（概算）
usb_c_width = 9;
usb_c_height = 3.5;
usb_a_width = 12;
usb_a_height = 5;
banana_d = 8;          // バナナジャック直径

// デフォルト公差
default_tolerance = 0.3;

// ========================================
// dp100() - フィットチェック用モデル
// ========================================

module dp100() {
    // 本体色
    body_color = [0.2, 0.2, 0.2];  // ダークグレー

    color(body_color) {
        difference() {
            // Step 1-2: フィレット付き直方体
            cuboid(
                [dp100_length, dp100_width, dp100_height],
                rounding = dp100_corner_r,
                edges = "Z",
                anchor = BOTTOM + LEFT + FRONT
            );

            // Step 3: 前面斜め切り抜き
            // Y=0（前面）側の上部を斜めにカット
            //
            // rotate() + cube() だと座標計算が複雑になるため、
            // polyhedron で頂点座標を直接指定して三角柱を作成。
            // 面の頂点順序は外側から見て反時計回り（CCW）にすること。
            // 順序が間違っていると difference() が正しく動作しない。
            polyhedron(
                points = [
                    // 左端の三角形 (X = -1)
                    [-1, -1, dp100_panel_start_z],                          // 0: 前面下
                    [-1, -1, dp100_height + 1],                             // 1: 前面上
                    [-1, dp100_panel_cutback + 1, dp100_height + 1],        // 2: 後方上
                    // 右端の三角形 (X = dp100_length + 1)
                    [dp100_length + 1, -1, dp100_panel_start_z],            // 3: 前面下
                    [dp100_length + 1, -1, dp100_height + 1],               // 4: 前面上
                    [dp100_length + 1, dp100_panel_cutback + 1, dp100_height + 1]  // 5: 後方上
                ],
                faces = [
                    [0, 2, 1],       // 左三角形（-X から見て CCW）
                    [3, 4, 5],       // 右三角形（+X から見て CCW）
                    [0, 1, 4, 3],    // 前面（-Y から見て CCW）
                    [1, 2, 5, 4],    // 上面（+Z から見て CCW）
                    [0, 3, 5, 2]     // 斜め面（切り抜き面、下向き法線）
                ]
            );
        }
    }

    // ディスプレイ領域（斜め面上）
    _dp100_display();

    // 端子（両側面）
    _dp100_terminals();
}

// ========================================
// 内部モジュール（プライベート）
// ========================================

// ディスプレイ領域
//
// 【斜め面への配置の考え方】
// 1. 斜め面の中心座標を計算
// 2. 斜め面の外向き法線方向を計算: (-sin(angle), cos(angle)) in YZ
// 3. 法線方向にオフセットして、オブジェクトが表面に「乗る」ようにする
//    （オフセットなしだと中心が面上になり、オブジェクトの半分が埋まる）
// 4. 斜め面の角度に合わせて回転
//
// よくある間違い:
// - 法線方向のオフセットを忘れる → オブジェクトが面に埋まる
// - 回転角度の符号を間違える → オブジェクトが面に垂直に刺さる
// - XY平面の板を作って回転するのが簡単（XZ平面だと回転後の向きが直感的でない）
//
module _dp100_display() {
    display_color = [0.15, 0.15, 0.15];  // 黒っぽい色（液晶OFF状態）
    display_width = 33.5;   // ディスプレイ幅（X方向）
    display_thickness = 0.5;
    display_margin_left = 5;  // 左端からディスプレイまでの距離

    // 斜め面の情報
    // 斜め面は (Y=0, Z=dp100_panel_start_z) から (Y=dp100_panel_cutback, Z=dp100_height) へ
    slope_length = sqrt(dp100_panel_cutback * dp100_panel_cutback +
                        (dp100_height - dp100_panel_start_z) * (dp100_height - dp100_panel_start_z));
    display_height_on_slope = slope_length * 0.6;  // 斜面の60%をディスプレイに

    // ディスプレイ中心位置（斜面の中央）
    slope_center_y = dp100_panel_cutback / 2;
    slope_center_z = (dp100_panel_start_z + dp100_height) / 2;

    // X方向は左寄り（左端から5mm）
    display_x = display_margin_left;

    // ディスプレイを斜め面に沿わせる
    // 斜め面の外向き法線方向: (-sin(angle), cos(angle)) in YZ
    // 表面に乗せるため、法線方向にオフセット
    normal_y = -sin(dp100_panel_angle);
    normal_z = cos(dp100_panel_angle);
    surface_offset = display_thickness / 2 + 0.1;  // 表面より少し外側に

    color(display_color)
        translate([display_x,
                   slope_center_y + normal_y * surface_offset,
                   slope_center_z + normal_z * surface_offset])
            rotate([dp100_panel_angle, 0, 0])
                translate([0, -display_height_on_slope/2, 0])
                    cube([display_width, display_height_on_slope, display_thickness]);
}

// 端子類
module _dp100_terminals() {
    banana_protrusion = 5.5;  // バナナプラグの突出量
    usb_protrusion = 2;       // USB端子の突出量

    // 出力側（X=0、左短辺）: バナナジャック
    banana_color_plus = "red";
    banana_color_minus = "black";
    banana_spacing = 20;
    banana_z = dp100_height / 2;
    banana_y = dp100_width / 2;

    // バナナジャック +
    color(banana_color_plus)
        translate([-banana_protrusion, banana_y - banana_spacing/2, banana_z])
            rotate([0, 90, 0])
                cylinder(h = banana_protrusion + 1, d = banana_d, $fn = 24);

    // バナナジャック -
    color(banana_color_minus)
        translate([-banana_protrusion, banana_y + banana_spacing/2, banana_z])
            rotate([0, 90, 0])
                cylinder(h = banana_protrusion + 1, d = banana_d, $fn = 24);

    // 入力側（X=100.4、右短辺）: USB Type-C + Type-A
    usb_color = [0.3, 0.3, 0.3];  // グレー
    usb_z = dp100_height / 2;

    // USB Type-C（上側）
    color(usb_color)
        translate([dp100_length - 1, dp100_width/2 - 10, usb_z + 3])
            rotate([0, 90, 0])
                cube([usb_c_height, usb_c_width, usb_protrusion + 2], center = true);

    // USB Type-A（下側）
    color(usb_color)
        translate([dp100_length - 1, dp100_width/2 + 8, usb_z - 2])
            rotate([0, 90, 0])
                cube([usb_a_height, usb_a_width, usb_protrusion + 2], center = true);
}

// ========================================
// dp100_footprint() - 2D フットプリント
// ========================================

module dp100_footprint(tolerance = 0) {
    offset(r = tolerance)
        square([dp100_length, dp100_width]);
}

// ========================================
// dp100_cutout() - カットアウト（difference用）
// ========================================

module dp100_cutout(tolerance = default_tolerance, depth = 10) {
    linear_extrude(height = depth)
        dp100_footprint(tolerance = tolerance);
}

// ========================================
// dp100_stand() - シンプルな台座
// ========================================

module dp100_stand(
    tolerance = default_tolerance,
    wall = 2,
    base = 2,
    lip_height = 5,
    end_opening = true  // 端子側を開放するか
) {
    inner_length = dp100_length + tolerance * 2;
    inner_width = dp100_width + tolerance * 2;

    outer_length = inner_length + wall * 2;
    outer_width = inner_width + wall * 2;
    total_height = base + lip_height;

    difference() {
        // 外形
        cube([outer_length, outer_width, total_height]);

        // 内側くり抜き（DP100収納部）
        translate([wall, wall, base])
            cube([inner_length, inner_width, lip_height + 1]);

        // 端子側の開口
        if (end_opening) {
            // 出力側（X=0）開口
            translate([-1, wall, base])
                cube([wall + 2, inner_width, lip_height + 1]);

            // 入力側（X=outer_length）開口
            translate([outer_length - wall - 1, wall, base])
                cube([wall + 2, inner_width, lip_height + 1]);
        }
    }
}

// ========================================
// dp100_in_stand() - 台座内のDP100（フィットチェック用）
// ========================================

module dp100_in_stand(
    tolerance = default_tolerance,
    wall = 2,
    base = 2
) {
    translate([wall + tolerance, wall + tolerance, base])
        dp100();
}

// ========================================
// スタンドアロン実行時のプレビュー
// ========================================

// include された場合は _dp100_included が定義されている
if (is_undef(_dp100_included)) {
    dp100();
}
