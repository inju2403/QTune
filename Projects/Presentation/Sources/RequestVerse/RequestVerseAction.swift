//
//  RequestVerseAction.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation
import Domain

enum RequestVerseAction {
    case onAppear(userId: String)
    case updateMood(String)          // 감정/상황 입력 업데이트
    case updateNote(String)          // 추가 메모 업데이트
    case tapRequest(nickname: String?, gender: String?)  // 말씀 추천받기
    case tapGoToQT                   // QT 하러 가기
    case tapResumeDraft              // 드래프트 이어서 작성
    case tapDiscardDraft             // 드래프트 삭제
    case dismissError                // 에러 메시지 닫기
}
