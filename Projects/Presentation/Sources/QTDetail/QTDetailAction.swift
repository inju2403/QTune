//
//  QTDetailAction.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation

/// QT 상세 화면 Action
public enum QTDetailAction: Equatable {
    case toggleFavorite
    case confirmDelete
    case deleteQT
    case prepareShare
    case selectShareType(ShareType)
    case selectSOAPField(SOAPField)
    case selectACTSField(ACTSField)
    case cancelShare
    case closeShareSheet
    case showEditSheet(Bool)
    case reloadQT
}
