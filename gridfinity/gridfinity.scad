// Gridfinity Library
// Gridfinity モジュラー収納システム用ライブラリ
//
// 提供モジュール:
//   gridfinity_baseplate(units_x, units_y) - ベースプレート生成
//   gridfinity_bin(units_x, units_y, units_z) - ビン（箱）生成
//
// Gridfinity 仕様:
//   グリッドユニット: 42mm x 42mm
//   高さユニット: 7mm (1U)
//   マグネット: 6mm径 x 2mm厚
//   ネジ: M3
//
// 参考:
//   Gridfinity 公式: https://gridfinity.xyz/
//   Gridfinity 仕様: https://github.com/gridfinity-unofficial/specification

// ===== 基本寸法 =====

// グリッド寸法
grid_unit = 42;               // 1グリッドのサイズ (mm)
height_unit = 7;              // 高さユニット (mm)
bin_clearance = 0.5;          // ビンとベースプレートのクリアランス
bin_size = grid_unit - bin_clearance;  // ビンの実サイズ (41.5mm)

// ベースプレートプロファイル
baseplate_wall_h = 4.65;      // ベースプレート壁の高さ
baseplate_fillet = 4.0;       // ベースプレート角のフィレット半径
baseplate_bottom_h = 2.6;     // ベースプレート底部の厚み

// ビンプロファイル
bin_fillet = 3.75;            // ビン角のフィレット半径
bin_base_h = 4.75;            // ビンベースの高さ（7mm中）

// スタッキングリップ
lip_h = 4.4;                  // リップ高さ
lip_angle = 45;               // リップ傾斜角度

// マグネット・ネジ穴
magnet_d = 6.0;               // マグネット直径
magnet_h = 2.0;               // マグネット厚さ
magnet_clearance = 0.2;       // マグネット穴のクリアランス
screw_d = 3.0;                // M3ネジ直径
screw_clearance = 0.2;        // ネジ穴のクリアランス

// マグネット/ネジ穴の位置（グリッド中心からのオフセット）
hole_offset = 13.0;           // コーナー穴位置（グリッド中心から）

// ===== ベースプレートプロファイル =====
// 階段状の壁プロファイル（断面）
// Z=0 が底面、X が壁からの距離

// ベースプレートの壁プロファイル（2D断面）
// 原点は壁の内側下端
module baseplate_wall_profile_2d() {
    // 階段状プロファイル（実測値に基づく近似）
    // 下から: 底部 → 傾斜 → 上部棚
    polygon([
        [0, 0],
        [0, 0.8],              // 垂直立ち上がり
        [1.6, 2.15],           // 45°傾斜
        [1.6, 2.15 + 0.8],     // 垂直
        [2.6, 3.75 + 0.1],     // 45°傾斜
        [2.6, baseplate_wall_h],  // 上端
        [4.0, baseplate_wall_h],  // 上面
        [4.0, 0]               // 外側
    ]);
}

// 単一グリッドセルの壁形状（中心原点）
module baseplate_cell_walls(size = grid_unit) {
    half = size / 2;
    fillet = baseplate_fillet;

    // 4辺の壁を生成
    // rotate([90, 0, 0]): profile Y→Z（高さ）, extrusion Z→-Y（壁の長さ方向）
    for (angle = [0, 90, 180, 270]) {
        rotate([0, 0, angle])
        translate([half - 4.0, half - fillet, 0])
            rotate([90, 0, 0])
                linear_extrude(height = size - fillet * 2)
                    baseplate_wall_profile_2d();
    }

    // 4隅の角丸部分
    // rotate_extrude(angle=90): θ=0→90 へ反時計回り掃引
    // 各コーナーの回転角: [1,1]→0°, [-1,1]→90°, [-1,-1]→180°, [1,-1]→270°
    for (corner = [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
        cx = corner[0] * (half - fillet);
        cy = corner[1] * (half - fillet);
        corner_angle =
            (corner[0] > 0 && corner[1] > 0) ? 0 :
            (corner[0] < 0 && corner[1] > 0) ? 90 :
            (corner[0] < 0 && corner[1] < 0) ? 180 : 270;

        translate([cx, cy, 0])
            rotate([0, 0, corner_angle])
                rotate_extrude(angle = 90, $fn = 24)
                    baseplate_wall_profile_2d();
    }
}

// 単一グリッドセル（底板 + 壁）
module baseplate_cell(magnets = true, screws = false) {
    half = grid_unit / 2;
    fillet = baseplate_fillet;

    // 底板
    linear_extrude(height = baseplate_bottom_h)
        offset(r = fillet)
            offset(r = -fillet)
                square([grid_unit, grid_unit], center = true);

