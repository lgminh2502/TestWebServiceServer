//
//  FileWebRouteCollection.swift
//  TestWebServiceServer
//
//  Created by Admin on 16/04/2024.
//

import Vapor

struct EPPhoto: Content {
    var id: UUID = UUID()
    let name: String
    let url: String
    
    init(name: String, baseUrl: String) {
        self.name = name
        self.url = baseUrl.appending("\(name)")
    }
}

struct Gallery: Content {
    let images: [EPPhoto]
}

extension Gallery {
    static func createDummyGallery(with baseUrl: String) -> [EPPhoto] {
        [
            EPPhoto(name: "chuttersnap-piQY2YNDJ8k-unsplash.jpg", baseUrl: baseUrl),
            EPPhoto(name: "leonard-von-bibra-hep72i867oI-unsplash.jpg", baseUrl: baseUrl),
        ]
    }
}

struct FileWebRouteCollection: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get { request -> String in
            return "Hello"
        }
        routes.get("images") { request in
            print("server baseURL \(request.baseUrl)")
            return Gallery.createDummyGallery(with: request.baseUrl.appending("/image/"))
        }
        routes.get("image", ":filename", use: downloadFileHandler)
    }
    
    func downloadFileHandler(_ req: Request) throws -> Response {
        guard let filename = req.parameters.get("filename"),
              let fileUrl = Bundle.main.url(forResource: stripFileExtension(filename), withExtension: "jpg") else {
            throw Abort(.badRequest)
        }
        return req.fileio.streamFile(at: fileUrl.path)
    }
    
    private func stripFileExtension( _ filename: String ) -> String {
        var components = filename.components(separatedBy: ".")
        guard components.count > 1 else { return filename }
        components.removeLast()
        return components.joined(separator: ".")
    }
}

struct FileContext: Encodable {
    var filenames: [String]
}

struct FileUploadPostData: Content {
    var file: File
}

import Foundation

extension URL {
    static func documentsDirectory() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false)
    }
    
    func visibleContents() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles)
    }
}

extension Request {
    var baseUrl: String {
        return application.baseUrl
    }
}

extension Application {
    var baseUrl: String {
        let configuration = self.http.server.configuration
        let scheme = configuration.tlsConfiguration == nil ? "http" : "https"
        let host = configuration.hostname
        let port = configuration.port
        return "\(scheme)://\(host):\(port)"
    }
}
