//
//  QTShareImageView.swift
//  Presentation
//
//  Created by 이승주 on 1/28/26.
//

import SwiftUI
import Domain

/// 시스템 공유 시트와 연동되는 이미지 공유 뷰
public struct QTShareImageView: View {
    let qt: QuietTime

    @State private var shareImage: Image?
    @State private var imageURL: URL?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.fontScale) private var fontScale
    @Environment(\.lineSpacing) private var lineSpacing

    public init(qt: QuietTime) {
        self.qt = qt
    }

    public var body: some View {
        if let imageURL {
            // 파일 URL을 전달 (iOS 18 호환성 향상)
            UIActivityViewControllerRepresentable(
                activityItems: [imageURL],
                onComplete: {
                    // 임시 파일 삭제
                    try? FileManager.default.removeItem(at: imageURL)
                    dismiss()
                }
            )
            .ignoresSafeArea()
        } else {
            // 이미지 렌더링 중
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .task {
                    await renderImage()
                }
        }
    }

    @MainActor
    private func renderImage() async {
        let shareCard = QTShareCard(qt: qt, fontScale: fontScale, lineSpacing: lineSpacing)

        // iOS 16+ ImageRenderer 사용
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: shareCard)
            renderer.scale = UIScreen.main.scale

            if let renderedUIImage = renderer.uiImage,
               let imageData = renderedUIImage.pngData() {
                // 임시 파일로 저장
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("QTune_Share_\(UUID().uuidString).png")

                do {
                    try imageData.write(to: tempURL)
                    self.imageURL = tempURL
                    self.shareImage = Image(uiImage: renderedUIImage)
                } catch {
                    print("Failed to save image to temp file: \(error)")
                }
            }
        }
    }
}

/// iOS 15 이하를 위한 UIActivityViewController wrapper
struct UIActivityViewControllerRepresentable: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onComplete: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            onComplete()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}