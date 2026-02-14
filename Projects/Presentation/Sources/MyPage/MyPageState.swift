//
//  MyPageState.swift
//  Presentation
//
//  Created by 이승주 on 1/15/26.
//

import Foundation
import Domain

/// 마이페이지 State
public struct MyPageState: Equatable {
    public var showVersionAlert: Bool
    public var showTranslationSelection: Bool
    public var selectedPrimaryTranslation: Translation
    public var selectedSecondaryTranslation: Translation?
    public var showNotificationSettings: Bool
    public var notificationTime: Date
    public var isNotificationEnabled: Bool

    public init(
        showVersionAlert: Bool = false,
        showTranslationSelection: Bool = false,
        selectedPrimaryTranslation: Translation = .koreanRevisedVersion,
        selectedSecondaryTranslation: Translation? = nil,
        showNotificationSettings: Bool = false,
        notificationTime: Date = {
            var components = DateComponents()
            components.hour = 20
            components.minute = 30
            return Calendar.current.date(from: components) ?? Date()
        }(),
        isNotificationEnabled: Bool = true
    ) {
        self.showVersionAlert = showVersionAlert
        self.showTranslationSelection = showTranslationSelection
        self.selectedPrimaryTranslation = selectedPrimaryTranslation
        self.selectedSecondaryTranslation = selectedSecondaryTranslation
        self.showNotificationSettings = showNotificationSettings
        self.notificationTime = notificationTime
        self.isNotificationEnabled = isNotificationEnabled
    }
}
