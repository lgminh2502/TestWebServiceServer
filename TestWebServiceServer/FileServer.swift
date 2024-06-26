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

// Prints hello during boot.
struct HelloLifecycleHandler: LifecycleHandler {
    // Called before application boots.
    func willBoot(_ app: Application) throws {
        app.logger.info("Hello!")
    }

    // Called after application boots.
    func didBoot(_ app: Application) throws {
        app.logger.info("Server is running")
    }

    // Called before application shutdown.
    func shutdown(_ app: Application) {
        app.logger.info("Goodbye!")
    }
}

struct Hello: Content {
    var name: String?
    
    // Runs after this Content is decoded. `mutating` is only required for structs, not classes.
    mutating func afterDecode() throws {
        // Name may not be passed in, but if it is, then it can't be an empty string.
        self.name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name = self.name, name.isEmpty {
            throw Abort(.badRequest, reason: "Name must not be empty.")
        }
    }

    // Runs before this Content is encoded. `mutating` is only required for structs, not classes.
    mutating func beforeEncode() throws {
        // Have to *always* pass a name back, and it can't be an empty string.
        guard
            let name = self.name?.trimmingCharacters(in: .whitespacesAndNewlines),
            !name.isEmpty
        else {
            throw Abort(.badRequest, reason: "Name must not be empty.")
        }
        self.name = name
    }
}

struct HTML {
  let value: String
}

extension HTML: ResponseEncodable {
  public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/html")
    return request.eventLoop.makeSucceededFuture(.init(
      status: .ok, headers: headers, body: .init(string: value)
    ))
  }
}

extension Environment {
    static var tls: Environment { .custom(name: "tls") }
}

class FileServer: ObservableObject {
    var app: Application
    let host: String?
    let port: Int
    
    @Published var fileURLs: [URL] = []
    
    init(host: String?, port: Int) {
        self.host = host
        self.port = port
        app = Application(.tls)
//        app.lifecycle.use(HelloLifecycleHandler())
        // Add lifecycle handler.
//        let encryptedCert = Obfuscator.obfuscate(Constants.cert)
//        print("\(encryptedCert)")
//        
//        let decryptedCert = Obfuscator.deObfuscate(encryptedCert)
//        print("\(decryptedCert)")
//        
//        let encryptedKey = Obfuscator.obfuscate(Constants.key)
//        print("\(encryptedKey)")
//        
//        let decryptedKey = Obfuscator.deObfuscate(encryptedKey)
//        print("\(decryptedKey)")
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
//        guard let serverCertPath = Bundle.main.path(forResource: "crt", ofType: "pem"),
//              let serverKeyPath = Bundle.main.path(forResource: "key", ofType: "pem") else {
//            print("No certificates found")
//            return
//        }
        do {
            
//            let encryptedCert = Obfuscator.obfuscate(Constants.cert)
//            print("\(encryptedCert)")
//            
//            let decryptedCert = Obfuscator.deObfuscate(encryptedCert)
//            print("\(decryptedCert)")
//            
//            let encryptedKey = Obfuscator.obfuscate(Constants.key)
//            print("\(encryptedKey)")
//            
//            let decryptedKey = Obfuscator.deObfuscate(encryptedKey)
//            print("\(decryptedKey)")
            
//            let certificateChain = try NIOSSLCertificate.fromPEMBytes(Array(decryptedCert.utf8)).map { NIOSSLCertificateSource.certificate($0) }
//            let privateKey = try NIOSSLPrivateKeySource.privateKey( .init(bytes: Array(decryptedKey.utf8), format: .pem))
//
//            let certificateChain = try NIOSSLCertificate.fromPEMBytes(Array(Secrets.cert.utf8)).map { NIOSSLCertificateSource.certificate($0) }
//            let privateKey = try NIOSSLPrivateKeySource.privateKey( .init(bytes: Array(Secrets.key.utf8), format: .pem))
//            
//            app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
//                certificateChain: certificateChain,
//                privateKey: privateKey
//            )
            // Enable TLS.
//            app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
//                certificateChain: try NIOSSLCertificate.fromPEMFile(serverCertPath).map { .certificate($0) },
//                privateKey: .file(serverKeyPath)
//            )
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
                
                app.get("hello1") { req in
//                    let hello = try req.query.decode(Hello.self)
//                    
//                    let res = Response()
//                    try res.content.encode(hello, as: .html)
//                    
//                    return hello
                    return HTML(value: """
                      <html>
                        <body>
                          <h1>Hello, World!</h1>
                        </body>
                      </html>
                      """)
                }
                
                // Me and my sadistic sense of humor.
                ContentConfiguration.global.use(decoder: try! ContentConfiguration.global.requireDecoder(for: .json), for: .xml)
                
//                app.get("hello") { req -> String in
//                    let hello = try req.query.decode(Hello.self)
//                    return "Hello, \(hello.name ?? "Anonymous")"
//                }
                
//                app.get("hello") { req async -> String in
//                    "Hello, world!"
//                }
                app.get("hello", "name") { req -> String in
                    let name = req.parameters.get("name")
//                    let name2 = req.parameters.get("text")
                    return "Hello, \(name ?? "Anonymous")"
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
                    guard let locaton = req.parameters.get("location"),
                          let region = req.parameters.get("region") else {
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
                    guard let keyword = req.query["keyword"] as String?,
                          let page = req.query["page"] as String? else {
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
                
                try app.register(collection: FileWebRouteCollection(baseUrl: app.baseUrl))
                
//                app.lifecycle.use(HelloLifecycleHandler())
                try app.server.start()
                app.server.onShutdown.whenComplete { result in
                    print("onShutdown result \(result)")
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func stop() {
        // Request server shutdown.
        app.server.shutdown()
        // Wait for the server to shutdown.
//        do {
//            try app.server.onShutdown.wait()
//        } catch {
//            print("error \(error)")
//        }
//        app.shutdown()
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

enum Obfuscator {

  /// deobfuscate the bytes array `obfuscatedChars` to the key using the `cipher` string.
  ///
  /// - parameter cipher: The key that will be used to deobfuscate the bytes array.
  /// - parameter obfuscatedChars: The bytes array to deobfuscate
  ///
  static func deObfuscate(_ obfuscatedChars: [UInt8], _ cipher: String = "$$$key") -> String {
    let cipher = [UInt8](cipher.utf8)
    var bytes = [UInt8]()
    obfuscatedChars.enumerated().forEach { item in
      bytes.append(item.element ^ cipher[item.offset % cipher.count])
    }
    return String(bytes: bytes, encoding: .utf8)!
  }

  static func obfuscate(_ string: String, _ cipher: String = "$$$key") -> [UInt8] {
    let cipher = [UInt8](cipher.utf8)
    var bytes = [UInt8]()
    ([UInt8](string.utf8)).enumerated().forEach { item in
      bytes.append(item.element ^ cipher[item.offset % cipher.count])
    }
    return bytes
  }
}

