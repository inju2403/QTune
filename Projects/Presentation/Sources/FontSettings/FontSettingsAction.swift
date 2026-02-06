//
//  FontSettingsAction.swift
//  Presentation
//
//  Created by 이승주 on 2/6/26.
//

import Foundation
import Domain

/// 폰트 설정 Action
public enum FontSettingsAction: Equatable {
    case selectFontScale(FontScale)
    case selectLineSpacing(LineSpacing)
    case save
    case saveCompleted
}
