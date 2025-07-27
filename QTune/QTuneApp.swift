//
//  QTuneApp.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import SwiftUI

@main
struct QTuneApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RequestVerseView(
                    viewModel: RequestVerseViewModel(
                        generateVerseUseCase: GenerateVerseInteractor(
                            repository: VerseRepositoryImpl()
                        )
                    )
                )
            }
        }
    }
}
