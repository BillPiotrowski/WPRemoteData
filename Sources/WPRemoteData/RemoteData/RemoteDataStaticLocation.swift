//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/16/21.
//

import Promises
import ReactiveSwift

/// Extension describing RemoteData whose RemoteDocument has a StaticLocation, making getAll and addListener accessibly as static methods.
extension RemoteData where
    RemoteDoc: RemoteDataDocumentStaticLocation,
    RemoteDoc == RemoteDoc.StaticLocation.A,
    RemoteDoc == RemoteDoc.Data.RemoteDoc,
    RemoteDoc.StaticLocation == RemoteDoc.Location,
    RemoteDoc.Data == Self
{
    public static func getAll(
        filters: [WhereFilter]? = nil
    ) -> Promises.Promise<ScorepioQueryResponse<RemoteDoc, Self>> {
        Self.RemoteDoc.getAll(filters: filters)
    }
    
    
    public static func addListener(
        filters: [WhereFilter]? = nil
    ) -> (
        ListenerRegistrationInterface,
        Signal<(ScorepioQueryResponse<RemoteDoc, Self>?, Error?), Never>
    ){
        Self.RemoteDoc.addListener(filters: filters)
    }
    
    public static var remoteLocation: RemoteDoc.StaticLocation {
        RemoteDoc.remoteDataLocation
    }
    
    public static func generateID() -> String {
        remoteLocation.generateDocumentID()
    }
}

