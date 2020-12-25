//
//  RemoteDataDownloadTask.swift
//  Scorepio
//
//  Created by William Piotrowski on 12/2/19.
//  Copyright © 2019 William Piotrowski. All rights reserved.
//

import Foundation
import SPCommon

public class RemoteDataDownloadTask: DownloadTaskRoot {
    let remoteData: LocallyArchivableRemoteDataReference
    
    init(remoteData: LocallyArchivableRemoteDataReference, handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil){
        self.remoteData = remoteData
        super.init(handler: handler)
        progress.totalUnitCount = 1
    }
    init(remoteDataProtocol: LocallyArchivableRemoteDataReference, handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil){
        self.remoteData = remoteDataProtocol
        super.init(handler: handler)
        progress.totalUnitCount = 1
    }
    
    override public func nextTask() {
        remoteData.download()
        .done { data in
            let localURL = self.remoteData.localFileReference.url
            self.completionStatus = .success(localURL: localURL)
        }
        .catch { error in
            self.completionStatus = .failure(error: error)
        }
        //remoteData.getToLocal(completionHandler: getToLocalCallback)
    }
}

/*
extension RemoteDataDownloadTask {
    private func getToLocalCallback(response: RemoteDataType.GetResponse, error: Error?) {
        guard let localURL = response.document?.serverDocument.localFile.url else {
            completionStatus = .failure(error: error ?? DownloadTaskRoot.DownloadError.noURL)
            return
        }
        completionStatus = .success(localURL: localURL)
    }
}
*/
