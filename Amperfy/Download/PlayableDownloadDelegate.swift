import Foundation
import CoreData

class PlayableDownloadDelegate: DownloadManagerDelegate {

    private let backendApi: BackendApi

    init(backendApi: BackendApi) {
        self.backendApi = backendApi
    }

    func prepareDownload(forRequest request: DownloadRequest, context: NSManagedObjectContext) throws -> URL {
        let playableMO = try context.existingObject(with: request.element.objectID) as! AbstractPlayableMO
        let playable = AbstractPlayable(managedObject: playableMO)
        guard !playable.isCached else {
            throw DownloadError.alreadyDownloaded 
        }
        return try updateDownloadUrl(forPlayable: playable)
    }

    private func updateDownloadUrl(forPlayable playable: AbstractPlayable) throws -> URL {
        guard Reachability.isConnectedToNetwork() else {
            throw DownloadError.noConnectivity
        }
        guard let url = backendApi.generateUrl(forDownloadingPlayable: playable) else {
            throw DownloadError.urlInvalid
        }
        return url
    }
    
    func validateDownloadedData(request: DownloadRequest) -> ResponseError? {
        guard let download = request.download, let data = download.resumeData else {
            return ResponseError(statusCode: 0, message: "Invalid download")
        }
        return backendApi.checkForErrorResponse(inData: data)
    }

    func completedDownload(request: DownloadRequest, context: NSManagedObjectContext) {
        guard let download = request.download, let data = download.resumeData else { return }
		let library = LibraryStorage(context: context)
        if let playableMO = try? context.existingObject(with: request.element.objectID) as? AbstractPlayableMO {
            let playableFile = library.createPlayableFile()
            playableFile.info = AbstractPlayable(managedObject: playableMO)
            playableFile.data = data
            library.saveContext()
        }
    }

}