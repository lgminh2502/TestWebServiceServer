//
//  FileServer.swift
//  TestWebServiceServer
//
//  Created by Admin on 16/04/2024.
//

import Foundation
import Vapor
import Network
import NIOSSL

extension Environment {
    static var tls: Environment { .custom(name: "tls") }
}

class FileServer: ObservableObject {
    private var app: Application
    let host: String?
    let port: Int
    
    @Published var fileURLs: [URL] = []
    
    init(host: String?, port: Int) {
        self.host = host
        self.port = port
        app = Application(.tls)
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
        guard let serverCertPath = Bundle.main.path(forResource: "crt", ofType: "pem"),
              let serverKeyPath = Bundle.main.path(forResource: "key", ofType: "pem") else {
            print("No certificates found")
            return
        }
        do {
            // Enable TLS.
            app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
                certificateChain: try NIOSSLCertificate.fromPEMFile(serverCertPath).map { .certificate($0) },
                privateKey: .file(serverKeyPath)
            )
        } catch {
            print("TLS configuration error \(error)")
        }
    }
    
    func start() {
        Task(priority: .background) {
            do {
                configure(app)
                app.get { req async in
                    "It works!"
                }
                
                app.get("hello") { req async -> String in
                    "Hello, world!"
                }
                
                app.get("restaurants", "speciality", "chinese") { req async -> String in
                    "restaurants/speciality/chinese"
                }
                
                app.get("restaurants", "speciality", "indian") { req async -> String in
                    "restaurants/speciality/indian"
                }
                
                app.get("restaurants", "speciality", "thai") { req async -> String in
                    "restaurants/speciality/thai"
                }
                
                app.get("restaurants", "speciality", ":region") { req -> String in
                    guard let region = req.parameters.get("region") else {
                        throw Abort(.badRequest)
                    }
                    return "restaurants/speciality/\(region)"
                }
                
                app.get("restaurants", ":location", "speciality", ":region") { req -> String in
                    guard let locaton = req.parameters.get("location"), let region = req.parameters.get("region") else {
                        throw Abort(.badRequest)
                    }
                    return "restaurants in \(locaton) with speciality \(region)"
                }
                
                app.get("routeany", "*", "endpoint") { req -> String in
                    return "This is anything route"
                }
                
                app.get("routeany", "*") { req -> String in
                    return "This is Catch All route zzz"
                }
                
                app.get("routeany", "**") { req -> String in
                    return "This is Catch All route"
                }
                
                app.get("search") { req -> String in
                    guard let keyword = req.query["keyword"] as String?, let page = req.query["page"] as String? else {
                        throw Abort(.badRequest)
                    }
                    return "Search for Keyword \(keyword) on Page \(page)"
                }
                
                let restaurants = app.grouped("restaurants")
                
                restaurants.get { req -> String in
                    return "restaurants base route"
                }
                
                restaurants.get("starRating", ":stars") { req -> String in
                    guard let stars = req.parameters.get("stars") else {
                        throw Abort(.badRequest)
                    }
                    return "restaurants/starRating/\(stars)"
                }
                try app.register(collection: FileWebRouteCollection())
                try app.server.start()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func stop() {
        // Request server shutdown.
        app.server.shutdown()
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
