import ProjectDescription

let project = Project(
  name: "Functions",
  targets: [
    .target(
      name: "Functions",
      destinations: .macOS,
      product: .staticFramework,
      bundleId: "com.qtune.functions",
      sources: ["Sources/**/*.ts"],
      scripts: [
        .pre(
          script: """
          cd ${SRCROOT}
          npm install
          npm run build
          """,
          name: "Build Firebase Functions",
          basedOnDependencyAnalysis: false
        )
      ]
    )
  ]
)
