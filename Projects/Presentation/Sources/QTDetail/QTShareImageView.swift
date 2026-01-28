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
    @State private var uiImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    public init(qt: QuietTime) {
        self.qt = qt
    }

    public var body: some View {
        if let uiImage {
            // ShareLink는 iOS 16+, UIImage를 직접 전달
            UIActivityViewControllerRepresentable(
                activityItems: [uiImage],
                onComplete: {
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
        let shareCard = QTShareCard(qt: qt)

        // iOS 16+ ImageRenderer 사용
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: shareCard)
            renderer.scale = UIScreen.main.scale

            if let renderedUIImage = renderer.uiImage {
                self.uiImage = renderedUIImage
                self.shareImage = Image(uiImage: renderedUIImage)
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