// DP100 実験用安定化電源装置ライブラリ
//
// フィットチェック用モデルと台座・治具作成のためのモジュール群
//
// 依存: BOSL2, NopSCADlib
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
//            原点(0,0,0)              → X+ (94mm)

include <BOSL2/std.scad>
include <NopSCADlib/vitamins/pcb.scad>

// ========================================
// DP100 寸法定数
// ========================================

// 外形寸法
dp100_length = 94;  // 長辺（X方向）※バナナプラグ込みで約100.4mm
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
dp100_panel_cutback = dp100_width - dp100_top_depth;  // 前面が後退する量（Y方向）= 11.2mm
dp100_panel_height = dp100_height - dp100_panel_start_z;  // 斜め面の垂直方向高さ（Z方向）= 11.2mm
dp100_panel_slope_length = sqrt(dp100_panel_cutback * dp100_panel_cutback + dp100_panel_height * dp100_panel_height);  // 斜め辺の長さ ≈ 15.84mm
// 三角関数の値を斜め辺から直接計算（整合性確保）
dp100_panel_sin = dp100_panel_cutback / dp100_panel_slope_length;  // sin(角度)
dp100_panel_cos = dp100_panel_height / dp100_panel_slope_length;   // cos(角度)
dp100_panel_angle = atan2(dp100_panel_cutback, dp100_panel_height);  // 角度（度）≈ 45°

// 端子寸法
// USB コネクタは NopSCADlib のモジュールを使用（usb_C(), usb_Ax1()）
banana_d = 8;          // バナナジャック直径

// ゴム足寸法（取り外し可能）
rubber_foot_d = 9;     // ゴム足直径
rubber_foot_h = 1.5;   // ゴム足高さ
// 配置: 下部四隅
// - 奥側面から外周まで: 2.5mm
// - 手前側面から外周まで: 13mm
// - 横側面から外周まで: 2.5mm
rubber_foot_margin_back = 2.5;   // 奥側面からの距離
rubber_foot_margin_front = 13;   // 手前側面からの距離
rubber_foot_margin_side = 2.5;   // 横側面からの距離

// デフォルト公差
default_tolerance = 0.3;

// ========================================
// dp100() - フィットチェック用モデル
// ========================================

module dp100(show_feet = true) {
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
            // 斜面を正しい角度で延長するため、底面のZ座標を調整
            // Y=-1 での斜面延長位置: Z = panel_start_z + (-1) * (panel_height / panel_cutback)
            cut_margin = 1;  // 本体からの延長マージン
            cut_bottom_z = dp100_panel_start_z - cut_margin * dp100_panel_height / dp100_panel_cutback;
            polyhedron(
                points = [
                    // 左端の三角形 (X = -1)
                    [-cut_margin, -cut_margin, cut_bottom_z],               // 0: 前面下（斜面延長上）
                    [-cut_margin, -cut_margin, dp100_height + cut_margin],  // 1: 前面上
                    [-cut_margin, dp100_panel_cutback + cut_margin, dp100_height + cut_margin],  // 2: 後方上
                    // 右端の三角形 (X = dp100_length + cut_margin)
                    [dp100_length + cut_margin, -cut_margin, cut_bottom_z], // 3: 前面下（斜面延長上）
                    [dp100_length + cut_margin, -cut_margin, dp100_height + cut_margin],  // 4: 前面上
                    [dp100_length + cut_margin, dp100_panel_cutback + cut_margin, dp100_height + cut_margin]  // 5: 後方上
                ],
                faces = [
                    [0, 2, 1],       // 左三角形（-X から見て CCW）
                    [3, 4, 5],       // 右三角形（+X から見て CCW）
                    [0, 1, 4, 3],    // 前面（-Y から見て CCW）
                    [1, 2, 5, 4],    // 上面（+Z から見て CCW）
                    [0, 3, 5, 2]     // 斜め面（切り抜き面、下向き法線）
                ]
            );

            // USB コネクタ用カットアウト（メスコネクタを埋め込むための空洞）
            // NopSCADlib の cutout=true は非常に長いカットアウトを生成するため、
            // intersection() で本体右半分のみに制限する
            // 位置は _dp100_terminals() と同じにすること
            //
            // 実測値:
            //   - コネクタ底面高さ: 5mm
            //   - Type-A 手前側〜本体手前: 20mm
            //   - Type-A 奥側〜Type-C 手前側の間隔: 9.5mm
            usb_bottom_z = 5;
            usb_a_w = 13.25;  // NopSCADlib usb_Ax1 の幅
            usb_c_w = 8.94;   // NopSCADlib usb_C の幅
            usb_a_y = 20 + usb_a_w/2;  // Type-A 中心 Y
            usb_c_y = 20 + usb_a_w + 9.5 + usb_c_w/2;  // Type-C 中心 Y
            usb_cutout_depth = 30;  // カットアウトの最大深さ

