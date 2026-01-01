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
        "CFBundleShortVersionString": "1.0.0",
        "CFBundleVersion": "102",
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
