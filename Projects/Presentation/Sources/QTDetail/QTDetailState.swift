//
//  QTDetailState.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// 공유 타입
public enum ShareType: Equatable {
    case summary // 선택한 묵상
    case full    // 전체 묵상
}

/// SOAP 필드 선택
public enum SOAPField: Equatable {
    case observation // 관찰
    case application // 적용
    case prayer      // 기도
}

/// ACTS 필드 선택
public enum ACTSField: Equatable {
    case adoration     // 경배
    case confession    // 회개
    case thanksgiving  // 감사
    case supplication  // 간구
}

/// QT 상세 화면 State
public struct QTDetailState: Equatable {
    public var qt: QuietTime
    public var showDeleteAlert: Bool
    public var showShareSheet: Bool
    public var showEditSheet: Bool
    public var shareText: String

    // 공유 옵션
    public var showShareTypeSelection: Bool
    public var showFieldSelection: Bool
    public var selectedShareType: ShareType?

    public init(
        qt: QuietTime,
        showDeleteAlert: Bool = false,
        showShareSheet: Bool = false,
        showEditSheet: Bool = false,
        shareText: String = "",
        showShareTypeSelection: Bool = false,
        showFieldSelection: Bool = false,
        selectedShareType: ShareType? = nil
    ) {
        self.qt = qt
        self.showDeleteAlert = showDeleteAlert
        self.showShareSheet = showShareSheet
        self.showEditSheet = showEditSheet
        self.shareText = shareText
        self.showShareTypeSelection = showShareTypeSelection
        self.showFieldSelection = showFieldSelection
        self.selectedShareType = selectedShareType
    }
}