            // USB Type-A（手前側）- カットアウト深さを制限
            intersection() {
                translate([dp100_length - usb_cutout_depth, 0, 0])
                    cube([usb_cutout_depth + 1, dp100_width, dp100_height]);
                translate([dp100_length + 0.1, usb_a_y, usb_bottom_z])
                    rotate([0, 0, 180])
                        usb_Ax1(cutout = true);
            }

            // USB Type-C（奥側）- カットアウト深さを制限
            intersection() {
                translate([dp100_length - usb_cutout_depth, 0, 0])
                    cube([usb_cutout_depth + 1, dp100_width, dp100_height]);
                translate([dp100_length + 0.1, usb_c_y, usb_bottom_z])
                    rotate([0, 0, 180])
                        usb_C(cutout = true);
            }
        }
    }

    // ディスプレイ領域（斜め面上）
    _dp100_display();

    // 端子（両側面）
    _dp100_terminals();

    // ゴム足（オプション）
    if (show_feet) {
        _dp100_rubber_feet();
    }
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

    // ディスプレイ高さ: 斜め辺の長さから上下0.2mmずつ小さい
    display_margin = 0.2;
    display_height_on_slope = dp100_panel_slope_length - display_margin * 2;

    // ディスプレイ中心位置（斜面の中央）
    slope_center_y = dp100_panel_cutback / 2;
    slope_center_z = (dp100_panel_start_z + dp100_height) / 2;

    // X方向は左寄り（左端から5mm）
    display_x = display_margin_left;

    // ディスプレイを斜め面に沿わせる
    // 斜め面の外向き法線方向: (-sin, cos) in YZ
    // 表面に乗せるため、法線方向にオフセット
    // 事前計算された sin/cos を使用して整合性を確保
    normal_y = -dp100_panel_sin;
    normal_z = dp100_panel_cos;
    surface_offset = display_thickness / 2;  // 表面に接触

    // ディスプレイを中央に配置してから回転
    // 回転はディスプレイの中心を軸に行う
    color(display_color)
        translate([display_x,
                   slope_center_y + normal_y * surface_offset,
                   slope_center_z + normal_z * surface_offset])
            rotate([dp100_panel_angle, 0, 0])
                translate([0, -display_height_on_slope/2, -display_thickness/2])
                    cube([display_width, display_height_on_slope, display_thickness]);
}

// 端子類
module _dp100_terminals() {
    // 出力側（X=0、左短辺）: バナナジャック
    // シンプルな円柱で表現
    banana_protrusion = 5.5;  // バナナプラグの突出量
    banana_color_plus = "red";
    banana_color_minus = "black";
    banana_spacing = 20;
    banana_z = dp100_height / 2;
    banana_y = dp100_width / 2;

    // バナナジャック +（手前側）
    color(banana_color_plus)
        translate([-banana_protrusion, banana_y - banana_spacing/2, banana_z])
            rotate([0, 90, 0])
                cylinder(h = banana_protrusion + 1, d = banana_d, $fn = 24);

    // バナナジャック -（奥側）
    color(banana_color_minus)
        translate([-banana_protrusion, banana_y + banana_spacing/2, banana_z])
            rotate([0, 90, 0])
                cylinder(h = banana_protrusion + 1, d = banana_d, $fn = 24);

    // 入力側（X=94、右短辺）: USB Type-C + Type-A（メスコネクタ）
    // NopSCADlib のモジュールを使用
    // メスコネクタなので本体に埋め込む（本体側でカットアウト済み）
    //
    // 実測値:
    //   - コネクタ底面高さ: 5mm
    //   - Type-A 手前側〜本体手前: 20mm
    //   - Type-A 奥側〜Type-C 手前側の間隔: 9.5mm

    // 共通設定
    usb_bottom_z = 5;
    usb_a_w = 13.25;  // NopSCADlib usb_Ax1 の幅
    usb_c_w = 8.94;   // NopSCADlib usb_C の幅
    usb_a_y = 20 + usb_a_w/2;  // Type-A 中心 Y
    usb_c_y = 20 + usb_a_w + 9.5 + usb_c_w/2;  // Type-C 中心 Y

    // USB Type-A（手前側）
    usb_a_depth = 17;
    translate([dp100_length - usb_a_depth/2, usb_a_y, usb_bottom_z])
        usb_Ax1();

    // USB Type-C（奥側）
    usb_c_depth = 7.35;
    translate([dp100_length - usb_c_depth/2, usb_c_y, usb_bottom_z])
        usb_C();
}

// ゴム足（下部四隅）
module _dp100_rubber_feet() {
    foot_color = [0.3, 0.3, 0.3];  // ダークグレー（本体より少し明るい）
    r = rubber_foot_d / 2;

    // 中心座標の計算
    // 外周からの距離なので、中心 = margin + radius
    x_left = rubber_foot_margin_side + r;
    x_right = dp100_length - rubber_foot_margin_side - r;
    y_front = rubber_foot_margin_front - r;  // 手前: 外周が13mmの位置
    y_back = dp100_width - rubber_foot_margin_back - r;

