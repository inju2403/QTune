//
//  Haptics.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import UIKit

/// 햅틱 피드백
public enum Haptics {
    /// 부드러운 탭 피드백
    public static func tap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// 성공 피드백
    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
