import Foundation
import TSCBasic
import TuistSupport

public struct Workspace: Equatable {
    // MARK: - Attributes

    public var path: AbsolutePath
    public var name: String
    public var projects: [AbsolutePath]
    /// Array of paths to `.xcodeproj`
    public var xcodeProjPaths: [AbsolutePath]
    public var schemes: [Scheme]
    public var additionalFiles: [FileElement]

    // MARK: - Init

    public init(
        path: AbsolutePath,
        name: String,
        projects: [AbsolutePath],
        xcodeProjPaths: [AbsolutePath],
        schemes: [Scheme] = [],
        additionalFiles: [FileElement] = []
    ) {
        self.path = path
        self.name = name
        self.projects = projects
        self.xcodeProjPaths = xcodeProjPaths
        self.schemes = schemes
        self.additionalFiles = additionalFiles
    }
}

extension Workspace {
    public func with(name: String) -> Workspace {
        var copy = self
        copy.name = name
        return copy
    }

    public func adding(files: [AbsolutePath]) -> Workspace {
        Workspace(path: path,
                  name: name,
                  projects: projects,
                  xcodeProjPaths: xcodeProjPaths,
                  schemes: schemes,
                  additionalFiles: additionalFiles + files.map { .file(path: $0) })
    }

    public func replacing(projects: [AbsolutePath]) -> Workspace {
        Workspace(path: path,
                  name: name,
                  projects: projects,
                  xcodeProjPaths: xcodeProjPaths,
                  schemes: schemes,
                  additionalFiles: additionalFiles)
    }

    public func merging(projects otherProjects: [AbsolutePath]) -> Workspace {
        Workspace(path: path,
                  name: name,
                  projects: Array(Set(projects + otherProjects)),
                  xcodeProjPaths: xcodeProjPaths,
                  schemes: schemes,
                  additionalFiles: additionalFiles)
    }
}