    // 壁
    baseplate_cell_walls();

    // マグネット/ネジ穴のカットアウト
    if (magnets || screws) {
        for (corner = [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
            hx = corner[0] * hole_offset;
            hy = corner[1] * hole_offset;

            translate([hx, hy, 0]) {
                if (magnets) {
                    // マグネット穴
                    translate([0, 0, -0.1])
                        cylinder(h = magnet_h + 0.1,
                                d = magnet_d + magnet_clearance * 2,
                                $fn = 32);
                }
                if (screws) {
                    // ネジ穴（貫通）
                    translate([0, 0, -0.1])
                        cylinder(h = baseplate_bottom_h + baseplate_wall_h + 0.2,
                                d = screw_d + screw_clearance * 2,
                                $fn = 24);
                }
            }
        }
    }
}

// ===== ビンプロファイル =====

// ビンベースの壁プロファイル（2D断面）
// ベースプレートの凹みに嵌まる凸形状
module bin_base_profile_2d() {
    // ベースプレートの壁と対になる形状
    // 少し小さめ（クリアランス分）
    clearance = 0.1;
    polygon([
        [0, 0],
        [0, 0.7],              // 垂直立ち上がり
        [1.5, 2.0],            // 45°傾斜
        [1.5, 2.0 + 0.7],      // 垂直
        [2.4, 3.55],           // 45°傾斜
        [2.4, bin_base_h],     // 上端
        [0, bin_base_h]        // 内側
    ]);
}

// 単一ビンベース（グリッドに嵌まる部分）
module bin_base_single() {
    half = bin_size / 2;
    fillet = bin_fillet;
    wall_w = 2.4;  // プロファイル幅

    // ベース部分を回転押し出しで生成
    // rotate([90, 0, 0]): profile Y→Z（高さ）, extrusion Z→-Y
    for (angle = [0, 90, 180, 270]) {
        rotate([0, 0, angle])
        translate([half - wall_w, half - wall_w, 0])
            rotate([90, 0, 0])
                linear_extrude(height = bin_size - wall_w * 2)
                    bin_base_profile_2d();
    }

    // 4隅の角丸部分
    // コーナー中心を half - wall_w に配置（壁の外端 half と一致させる）
    // 各コーナーの回転角: [1,1]→0°, [-1,1]→90°, [-1,-1]→180°, [1,-1]→270°
    for (corner = [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
        cx = corner[0] * (half - wall_w);
        cy = corner[1] * (half - wall_w);
        corner_angle =
            (corner[0] > 0 && corner[1] > 0) ? 0 :
            (corner[0] < 0 && corner[1] > 0) ? 90 :
            (corner[0] < 0 && corner[1] < 0) ? 180 : 270;

        translate([cx, cy, 0])
            rotate([0, 0, corner_angle])
                rotate_extrude(angle = 90, $fn = 24)
                    bin_base_profile_2d();
    }

    // 中央の塗りつぶし
    linear_extrude(height = bin_base_h)
        offset(r = wall_w)
            offset(r = -wall_w)
                square([bin_size - wall_w * 2, bin_size - wall_w * 2], center = true);
}

// スタッキングリップのプロファイル（2D断面）
module lip_profile_2d() {
    // 45°傾斜のリップ
    polygon([
        [0, 0],
        [lip_h, 0],
        [lip_h, lip_h],
        [0, 0]
    ]);
}

// ===== メインモジュール =====

// ベースプレート生成
// units_x, units_y: グリッド数
// magnets: マグネット穴を追加
// screws: M3ネジ穴を追加
module gridfinity_baseplate(units_x, units_y, magnets = true, screws = false) {
    total_x = units_x * grid_unit;
    total_y = units_y * grid_unit;
    fillet = baseplate_fillet;

