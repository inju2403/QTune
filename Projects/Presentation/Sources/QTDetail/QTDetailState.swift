//
//  QTDetailState.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 상세 화면 State
public struct QTDetailState: Equatable {
    public var qt: QuietTime
    public var showDeleteAlert: Bool
    public var showShareSheet: Bool
    public var showEditSheet: Bool
    public var shareText: String

    public init(
        qt: QuietTime,
        showDeleteAlert: Bool = false,
        showShareSheet: Bool = false,
        showEditSheet: Bool = false,
        shareText: String = ""
    ) {
        self.qt = qt
        self.showDeleteAlert = showDeleteAlert
        self.showShareSheet = showShareSheet
        self.showEditSheet = showEditSheet
        self.shareText = shareText
    }
}
