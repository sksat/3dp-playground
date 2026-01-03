// Heat-Set Insert Library
// ヒートセットインサート用穴生成ライブラリ
//
// 提供モジュール:
//   insert_hole(size, length, tolerance, extra_depth)
//   m2_insert_hole(), m2p5_insert_hole(), m3_insert_hole()
//
// 対応サイズ: M2, M2.5, M3
// 参考: CNC Kitchen specifications
//       https://www.cnckitchen.com/blog/tipps-amp-tricks-fr-gewindeeinstze-im-3d-druck-3awey
//
// 使用例:
//   difference() {
//       cylinder(h = 10, d = 8, $fn = 24);  // ボス
//       translate([0, 0, 10])
//           insert_hole("M3");              // インサート穴
//   }

// ===== ヒートセットインサート寸法テーブル =====
// [外径, 推奨穴径, 長さ]

function m2_insert_table(length) =
    length == "short"    ? [3.6, 3.2, 3.0] :
    length == "standard" ? [3.6, 3.2, 3.0] :
    is_num(length) ? [3.6, 3.2, length] :
    undef;

function m2p5_insert_table(length) =
    length == "short"    ? [4.6, 4.0, 4.0] :
    length == "standard" ? [4.6, 4.0, 4.0] :
    length == "long"     ? [5.0, 4.0, 5.7] :
    is_num(length) ? [4.6, 4.0, length] :
    undef;

function m3_insert_table(length) =
    length == "short"    ? [4.6, 4.0, 3.0] :
    length == "standard" ? [4.6, 4.4, 4.0] :
    length == "long"     ? [5.0, 4.0, 5.7] :
    is_num(length) ? [4.6, 4.2, length] :
    undef;

// 統合ルックアップ関数
// 戻り値: [外径, 穴径, 長さ]
function insert_specs(size, length = "standard") =
    size == "M2"   ? m2_insert_table(length) :
    size == "M2.5" ? m2p5_insert_table(length) :
    size == "M3"   ? m3_insert_table(length) :
    undef;

// ボス径の推奨値（インサート外径 + 肉厚 * 2）
function insert_boss_d(size, wall = 2) =
    let(specs = insert_specs(size))
    is_undef(specs) ? 0 : specs[0] + wall * 2;

// ===== モジュール =====

// インサート穴（difference用）
// 原点はボス上面、穴は下方向（-Z）に掘る
module insert_hole(size = "M3", length = "standard", tolerance = 0, extra_depth = 1) {
    specs = insert_specs(size, length);

    if (is_undef(specs)) {
        echo(str("ERROR: Invalid insert size '", size, "' or length '", length, "'"));
    } else {
        hole_d = specs[1] + tolerance;
        insert_length = specs[2];
        total_depth = insert_length + extra_depth;

        // 穴を掘る（上面から下へ、Z-fighting回避のため+0.1）
        translate([0, 0, -total_depth])
            cylinder(h = total_depth + 0.1, d = hole_d, $fn = 24);
    }
}

// M2専用
module m2_insert_hole(length = "standard", tolerance = 0, extra_depth = 1) {
    insert_hole("M2", length, tolerance, extra_depth);
}

// M2.5専用
module m2p5_insert_hole(length = "standard", tolerance = 0, extra_depth = 1) {
    insert_hole("M2.5", length, tolerance, extra_depth);
}

// M3専用
module m3_insert_hole(length = "standard", tolerance = 0, extra_depth = 1) {
    insert_hole("M3", length, tolerance, extra_depth);
}