    difference() {
        union() {
            // 外枠（底板を含む基礎）
            linear_extrude(height = baseplate_bottom_h + baseplate_wall_h)
                offset(r = fillet)
                    offset(r = -fillet)
                        square([total_x, total_y], center = true);

            // 各セルの壁
            for (ix = [0:units_x-1]) {
                for (iy = [0:units_y-1]) {
                    cx = (ix - (units_x - 1) / 2) * grid_unit;
                    cy = (iy - (units_y - 1) / 2) * grid_unit;
                    translate([cx, cy, baseplate_bottom_h])
                        baseplate_cell_walls();
                }
            }
        }

        // 各セルの凹み（壁の内側）とマグネット/ネジ穴
        for (ix = [0:units_x-1]) {
            for (iy = [0:units_y-1]) {
                cx = (ix - (units_x - 1) / 2) * grid_unit;
                cy = (iy - (units_y - 1) / 2) * grid_unit;

                // セル内側の凹み
                translate([cx, cy, baseplate_bottom_h - 0.1])
                    linear_extrude(height = baseplate_wall_h + 0.2)
                        offset(r = fillet - 4.0)
                            offset(r = -(fillet - 4.0))
                                square([grid_unit - 8.0, grid_unit - 8.0], center = true);

                // マグネット/ネジ穴
                if (magnets || screws) {
                    for (corner = [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
                        hx = cx + corner[0] * hole_offset;
                        hy = cy + corner[1] * hole_offset;

                        translate([hx, hy, 0]) {
                            if (magnets) {
                                translate([0, 0, -0.1])
                                    cylinder(h = magnet_h + 0.2,
                                            d = magnet_d + magnet_clearance * 2,
                                            $fn = 32);
                            }
                            if (screws) {
                                translate([0, 0, -0.1])
                                    cylinder(h = baseplate_bottom_h + baseplate_wall_h + 0.2,
                                            d = screw_d + screw_clearance * 2,
                                            $fn = 24);
                            }
                        }
                    }
                }
            }
        }
    }
}

// ビン（箱）生成
// units_x, units_y: グリッド数
// units_z: 高さユニット数（7mm単位、リップは含まない）
// lip: スタッキングリップを追加
// wall_thickness: 壁の厚さ
module gridfinity_bin(units_x, units_y, units_z, lip = true, wall_thickness = 1.2) {
    total_x = units_x * grid_unit - bin_clearance;
    total_y = units_y * grid_unit - bin_clearance;
    bin_height = units_z * height_unit;
    corner_r = 2.4;  // bin_base_single の wall_w と同じ

    // 全体高さ（リップ含む）
    total_height = bin_height + (lip ? lip_h : 0);

    difference() {
        union() {
            // 各セルのベース
            for (ix = [0:units_x-1]) {
                for (iy = [0:units_y-1]) {
                    cx = (ix - (units_x - 1) / 2) * grid_unit;
                    cy = (iy - (units_y - 1) / 2) * grid_unit;
                    translate([cx, cy, 0])
                        bin_base_single();
                }
            }

            // 本体（ベースより上）
            translate([0, 0, bin_base_h])
                linear_extrude(height = bin_height - bin_base_h + (lip ? lip_h : 0))
                    offset(r = corner_r)
                        offset(r = -corner_r)
                            square([total_x, total_y], center = true);
        }

        // 内側のくり抜き（底面を残す）
        inner_x = total_x - wall_thickness * 2;
        inner_y = total_y - wall_thickness * 2;
        inner_r = max(corner_r - wall_thickness, 0.5);

        // くり抜きはベース上面から開始（壁厚分は底として残す）
        translate([0, 0, bin_base_h])
            linear_extrude(height = total_height - bin_base_h + 0.1)
                offset(r = inner_r)
                    offset(r = -inner_r)
                        square([inner_x, inner_y], center = true);

        // スタッキングリップ（上端内側を斜めにカット）
        if (lip) {
            translate([0, 0, bin_height])
                linear_extrude(height = lip_h + 0.1, scale = (total_x + lip_h * 2) / total_x)
                    offset(r = inner_r)
                        offset(r = -inner_r)
                            square([inner_x, inner_y], center = true);
        }
    }
}

// ===== シンプルなベースプレート（壁なし） =====
// 軽量版、マグネット穴のみ
module gridfinity_baseplate_simple(units_x, units_y, magnets = true) {
    total_x = units_x * grid_unit;
    total_y = units_y * grid_unit;
    fillet = baseplate_fillet;
    plate_h = baseplate_bottom_h;

    difference() {
        // 底板
        linear_extrude(height = plate_h)
            offset(r = fillet)
                offset(r = -fillet)
                    square([total_x, total_y], center = true);

        // マグネット穴
        if (magnets) {
            for (ix = [0:units_x-1]) {
                for (iy = [0:units_y-1]) {
                    cx = (ix - (units_x - 1) / 2) * grid_unit;
                    cy = (iy - (units_y - 1) / 2) * grid_unit;

                    for (corner = [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
                        hx = cx + corner[0] * hole_offset;
                        hy = cy + corner[1] * hole_offset;

                        translate([hx, hy, -0.1])
                            cylinder(h = magnet_h + 0.2,
                                    d = magnet_d + magnet_clearance * 2,
                                    $fn = 32);
                    }
                }
            }
        }
    }
}
