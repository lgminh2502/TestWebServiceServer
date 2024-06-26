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
    let contentType: String
    let data: [EPPhoto]?
    
    init(name: String, baseUrl: String, data: [EPPhoto]? = nil) {
        self.name = name
        self.url = baseUrl.appending("\(name)")
        self.contentType = "text"
        self.data = data
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, url, data
        case contentType = "content_type"
    }
    
}

struct Gallery: Content {
    let images: [EPPhoto]
}

extension Gallery {
    static func createDummyGallery(with baseUrl: String) -> [EPPhoto] {
        [
            EPPhoto(name: "image_1.jpg", baseUrl: baseUrl),
            EPPhoto(name: "image_2.jpg", baseUrl: baseUrl),
            EPPhoto(name: "image_3.jpg", baseUrl: baseUrl, data: [
                EPPhoto(name: "image_1.jpg", baseUrl: baseUrl),
                EPPhoto(name: "image_2.jpg", baseUrl: baseUrl)
            ]),
            EPPhoto(name: "image_4.jpg", baseUrl: baseUrl),
        ]
    }
}

struct FileWebRouteCollection: RouteCollection {
    private let baseUrl: String
    private let dataStore: DataStore
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
        self.dataStore = DataStore(baseUrl: URL(string: baseUrl)!)
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("images") { request in
            print("server baseURL \(request.baseUrl)")
            return Gallery.createDummyGallery(with: request.baseUrl.appending("/image/"))
        }
        routes.get("image", ":filename", use: downloadFileHandler)
        
        routes.get("content") { request in
            guard let id = request.query["id"] as String?,
                  let contentType = request.query["content_type"] as String?,
                  let type = ContentType(value: contentType) else {
                throw Abort(.badRequest)
            }
            if let response = dataStore.getContent(contentId: id, contentType: type) {
                return response
            } else {
                throw Abort(.notFound)
            }
        }
    
        routes.get("image") { request in
            guard let imagePath = request.query["path"] as String? else {
                throw Abort(.badRequest)
            }
            guard let fileUrl = Bundle.main.url(forResource: stripFileExtension(imagePath), withExtension: "jpg") else {
                throw Abort(.notFound)
            }
            return request.fileio.streamFile(at: fileUrl.path)
        }
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

struct ContentInfo: Content {
    var id: String = ""
    var name: String = ""
    var contentType: String = ""
    var orientation: String = ""
    var image: String?
    var interval: Int?
    var imageContain: String?
    var scheduleContents: [ScheduleContent]?
    var playlistContent: [ContentInfo]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, orientation, image, interval
        case contentType = "content_type"
        case imageContain = "image_contain"
        case scheduleContents = "schedule_contents"
        case playlistContent = "playlist_content"
    }
}

struct ScheduleContent: Content {
    var contentInfo: ContentInfo
    var startTime: Float
    var endTime: Float
    
    enum CodingKeys: String, CodingKey {
        case contentInfo = "content_info"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

enum OrientationType: String {
    case portrait
    case landscape
    
    var value: String {
        return self.rawValue.firstCapitalized
    }
}

enum ContentType: String {
    case imageContent
    case canvasContent
    case playlistContent
    case scheduleContent
    
    var value: String {
        return self.rawValue.firstCapitalized
    }
    
    init?(value: String) {
        switch value.lowercased() {
        case ContentType.imageContent.rawValue.lowercased():
            self = .imageContent
        case ContentType.canvasContent.rawValue.lowercased():
            self = .canvasContent
        case ContentType.playlistContent.rawValue.lowercased():
            self = .playlistContent
        case ContentType.scheduleContent.rawValue.lowercased():
            self = .scheduleContent
        default:
            return nil
        }
    }
}

enum ImageContainType: String {
    case cropToFit
    case fitToScreen
    
    var value: String {
        return self.rawValue.firstCapitalized
    }
}

struct DataStore {
    private let baseUrl: URL
    
    let imageContent1: ContentInfo
    let imageContent2: ContentInfo
    
    let canvasContent1: ContentInfo
    let canvasContent2: ContentInfo
    
    let playlistContent: ContentInfo
    let scheduleContent: ContentInfo
    
    init(baseUrl: URL) {
        func buildImageUrl(imageName: String) -> String {
            guard var component = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true) else {
                return ""
            }
            component.path = "/image"
            component.queryItems = [URLQueryItem(name: "path", value: imageName),]
            return component.url?.absoluteString ?? ""
        }
        self.baseUrl = baseUrl
        self.imageContent1 = ContentInfo(id: "image_content_1", name :"Image 1", contentType: ContentType.imageContent.value, orientation: OrientationType.landscape.value, image: buildImageUrl(imageName: "image_1.jpg"), imageContain: ImageContainType.cropToFit.value)
        self.imageContent2 = ContentInfo(id: "image_content_2", name :"Image 4", contentType: ContentType.imageContent.value, orientation: OrientationType.portrait.value, image: buildImageUrl(imageName: "image_2.jpg"), imageContain: ImageContainType.fitToScreen.value)
        
        self.canvasContent1 = ContentInfo(id: "canvas_content_1", name :"Canvas 2", contentType: ContentType.canvasContent.value, orientation: OrientationType.landscape.value, image: buildImageUrl(imageName: "image_3.jpg"), imageContain: ImageContainType.cropToFit.value)
        self.canvasContent2 = ContentInfo(id: "canvas_content_2", name :"Canvas 4", contentType: ContentType.canvasContent.value, orientation: OrientationType.portrait.value, image: buildImageUrl(imageName: "image_4.jpg"), imageContain: ImageContainType.fitToScreen.value)
        
        self.playlistContent = ContentInfo(id: "playlist_content_1", name: "Playlist 1", contentType: ContentType.playlistContent.value, orientation: OrientationType.landscape.value, interval: 5, playlistContent: [ imageContent1, canvasContent1])
        
        self.scheduleContent =  ContentInfo(id: "schedule_content_1", name: "Schedule 1", contentType: ContentType.scheduleContent.value, orientation: OrientationType.landscape.value, scheduleContents: [ScheduleContent(contentInfo: canvasContent2, startTime: 0, endTime: 12), ScheduleContent(contentInfo: imageContent2, startTime: 12, endTime: 24)])
    }
    
    func getContent(contentId: String, contentType: ContentType) -> ContentInfo? {
        switch (contentId, contentType) {
        case ("image_content_1", .imageContent):
            imageContent1
        case ("image_content_2", .imageContent):
            imageContent2
        case ("canvas_content_1", .canvasContent):
            canvasContent1
        case ("canvas_content_2", .canvasContent):
            canvasContent2
        case ("playlist_content_1", .playlistContent):
            playlistContent
        case ("schedule_content_1", .scheduleContent):
            scheduleContent
        default:
            nil
        }
    }
        
}

extension StringProtocol {
    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { return prefix(1).capitalized + dropFirst() }
}
