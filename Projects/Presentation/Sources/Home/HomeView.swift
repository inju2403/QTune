//
//  HomeView.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// 홈 화면 (가벼운 소개 + CTA)
public struct HomeView: View {
    @State private var showRecommendFlow = false

    public init() {}

    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    // 타이틀 블록
                    VStack(spacing: 12) {
                        Text("QTune")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(DSColor.cocoaDeep)

                        Text("당신의 하루를\n말씀으로 조율하세요")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(DSColor.textSec)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 60)

                    // 설명 카드
                    SoftCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(DSColor.gold)
                                    .font(.system(size: 24))

                                Text("오늘의 말씀 추천")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(DSColor.textPri)
                            }

                            Text("오늘의 감정과 상황을 나누면\n당신에게 필요한 말씀을 추천해드려요")
                                .font(.system(size: 15))
                                .foregroundStyle(DSColor.textSec)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, 20)

                    // CTA 버튼
                    PrimaryCTAButton(title: "오늘의 말씀 추천받기", icon: "sparkles") {
                        Haptics.tap()
                        showRecommendFlow = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showRecommendFlow) {
            RecommendFlowView()
        }
    }
}
