import ProjectDescription

let project = Project(
  name: "App",
  packages: [
    .remote(url: "https://github.com/firebase/firebase-ios-sdk", requirement: .upToNextMajor(from: "11.0.0"))
  ],
  settings: .settings(
    configurations: [
      .debug(name: "Debug", settings: ["ENVIRONMENT": "PRODUCTION"]),
      .release(name: "Release", settings: ["ENVIRONMENT": "PRODUCTION"]),
      .debug(name: "Debug-Sandbox", settings: ["ENVIRONMENT": "SANDBOX"]),
      .release(name: "Release-Sandbox", settings: ["ENVIRONMENT": "SANDBOX"])
    ]
  ),
  targets: [
    .target(
      name: "App",
      destinations: [.iPhone],
      product: .app,
      bundleId: "com.inju.qtune",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "$(PRODUCT_NAME)",
        "CFBundleShortVersionString": "1.5.1",
        "CFBundleVersion": "151",
        "UILaunchStoryboardName": "LaunchScreen",
        "UIViewControllerBasedStatusBarAppearance": true,
        "UIUserInterfaceStyle": "Light"
      ]),
      sources: nil,
      resources: [
        "Resources/Assets.xcassets",
        "Resources/LaunchScreen.storyboard",
        "Resources/Preview Content/**",
        "Resources/GoogleService-Info.plist",
        "Resources/GoogleService-Info-sandbox.plist"
      ],
      buildableFolders: [.folder("Sources")],
      scripts: [
        .pre(
          script: """
          # Firebase 환경별 GoogleService-Info.plist 복사
          echo "🔧 Environment: ${ENVIRONMENT}"

          if [ "${ENVIRONMENT}" = "SANDBOX" ]; then
            echo "📋 Using Sandbox GoogleService-Info.plist"
            cp "${SRCROOT}/Resources/GoogleService-Info-sandbox.plist" "${SRCROOT}/Resources/GoogleService-Info.plist"
          else
            echo "📋 Using Production GoogleService-Info.plist"
            if [ -f "${SRCROOT}/Resources/GoogleService-Info-production.plist" ]; then
              cp "${SRCROOT}/Resources/GoogleService-Info-production.plist" "${SRCROOT}/Resources/GoogleService-Info.plist"
            fi
          fi
          """,
          name: "Setup Firebase Config",
          basedOnDependencyAnalysis: false
        ),
        .pre(
          script: """
          if command -v swiftlint >/dev/null 2>&1; then
            swiftlint --strict
          else
            echo "⚠️  SwiftLint not installed. Skipping."
          fi
          """,
          name: "SwiftLint",
          basedOnDependencyAnalysis: false
        ),
        .post(
          script: """
          # Firebase Crashlytics dSYM 업로드
          CRASHLYTICS_SCRIPT="${BUILD_DIR%Build/*}SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"

          if [ -f "$CRASHLYTICS_SCRIPT" ]; then
            echo "🔥 Uploading dSYM to Firebase Crashlytics..."
            "$CRASHLYTICS_SCRIPT"
          else
            echo "⚠️  Crashlytics script not found. Skipping dSYM upload."
            echo "Path checked: $CRASHLYTICS_SCRIPT"
          fi
          """,
          name: "Firebase Crashlytics",
          inputPaths: [
            "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}",
            "$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)"
          ],
          basedOnDependencyAnalysis: false
        )
      ],
      dependencies: [
        .project(target: "Presentation", path: "../Presentation"),
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Data", path: "../Data"),
        .package(product: "FirebaseAnalytics"),
        .package(product: "FirebaseCrashlytics"),
        .package(product: "FirebaseCore")
      ],
      settings: .settings(
        base: [
            "OTHER_LDFLAGS": .array(["$(inherited)", "-ObjC"])
        ],
        configurations: [
          .debug(name: "Debug", settings: [
            "PRODUCT_BUNDLE_IDENTIFIER": "com.inju.qtune",
            "PRODUCT_NAME": "QTune"
          ]),
          .release(name: "Release", settings: [
            "PRODUCT_BUNDLE_IDENTIFIER": "com.inju.qtune",
            "PRODUCT_NAME": "QTune"
          ]),
          .debug(name: "Debug-Sandbox", settings: [
            "PRODUCT_BUNDLE_IDENTIFIER": "com.inju.qtune.sandbox",
            "PRODUCT_NAME": "QTune-Sandbox"
          ]),
          .release(name: "Release-Sandbox", settings: [
            "PRODUCT_BUNDLE_IDENTIFIER": "com.inju.qtune.sandbox",
            "PRODUCT_NAME": "QTune-Sandbox"
          ])
        ],
        defaultSettings: .recommended
      )
    ),
    // Sandbox 전용 타겟 (선택사항)
    .target(
      name: "App-Sandbox",
      destinations: [.iPhone],
      product: .app,
      bundleId: "com.inju.qtune.sandbox",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "QTune Sandbox",
        "CFBundleShortVersionString": "1.5.1",
        "CFBundleVersion": "151",
        "UILaunchStoryboardName": "LaunchScreen",
        "UIViewControllerBasedStatusBarAppearance": true,
        "UIUserInterfaceStyle": "Light"
      ]),
      sources: nil,
      resources: [
        "Resources/Assets.xcassets",
        "Resources/LaunchScreen.storyboard",
        "Resources/Preview Content/**",
        "Resources/GoogleService-Info.plist"  // Firebase SDK는 이 이름을 찾음
      ],
      buildableFolders: [.folder("Sources")],
      scripts: [
        .pre(
          script: """
          # Sandbox 환경용 GoogleService-Info.plist 설정
          echo "📋 Setting up Sandbox GoogleService-Info.plist"
          if [ -f "${SRCROOT}/Resources/GoogleService-Info-sandbox.plist" ]; then
            cp -f "${SRCROOT}/Resources/GoogleService-Info-sandbox.plist" "${SRCROOT}/Resources/GoogleService-Info.plist"
            echo "✅ Copied sandbox plist to GoogleService-Info.plist"
          else
            echo "⚠️ GoogleService-Info-sandbox.plist not found!"
          fi
          """,
          name: "Setup Sandbox Firebase Config",
          basedOnDependencyAnalysis: false
        ),
        .pre(
          script: """
          if command -v swiftlint >/dev/null 2>&1; then
            swiftlint --strict
          else
            echo "⚠️  SwiftLint not installed. Skipping."
          fi
          """,
          name: "SwiftLint",
          basedOnDependencyAnalysis: false
        ),
        .post(
          script: """
          # Firebase Crashlytics dSYM 업로드
          CRASHLYTICS_SCRIPT="${BUILD_DIR%Build/*}SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"

          if [ -f "$CRASHLYTICS_SCRIPT" ]; then
            echo "🔥 Uploading dSYM to Firebase Crashlytics..."
            "$CRASHLYTICS_SCRIPT"
          else
            echo "⚠️  Crashlytics script not found. Skipping dSYM upload."
            echo "Path checked: $CRASHLYTICS_SCRIPT"
          fi
          """,
          name: "Firebase Crashlytics",
          inputPaths: [
            "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}",
            "$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)"
          ],
          basedOnDependencyAnalysis: false
        )
      ],
      dependencies: [
        .project(target: "Presentation", path: "../Presentation"),
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Data", path: "../Data"),
        .package(product: "FirebaseAnalytics"),
        .package(product: "FirebaseCrashlytics"),
        .package(product: "FirebaseCore")
      ],
      settings: .settings(
        base: [
            "OTHER_LDFLAGS": .array(["$(inherited)", "-ObjC"])
        ],
        configurations: [],
        defaultSettings: .recommended
      )
    )
  ]
)