import Foundation

/// 見た目の確認用のデモ譜面 (音源なし)。起動画面の「デモ譜面で開く」で使う。
///
/// ファイルを用意しにくい場所 (Appetize などのシミュレータ) でも、エディタの画面をすぐ開けるようにするためのもの。
/// BPM list / Effect list にも中身が入るよう、BPM の変化と scroll / jump を入れてある。
/// 保存先は一時フォルダなので、実際の譜面には影響しない。
enum DemoChart {
    static func writeToTemp() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Demo.mc")
        try data().write(to: url, options: .atomic)
        return url
    }

    static func data() throws -> Data {
        // 拍は [整数部, 分子, 分母]。x は中心 (0...255)、w は幅
        func beat(_ m: Int, _ n: Int = 0, _ d: Int = 1) -> [Int] { [m, n, d] }

        var notes: [[String: Any]] = []

        // タップ: 64 拍ぶん。x をずらしながら並べ、ときどき裏拍にも置く
        for i in 0..<64 {
            let x = 24 + (i * 53) % 208
            notes.append(["beat": beat(i), "x": x, "w": 48])
            if i % 4 == 2 {
                notes.append(["beat": beat(i, 1, 2), "x": 255 - x, "w": 40])
            }
        }

        // スライド: seg の beat / x は、始点からの相対
        let segs: [[String: Any]] = [
            ["beat": beat(1), "x": 40],
            ["beat": beat(2), "x": 100],
            ["beat": beat(3), "x": 60]
        ]
        for k in 0..<4 {
            let slide: [String: Any] = ["beat": beat(8 + k * 12), "x": 60, "w": 48, "seg": segs]
            notes.append(slide)
        }

        // ウィップ (type 4)
        notes.append(["beat": beat(30), "x": 128, "w": 200, "type": 4])

        let song: [String: Any] = ["title": "Demo Chart", "artist": "Demo", "id": 0]
        let meta: [String: Any] = [
            "mode": 5,
            "version": "Demo",
            "creator": "demo",
            "background": "",
            "song": song
        ]
        // BPM の変化 (BPM list の中身になる)
        let times: [[String: Any]] = [
            ["beat": beat(0), "bpm": 150],
            ["beat": beat(16), "bpm": 180],
            ["beat": beat(32), "bpm": 120.5],
            ["beat": beat(48), "bpm": 200]
        ]
        // scroll / jump (Effect list の中身になる)
        let effects: [[String: Any]] = [
            ["beat": beat(0), "scroll": 1.0],
            ["beat": beat(8), "scroll": 1.5],
            ["beat": beat(24), "scroll": 0.5],
            ["beat": beat(40), "jump": 500],
            ["beat": beat(56), "scroll": 1.0]
        ]
        let root: [String: Any] = [
            "meta": meta,
            "time": times,
            "effect": effects,
            "note": notes
        ]
        return try JSONSerialization.data(withJSONObject: root, options: [])
    }
}
