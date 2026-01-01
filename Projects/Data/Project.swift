import ProjectDescription

let project = Project(
  name: "Data",
  packages: [
    .remote(url: "https://github.com/firebase/firebase-ios-sdk", requirement: .upToNextMajor(from: "11.0.0"))
  ],
  targets: [
    .target(
      name: "Data",
      destinations: [.iPhone],
      product: .framework,
      bundleId: "com.qtune.data",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .default,
      sources: nil,
      buildableFolders: [.folder("Sources")],
      dependencies: [
        .project(target: "Domain", path: "../Domain"),
        .package(product: "FirebaseFunctions", type: .runtime),
        .package(product: "FirebaseAuth", type: .runtime)
      ]
    )
  ]
)
