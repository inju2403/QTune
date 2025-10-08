import ProjectDescription

let project = Project(
  name: "App",
  targets: [
    .target(
      name: "App",
      destinations: [.iPhone],
      product: .app,
      bundleId: "com.yourcompany.app",
      deploymentTargets: .iOS("16.0"),
      infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [
          "UIColorName": "",
          "UIImageName": "",
          "UILaunchScreen": [:]
        ],
        "UIViewControllerBasedStatusBarAppearance": true
      ]),
      sources: ["Sources/**"],
      resources: ["Sources/Assets.xcassets", "Sources/Preview Content/**"],
      dependencies: [
        .project(target: "Presentation", path: "../Presentation"),
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Data", path: "../Data")
      ]
    )
  ]
)
