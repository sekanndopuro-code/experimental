import SwiftUI

@main
struct MalodySlideEditorApp: App {
    var body: some Scene {
        WindowGroup {
            // iPad のとき「iPhone表示」を選んでいれば、iPhone と同じ大きさの枠に入れる (PhonePreview.swift)。
            // 選んでいなければ、中身 (RootView) をそのまま出すだけで、何も変わらない
            PhonePreviewHost { RootView() }
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                // ホームバーは隠さない (隠すと、下端に触れた瞬間に白く出て反応してしまう)。
                // 下端を「遅延」にすると、バーは半透明のまま残り、はっきり上へ持ち上げるまでホームに戻らない (本家 Malody と同じ)
                .defersSystemGestures(on: .bottom)
        }
    }
}
