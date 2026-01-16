//
//  MyPageState.swift
//  Presentation
//
//  Created by 이승주 on 1/15/26.
//

import Foundation

/// 마이페이지 State
public struct MyPageState: Equatable {
    public var showVersionAlert: Bool

    public init(showVersionAlert: Bool = false) {
        self.showVersionAlert = showVersionAlert
    }
}
