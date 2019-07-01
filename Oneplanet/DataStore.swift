//
//  DataStore.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/1.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import RealmSwift

class DataStore {
    static var shared: DataStore!
    
    let realm: Realm
    let operationQueue: OperationQueue
    
    init(realm: Realm, operationQueue: OperationQueue = .current ?? .main) {
        self.realm = realm
        self.operationQueue = operationQueue
    }
    
    @discardableResult func save(_ changeHandler: (()->Void)) -> Bool {
        do {
            try realm.write {
                changeHandler()
            }
            return true
        } catch let error {
            logger.error("[DataStore] Cannot save", context: error)
            return false
        }
    }
    
    @discardableResult func addOrUpdate(_ object: Object) -> Bool {
        return save {
            realm.add(object, update: true)
        }
    }
    
    @discardableResult func delete(_ object: Object) -> Bool {
        return save {
            realm.delete(object)
        }
    }
    
    @discardableResult func delete(_ objects: [Object]) -> Bool {
        if objects.isEmpty {
            return true
        }
        return save {
            realm.delete(objects)
        }
    }
    
    func cleanAll() {
        save {
            realm.deleteAll()
        }
    }
    
    func search<T: Object>(_ selector: ((T)->Bool) ) -> [T] {
        return realm.objects(T.self).filter(selector)
    }
    
}

class PrepareDataStoreOperation: Operation {
    private(set) var dataStore: DataStore?
    private(set) var error: Error?
    private var dbURL: URL!
    
    private func migrate(_ migration: Migration, oldSchemaVersion: UInt64) {
    }
    
    override func main() {
        dbURL = makeRootURL()!.appendingPathComponent("oneplanet.realm")
        if let store = createDataStore() {
            dataStore = store
        } else {
            cleanUpAndTryAgain()
        }
    }
    
    private func makeRootURL() -> URL? {
        guard let docDirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask , true).first else {
            return nil
        }
        let result = URL(fileURLWithPath: docDirPath).appendingPathComponent("App Data")
        return makeDirectoryIfNeeded(at: result)
    }
    
    private func makeDirectoryIfNeeded(at url: URL) -> URL? {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            guard isDir.boolValue else {
                fatalError("\(url) is reserved as a folder for application data")
            }
            return url
        }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            try (url as NSURL).setResourceValues([URLResourceKey.isExcludedFromBackupKey : true])
        } catch let error {
            assertionFailure("\(error)")
            return nil
        }
        return url
    }
    
    private func createDataStore() -> DataStore? {
        let configuration = Realm.Configuration(fileURL: dbURL, schemaVersion: 1, migrationBlock: {[weak self] (migration, oldSchemaVersion) in
            self?.migrate(migration, oldSchemaVersion: oldSchemaVersion)
        })
        do {
            let realm = try Realm(configuration: configuration)
            return DataStore(realm: realm)
        } catch let error {
            logger.error("[PrepareDataStoreOperation] Cannot create realm", context: error)
            self.error = error
            return nil
        }
    }
    
    private func cleanUpAndTryAgain() {
        do {
            try FileManager.default.removeItem(at: dbURL)
            dataStore = createDataStore()
        } catch let error {
            logger.error("[PrepareDataStoreOperation] Cannot remove db file", context: error)
            return
        }
    }
}
