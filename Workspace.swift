import ProjectDescription

let workspace = Workspace(
  name: "QTune",
  projects: [
    "Projects/*"
  ],
  schemes: [],
  additionalFiles: [
    "functions/**",
    ".firebaserc",
    "firebase.json"
  ]
)
