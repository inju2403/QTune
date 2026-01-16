import ProjectDescription

let project = Project(
  name: "App",
  targets: [
    .target(
      name: "App",
      destinations: [.iPhone],
      product: .app,
      bundleId: "com.inju.qtune",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "QTune",
        "CFBundleShortVersionString": "1.2.1",
        "CFBundleVersion": "122",
        "UILaunchStoryboardName": "LaunchScreen",
        "UIViewControllerBasedStatusBarAppearance": true
      ]),
      sources: nil,
      resources: [
        "Resources/Assets.xcassets",
        "Resources/LaunchScreen.storyboard",
        "Resources/Preview Content/**",
        "Resources/GoogleService-Info.plist"
      ],
      buildableFolders: [.folder("Sources")],
      scripts: [
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
        .project(target: "Data", path: "../Data")
      ]
    )
  ]
)
