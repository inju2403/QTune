import ProjectDescription

let project = Project(
  name: "Data",
  targets: [
    .target(
      name: "Data",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.qtune.data",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .default,
      sources: ["Sources/**"],
      dependencies: [
        .project(target: "Domain", path: "../Domain")
      ]
    )
  ]
)
