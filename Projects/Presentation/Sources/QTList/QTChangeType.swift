//
//  QTChangeType.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

// MARK: - Notification Names
public extension Notification.Name {
    static let qtDidChange = Notification.Name("qtDidChange")
}

// MARK: - QT Change Type
public enum QTChangeType {
    case created(QuietTime)
    case updated(QuietTime)
    case deleted(UUID)
}
