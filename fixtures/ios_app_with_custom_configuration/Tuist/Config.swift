import ProjectDescription

let config = Config(
  cache: .cache(profiles: [.profile(name: "simulator", configuration: "debug")]),
  generationOptions: [.disableAutogeneratedSchemes]
)
