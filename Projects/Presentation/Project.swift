import ProjectDescription

let project = Project(
  name: "Presentation",
  targets: [
    .target(
      name: "Presentation",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.qtune.presentation",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: nil,
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
        .project(target: "Domain", path: "../Domain")
      ]
    ),
    .target(
      name: "PresentationTests",
      destinations: [.iPhone],
      product: .unitTests,
      bundleId: "com.qtune.presentationTests",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: nil,
      buildableFolders: [.folder("Tests")],
      dependencies: [
        .target(name: "Presentation")
      ]
    )
  ]
)
