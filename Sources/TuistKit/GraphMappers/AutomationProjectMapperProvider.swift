import Foundation
import TuistAutomation
import TuistCore
import TuistGenerator
import TuistSupport
import TSCBasic

/// Custom mapper provider for automation features
/// It uses default `ProjectMapperProvider` but adds its own on top
final class AutomationProjectMapperProvider: ProjectMapperProviding {
    private let temporaryDirectory: AbsolutePath
    private let projectMapperProvider: ProjectMapperProviding

    init(
        temporaryDirectory: AbsolutePath,
        projectMapperProvider: ProjectMapperProviding = ProjectMapperProvider()
    ) {
        self.temporaryDirectory = temporaryDirectory
        self.projectMapperProvider = projectMapperProvider
    }

    func mapper(config: Config) -> ProjectMapping {
        var mappers: [ProjectMapping] = []
        mappers.append(AutomationPathProjectMapper(temporaryDirectory: temporaryDirectory))
        mappers.append(projectMapperProvider.mapper(config: config))

        if config.generationOptions.contains(.disableAutogeneratedSchemes) {
            mappers.append(
                AutogeneratedSchemesProjectMapper(
                    enableCodeCoverage: config.generationOptions.contains(.enableCodeCoverage)
                )
            )
        }

        return SequentialProjectMapper(mappers: mappers)
    }
}