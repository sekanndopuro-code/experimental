import SwiftUI
import UIKit

// MARK: - iPhone 表示プレビュー (iPad の上で、iPhone 横画面の見た目を確かめる開発用の機能)
//
// 仕組み:
//  - エディタの寸法は「画面の高さ ÷ 820」の倍率で決まる (DesignCanvas / EditorView.swift)。
//    なので、iPad の画面の中に「iPhone と同じ pt の大きさの枠」(例: 852 × 393 pt) を作ってアプリを入れれば、
//    倍率もレイアウトも iPhone の実機と同じになる。
//  - 起動画面の「iPhone表示」メニューで機種を選ぶ。選んだ機種は覚えているので、アプリを開き直しても続く。
//  - iPhone の実機やシミュレータで動いているときは何もしない (iPad のときだけ働く)。
//
// 再現できないもの (これらは iPhone のシミュレータ = Appetize などで確かめる):
//  - ソフトウェアキーボード (iPad のキーボードは大きさも出方も違う)。BPM / Effect の入力の確認には使えない
//  - テストプレイ・ファイル選択・アラートなど、全画面で出る表示 (iPad の画面全体に出る)
//  - ノッチ / ダイナミックアイランドまわりの安全領域 (島の形を黒く重ねて、隠れる範囲だけは見えるようにしてある)

enum PhonePreviewDevice: String, CaseIterable, Identifiable {
    case off, se, iphone16, iphone16Pro, iphone16ProMax

    var id: String { rawValue }

    /// 横画面での画面の大きさ (pt)。nil = プレビューしない
    var size: CGSize? {
        switch self {
        case .off:            return nil
        case .se:             return CGSize(width: 667, height: 375)
        case .iphone16:       return CGSize(width: 852, height: 393)
        case .iphone16Pro:    return CGSize(width: 874, height: 402)
        case .iphone16ProMax: return CGSize(width: 956, height: 440)
        }
    }

    var label: String {
        switch self {
        case .off:            return "オフ"
        case .se:             return "iPhone SE"
        case .iphone16:       return "iPhone 16"
        case .iphone16Pro:    return "iPhone 16 Pro"
        case .iphone16ProMax: return "iPhone 16 Pro Max"
        }
    }

    /// 画面の角の丸み (pt)
    var cornerRadius: CGFloat {
        switch self {
        case .off, .se:       return 0
        case .iphone16:       return 47
        case .iphone16Pro, .iphone16ProMax: return 55
        }
    }

    /// ダイナミックアイランドとホームバーがある機種か
    var hasIsland: Bool {
        switch self {
        case .off, .se: return false
        default:        return true
        }
    }
}

enum PhonePreview {
    static let deviceKey = "phonePreviewDevice"
    static let realSizeKey = "phonePreviewRealSize"

    /// iPad (11〜13 インチは約 132pt/インチ) の上で、iPhone (約 153pt/インチ) と同じ実際の大きさに近づける倍率。
    /// 文字が「本当に読めない小ささか」を、手で持った感覚で確かめるためのもの
    static let realSizeScale: CGFloat = 0.86

    /// iPad のときだけ使える
    static var isAvailable: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

/// アプリ全体を包む。プレビューがオフ (または iPad 以外) のときは、中身をそのまま出すだけで何も変えない
struct PhonePreviewHost<Content: View>: View {
    @AppStorage(PhonePreview.deviceKey) private var deviceRaw = PhonePreviewDevice.off.rawValue
    @AppStorage(PhonePreview.realSizeKey) private var realSize = false

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if PhonePreview.isAvailable,
           let device = PhonePreviewDevice(rawValue: deviceRaw),
           let size = device.size {
            framed(device: device, size: size)
        } else {
            content
        }
    }

    @ViewBuilder
    private func framed(device: PhonePreviewDevice, size: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: device.cornerRadius, style: .continuous)
        ZStack {
            Color(white: 0.14).ignoresSafeArea()

            content
                .frame(width: size.width, height: size.height)
                .background(Color.black)
                // 枠の外へはみ出すもの (右からスライドして出るパネルの待機位置など) は、実機では画面の外なので切り取る
                .clipShape(shape)
                .overlay(PhoneBezelOverlay(device: device))
                .overlay(shape.stroke(Color.white.opacity(0.35), lineWidth: 2))
                .scaleEffect(realSize ? PhonePreview.realSizeScale : 1)
        }
        .overlay(alignment: .top) {
            caption(device: device, size: size)
        }
    }

    private func caption(device: PhonePreviewDevice, size: CGSize) -> some View {
        let s = DesignScreen.scale(forHeight: size.height)
        var text = "\(device.label) · \(Int(size.width))×\(Int(size.height))pt · UI倍率 ×\(String(format: "%.2f", Double(s)))"
        if realSize { text += " · 実寸補正" }
        return Text(text)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(.white.opacity(0.6))
            .padding(.top, 10)
            .allowsHitTesting(false)
    }
}

/// 実機で隠れる部分の目安: ダイナミックアイランド (横画面では左端) とホームバー (下端)。タッチは邪魔しない
private struct PhoneBezelOverlay: View {
    let device: PhonePreviewDevice

    var body: some View {
        ZStack {
            if device.hasIsland {
                Capsule()
                    .fill(Color.black)
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    .frame(width: 37, height: 125)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 11)

                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 140, height: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
        }
        .allowsHitTesting(false)
    }
}
