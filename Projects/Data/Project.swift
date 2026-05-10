import ProjectDescription

let project = Project(
  name: "Data",
  targets: [
    .target(
      name: "Data",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.qtune.data",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .default,
      sources: nil,
      resources: [
        "Resources/bible.sqlite"
      ],
      buildableFolders: [.folder("Sources")],
      dependencies: [
        .project(target: "Domain", path: "../Domain")
      ]
    )
  ]
)
