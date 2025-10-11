//
//  APIKeyMissingView.swift
//  App
//
//  Created by 이승주 on 10/11/25.
//

import SwiftUI

/// OpenAI API 키가 설정되지 않았을 때 표시되는 안내 화면
struct APIKeyMissingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            VStack(spacing: 12) {
                Text("API 키가 설정되지 않았습니다")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("OpenAI API 키를 환경변수에 설정해주세요")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("설정 방법:")
                    .font(.headline)
                    .padding(.bottom, 4)

                Group {
                    Text("1. Xcode에서 Product > Scheme > Edit Scheme 선택")
                    Text("2. Run > Arguments > Environment Variables 추가")
                    Text("3. OPENAI_API_KEY = your_api_key_here")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Text("⚠️ 실제 배포 시에는 백엔드 프록시를 통해 API를 호출하는 것이 권장됩니다.")
                .font(.caption)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(32)
    }
}

#Preview {
    APIKeyMissingView()
}
