//
//  QTShareCardView.swift
//  Presentation
//
//  Created by 이승주 on 1/28/26.
//

import SwiftUI
import Domain
import Photos

// MARK: - 4포인트 스냅 슬라이더

/// 드래그하면 4개의 포인트에 스냅되는 슬라이더
private struct SnapSlider: View {
    let index: Int
    let count: Int
    let onChange: (Int) -> Void

    @GestureState private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let stepWidth = count > 1 ? trackWidth / CGFloat(count - 1) : trackWidth
            let baseX = CGFloat(index) * stepWidth
            let rawX = baseX + dragTranslation
            let currentX = min(max(rawX, 0), trackWidth)

            ZStack(alignment: .leading) {
                // 배경 트랙
                Capsule()
                    .fill(DS.Color.textSecondary.opacity(0.15))
                    .frame(height: 3)

                // 활성 트랙 (현재 위치까지 gold)
                Capsule()
                    .fill(DS.Color.gold)
                    .frame(width: max(currentX, 0), height: 3)

                // 4개 틱 마크
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { i in
                        let tickX = CGFloat(i) * stepWidth
                        Circle()
                            .fill(tickX <= currentX ? DS.Color.gold : DS.Color.textSecondary.opacity(0.25))
                            .frame(width: 6, height: 6)
                        if i < count - 1 { Spacer() }
                    }
                }

                // 썸 (드래그 중 실시간, 종료 시 스냅)
                Circle()
                    .fill(.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .offset(x: currentX - 11)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragTranslation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let newX = min(max(baseX + value.translation.width, 0), trackWidth)
                        let newIndex = Int((newX / stepWidth).rounded())
                        let snapped = min(max(newIndex, 0), count - 1)
                        if snapped != index {
                            Haptics.tap()
                            onChange(snapped)
                        }
                    }
            )
        }
        .frame(height: 28)
    }
}

// MARK: - QTShareCardView

/// 이미지 공유 프리뷰 및 바텀시트
public struct QTShareCardView: View {
    let qt: QuietTime
    let onShare: (UIImage?) -> Void

    // 마지막 설정 기억 (AppStorage — 바텀시트 재오픈 시 유지)
    @AppStorage("shareCard.fontScaleRaw") private var fontScaleRaw: String = FontScale.medium.rawValue
    @AppStorage("shareCard.lineSpacingRaw") private var lineSpacingRaw: String = LineSpacing.normal.rawValue

    @State private var renderedImage: Image?
    @State private var renderedUIImage: UIImage?
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""

    // 현재 설정값
    private var localFontScale: FontScale { FontScale(rawValue: fontScaleRaw) ?? .medium }
    private var localLineSpacing: LineSpacing { LineSpacing(rawValue: lineSpacingRaw) ?? .normal }

    // 인덱스 헬퍼
    private var fontScaleIndex: Int { FontScale.allCases.firstIndex(of: localFontScale) ?? 1 }
    private var lineSpacingIndex: Int { LineSpacing.allCases.firstIndex(of: localLineSpacing) ?? 1 }

    public init(
        qt: QuietTime,
        onShare: @escaping (UIImage?) -> Void
    ) {
        self.qt = qt
        self.onShare = onShare
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 핸들 바
            RoundedRectangle(cornerRadius: 3)
                .fill(DS.Color.textSecondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // 상단 버튼 영역 (저장, 공유 — 동일 스타일, 우측 정렬)
            HStack(alignment: .center, spacing: 8) {
                Spacer()

                Button {
                    Haptics.tap()
                    saveToPhotos()
                } label: {
                    Text("저장")
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(height: 36)
                }
                .disabled(renderedUIImage == nil)
                .opacity(renderedUIImage == nil ? 0.4 : 1)

                Button {
                    Haptics.tap()
                    onShare(renderedUIImage)
                } label: {
                    Text("공유")
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(height: 36)
                        .padding(.horizontal, 16)
                }
                .disabled(renderedUIImage == nil)
                .opacity(renderedUIImage == nil ? 0.4 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // 이미지 프리뷰 (중앙 정렬, 가능한 크게)
            Group {
                if let renderedImage {
                    renderedImage
                        .resizable()
                        .aspectRatio(9/16, contentMode: .fit)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 3)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DS.Color.background)
                        .aspectRatio(9/16, contentMode: .fit)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 하단 컨트롤: 글자 크기 / 행간 (드래그 스냅 슬라이더)
            VStack(spacing: 20) {
                // 글자 크기
                HStack(spacing: 10) {
                    Text("글자 크기")
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 56, alignment: .leading)

                    Text("가")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 18, alignment: .center)

                    SnapSlider(
                        index: fontScaleIndex,
                        count: FontScale.allCases.count
                    ) { newIndex in
                        fontScaleRaw = FontScale.allCases[newIndex].rawValue
                        Task { await renderImage() }
                    }

                    Text("가")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 22, alignment: .center)
                }

                // 행간
                HStack(spacing: 10) {
                    Text("행간")
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 56, alignment: .leading)

                    Image(systemName: "text.alignleft")
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 18, alignment: .center)

                    SnapSlider(
                        index: lineSpacingIndex,
                        count: LineSpacing.allCases.count
                    ) { newIndex in
                        lineSpacingRaw = LineSpacing.allCases[newIndex].rawValue
                        Task { await renderImage() }
                    }

                    Image(systemName: "text.alignleft")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 22, alignment: .center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(DS.Color.canvas)
        .task {
            await renderImage()
        }
        .alert("이미지 저장", isPresented: $showSaveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
    }

    // MARK: - Private

    private func saveToPhotos() {
        guard let image = renderedUIImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    self.saveAlertMessage = "이미지가 사진첩에 저장되었습니다."
                    self.showSaveAlert = true
                case .denied, .restricted:
                    self.saveAlertMessage = "사진 접근 권한이 필요합니다.\n설정 > QTune에서 사진 권한을 허용해주세요."
                    self.showSaveAlert = true
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    @MainActor
    private func renderImage() async {
        let shareCard = QTShareCard(qt: qt, fontScale: localFontScale, lineSpacing: localLineSpacing)

        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: shareCard)
            renderer.scale = UIScreen.main.scale

            if let uiImage = renderer.uiImage {
                renderedImage = Image(uiImage: uiImage)
                renderedUIImage = uiImage
            }
        }
    }
}
