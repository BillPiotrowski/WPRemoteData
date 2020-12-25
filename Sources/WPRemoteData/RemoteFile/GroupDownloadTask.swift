//
//  GroupDownloadTask.swift
//  RemoteFile
//
//  Created by William Piotrowski on 6/29/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
import SPCommon

public class GroupDownloadTask: DownloadTaskRoot {
    private let downloadTasks: [DownloadTaskProtocol]
    private var taskQueue: [DownloadTaskProtocol]
    private var progressResolution: Int = 100
    
    public init(downloadTasks: [DownloadTaskProtocol], handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil){
        self.taskQueue = downloadTasks
        self.downloadTasks = downloadTasks
        super.init(handler: handler)
        progress.totalUnitCount = Int64(downloadTasks.count * progressResolution)
    }
    
    public convenience init(remoteFiles: [RemoteDownloadable], handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil){
        var downloadTasks: [DownloadTaskProtocol] = []
        for remoteFile in remoteFiles {
            downloadTasks.append(remoteFile.downloadTaskProtocol)
        }
        self.init(downloadTasks: downloadTasks, handler: handler)
    }
    
    public override func nextTask(){
        guard let nextFile = nextDownloadTask else {
            completionStatus = .success(localURL: nil)
            return
        }
        self.progress.addChild(nextFile.progress, withPendingUnitCount: Int64(progressResolution))
        currentChildTask = nextFile
        nextFile.begin()
    }
}

// QUEUE METHODS AND PROPERTIES
extension GroupDownloadTask {
    private var nextDownloadTask: DownloadTaskProtocol? {
        guard taskQueue.count > 0 else { return nil }
        return taskQueue.removeFirst()
    }
}

