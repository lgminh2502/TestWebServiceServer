//
//  FileServer.swift
//  TestWebServiceServer
//
//  Created by Admin on 16/04/2024.
//

import Foundation
import Vapor
import Network

class FileServer: ObservableObject {
    private var app: Application
    let host: String?
    let port: Int
    
    @Published var fileURLs: [URL] = []
    
    init(host: String?, port: Int) {
        self.host = host
        self.port = port
        app = Application(.development)
    }
    
    var baseUrl: String {
        return app.baseUrl
    }
    
    private func configure(_ app: Application) {
        if let host {
            app.http.server.configuration.hostname = host
        }
        app.http.server.configuration.port = port
        app.routes.defaultMaxBodySize = "50MB"
    }
    
    func start() {
        Task(priority: .background) {
            do {
                configure(app)
                try app.register(collection: FileWebRouteCollection())
                try await app.execute()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func stop() {
        app.http.server.shared.shutdown()
    }
    
    func loadFiles() {
        do {
            let documentsDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false)
            let fileUrls = try FileManager.default.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles)
            self.fileURLs = fileUrls
        } catch {
            print(error)
        }
    }
    
    func deleteFile(at offsets: IndexSet) {
        let urlsToDelete = offsets.map { fileURLs[$0] }
        fileURLs.remove(atOffsets: offsets)
        for url in urlsToDelete {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
