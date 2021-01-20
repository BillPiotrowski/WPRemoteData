//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/19/21.
//

import Foundation
import SPCommon

enum DownloadTaskError {
    case userCancelled
}
extension DownloadTaskError: ScorepioError {
    var message: String {
        switch self {
        case .userCancelled: return "Download task cancelled."
        }
    }
}
