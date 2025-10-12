//
//  Motion.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI

/// 애니메이션 토큰 - 스르륵 부드러운 움직임
public enum Motion {
    /// 화면 전환, 컴포넌트 등장
    public static let appear = Animation.snappy(duration: 0.45, extraBounce: 0.03)

    /// 버튼 프레스
    public static let press = Animation.snappy(duration: 0.20, extraBounce: 0.01)

    /// 광채/빛무리 효과
    public static let halo = Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)
}
