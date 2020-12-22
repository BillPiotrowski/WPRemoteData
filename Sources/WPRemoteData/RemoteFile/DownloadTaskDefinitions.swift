//
//  DownloadTaskDefinitions.swift
//  RemoteFile
//
//  Created by William Piotrowski on 6/29/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//
/*
import Foundation

public protocol DownloadTaskProtocol {
    var progress: Progress { get }
    var snapshot: DownloadTaskSnapshot { get }
    var hardRefresh: Bool { get set }
    var uid: String { get }
    
    var completionCallback: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? { get set }
    
    func begin()
    func pause()
    func resume()
    func cancel()
    
    func removeObserver(withHandle: String)
    func removeAllObservers(for: DownloadTaskRoot.Observable)
    func removeAllObservers()
    func observe (_ status: DownloadTaskRoot.Observable, handler: @escaping (_ snapshot: DownloadTaskSnapshot) -> Void) -> String
}

public struct DownloadTaskSnapshot {
    public let progress: Progress
    public let error: Error?
    //let metadata:
    let task: DownloadTaskProtocol
    let currentChildTask: DownloadTaskProtocol?
    let completedChildTaskSnapshots: [DownloadTaskSnapshot]
}

*/