    color(foot_color) {
        // 手前左
        translate([x_left, y_front, -rubber_foot_h])
            cylinder(h = rubber_foot_h, d = rubber_foot_d, $fn = 24);
        // 手前右
        translate([x_right, y_front, -rubber_foot_h])
            cylinder(h = rubber_foot_h, d = rubber_foot_d, $fn = 24);
        // 奥左
        translate([x_left, y_back, -rubber_foot_h])
            cylinder(h = rubber_foot_h, d = rubber_foot_d, $fn = 24);
        // 奥右
        translate([x_right, y_back, -rubber_foot_h])
            cylinder(h = rubber_foot_h, d = rubber_foot_d, $fn = 24);
    }
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
    corner_r = dp100_corner_r  // DP100と同じ角丸半径
) {
    inner_length = dp100_length + tolerance * 2;
    inner_width = dp100_width + tolerance * 2;
    inner_r = corner_r + tolerance;  // 内側の角丸（DP100が入る）

    outer_length = inner_length + wall * 2;
    outer_width = inner_width + wall * 2;
    outer_r = inner_r + wall;  // 外側の角丸
    total_height = base + lip_height;

    // 端子開口の寸法と位置
    // バナナジャック: Y = dp100_width/2 ± 10mm (spacing=20mm)
    banana_center_y = dp100_width / 2;  // 31.1mm
    banana_spacing = 20;
    banana_margin = 5;  // ジャック周りの余裕
    banana_opening_w = banana_spacing + banana_d + banana_margin * 2;  // 20+8+10=38mm
    banana_opening_h = banana_d + banana_margin * 2;  // 8+10=18mm
    banana_opening_y = wall + tolerance + banana_center_y - banana_opening_w/2;

    // USB: Type-A (Y=20〜33.25) + Type-C (Y=42.75〜51.69)
    // コネクタ持ち手部分の余裕を考慮（約2.5mm）
    usb_start_y = 14;   // Type-A 手前側に余裕を持たせる
    usb_end_y = 57;     // Type-C 奥側 + 持ち手余裕（51.69 + 5.3mm）
    usb_opening_w = usb_end_y - usb_start_y;  // 43mm
    usb_opening_h = 14;  // USB コネクタ高さ + 余裕
    usb_opening_y = wall + tolerance + usb_start_y;

    difference() {
        // 外形（フィレット付き）
        cuboid(
            [outer_length, outer_width, total_height],
            rounding = outer_r,
            edges = "Z",
            anchor = BOTTOM + LEFT + FRONT
        );

        // 内側くり抜き（DP100収納部、フィレット付き）
        translate([wall, wall, base])
            cuboid(
                [inner_length, inner_width, lip_height + 1],
                rounding = inner_r,
                edges = "Z",
                anchor = BOTTOM + LEFT + FRONT
            );

        // 出力側（X=0）開口：バナナジャック用
        translate([-1, banana_opening_y, base])
            cube([wall + 2, banana_opening_w, banana_opening_h]);

        // 入力側（X=outer_length）開口：USB用
        translate([outer_length - wall - 1, usb_opening_y, base])
            cube([wall + 2, usb_opening_w, usb_opening_h]);

        // ゴム足用凹み（底面に4箇所）
        // クリアランス: 直径+1mm
        // 深さ: ゴム足高さ + 0.3mm（ただし底面に最低0.4mm残す）
        foot_recess_d = rubber_foot_d + 1;
        min_floor = 0.4;  // 底面の最小厚さ（印刷用に2層分）
        foot_recess_depth = min(rubber_foot_h + 0.3, base - min_floor);
        foot_r = rubber_foot_d / 2;

        // ゴム足中心座標（DP100ローカル座標）
        foot_x_left = rubber_foot_margin_side + foot_r;
        foot_x_right = dp100_length - rubber_foot_margin_side - foot_r;
        foot_y_front = rubber_foot_margin_front - foot_r;
        foot_y_back = dp100_width - rubber_foot_margin_back - foot_r;

        // スタンド座標に変換
        foot_offset_x = wall + tolerance;
        foot_offset_y = wall + tolerance;

        // 手前左
        translate([foot_offset_x + foot_x_left, foot_offset_y + foot_y_front, base - foot_recess_depth])
            cylinder(h = foot_recess_depth + 0.1, d = foot_recess_d, $fn = 24);
        // 手前右
        translate([foot_offset_x + foot_x_right, foot_offset_y + foot_y_front, base - foot_recess_depth])
            cylinder(h = foot_recess_depth + 0.1, d = foot_recess_d, $fn = 24);
        // 奥左
        translate([foot_offset_x + foot_x_left, foot_offset_y + foot_y_back, base - foot_recess_depth])
            cylinder(h = foot_recess_depth + 0.1, d = foot_recess_d, $fn = 24);
        // 奥右
        translate([foot_offset_x + foot_x_right, foot_offset_y + foot_y_back, base - foot_recess_depth])
            cylinder(h = foot_recess_depth + 0.1, d = foot_recess_d, $fn = 24);
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
