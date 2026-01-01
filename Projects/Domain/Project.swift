import ProjectDescription

let project = Project(
  name: "Domain",
  targets: [
    .target(
      name: "Domain",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.qtune.domain",
      deploymentTargets: .iOS("17.0"),
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
      ]
    ),
    .target(
      name: "DomainTests",
      destinations: [.iPhone],
      product: .unitTests,
      bundleId: "com.qtune.domainTests",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .default,
      sources: nil,
      buildableFolders: [.folder("Tests")],
      dependencies: [
        .target(name: "Domain")
      ],
      settings: .settings(
        base: [
          "TEST_HOST": "",
          "BUNDLE_LOADER": ""
        ]
      )
    )
  ]
)
