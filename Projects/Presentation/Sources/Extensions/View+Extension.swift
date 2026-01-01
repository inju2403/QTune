//
//  View+Extension.swift
//  Presentation
//
//  Created by 이승주 on 1/1/26.
//

import SwiftUI
import UIKit

extension View {
    /// 현재 활성화된 텍스트 입력(TextField/TextEditor)의 포커스를 해제하고 키보드를 내립니다.
    func endTextEditing() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
