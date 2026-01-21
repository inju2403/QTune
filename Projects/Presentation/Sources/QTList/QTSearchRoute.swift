//
//  QTSearchRoute.swift
//  Presentation
//
//  Created by 이승주 on 1/21/26.
//

import Foundation
import Domain

/// 검색 탭 전용 네비게이션 라우트
public enum QTSearchRoute: Hashable {
    case detail(QuietTime)
}
