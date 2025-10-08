import ProjectDescription

let project = Project(
  name: "Domain",
  targets: [
    .target(
      name: "Domain",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.qtune.domain",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Sources/**"]
    ),
    .target(
      name: "DomainTests",
      destinations: [.iPhone],
      product: .unitTests,
      bundleId: "com.qtune.domainTests",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Tests/**"],
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
