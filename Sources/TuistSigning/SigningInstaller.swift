import Foundation
import Basic
import AEXML
import TuistSupport

enum SigningInstallerError: FatalError {
    case invalidProvisioningProfile(AbsolutePath)
    case noFileExtension(AbsolutePath)
    
    var type: ErrorType {
        switch self {
        case .invalidProvisioningProfile, .noFileExtension:
            return .abort
        }
    }
    
    var description: String {
        switch self {
        case let .invalidProvisioningProfile(path):
            return "Provisioning profile at \(path.pathString) is invalid - check if it has the expected structure"
        case let .noFileExtension(path):
            return "Unable to parse extension from file at \(path.pathString)"
        }
    }
}

public protocol SigningInstalling {
    func installSigning(at path: AbsolutePath) throws
}

enum SigningFile {
    case provisioningProfile(AbsolutePath)
    case signingCertificate(AbsolutePath)
}

public final class SigningInstaller: SigningInstalling {
    
    private let signingFilesLocator: SigningFilesLocating
    private let securityController: SecurityControlling
    
    public convenience init() {
        self.init(signingFilesLocator: SigningFilesLocator(),
                  securityController: SecurityController())
    }
    
    init(signingFilesLocator: SigningFilesLocating,
                securityController: SecurityControlling) {
        self.signingFilesLocator = signingFilesLocator
        self.securityController = securityController
    }
    
    public func installSigning(at path: AbsolutePath) throws {
        let signingKeyFiles = try signingFilesLocator.locateSigningFiles(at: path)
        try signingKeyFiles.forEach {
            switch $0.extension {
            case "mobileprovision", "provisionprofile":
                try installProvisioningProfile(at: $0)
            case "cer":
                try importCertificate(at: $0)
            default:
                logger.warning("File \($0.pathString) has unknown extension")
            }
        }
    }
    
    private func installProvisioningProfile(at path: AbsolutePath) throws {
        let unencryptedProvisioningProfile = try securityController.decodeFile(at: path)
        let xmlDocument = try AEXMLDocument(xml: unencryptedProvisioningProfile)
        let children = xmlDocument.root.children.flatMap { $0.children }
        
        guard let profileExtension = path.extension else { throw SigningInstallerError.noFileExtension(path) }
        
        guard
            let uuidIndex = children.firstIndex(where: { $0.string == "UUID" }),
            children.index(after: uuidIndex) != children.endIndex,
            let uuid = children[children.index(after: uuidIndex)].value
        else { throw SigningInstallerError.invalidProvisioningProfile(path) }
        
        // TODO: Create directory if it does not exist
        let provisioningProfilesPath = AbsolutePath.homeDirectory.appending(components: "Library", "MobileDevice", "Provisioning Profiles")
        let encryptedProvisioningProfile = try FileHandler.shared.readFile(path)
        try encryptedProvisioningProfile.write(to: provisioningProfilesPath.appending(component: uuid + "." + profileExtension).url)
        
        logger.debug("Installed provisioning profile \(path.pathString)")
    }
    
    private func importCertificate(at path: AbsolutePath) throws {
        guard try !securityController.certificateExists(path: path) else {
            logger.debug("Certificate at \(path) is already present in keychain")
            return
        }
        
        try securityController.importCertificate(at: path)
        logger.debug("Imported certificate at \(path.pathString)")
    }
}
