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
      sources: ["Sources/**"],
      dependencies: [
        .project(target: "Domain", path: "../Domain")
      ]
    )
  ]
)
