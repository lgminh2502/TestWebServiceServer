//
//  ContentView.swift
//  TestWebServiceServer
//
//  Created by Admin on 16/04/2024.
//

import SwiftUI
import Network

class ViewModel: ObservableObject {
    @Published var serverAddress: String
    @Published var imageAddress: String
    @Published var isServerStarted: Bool = false
    private let server: FileServer
    
    init() {
        server = FileServer(host: NWInterface.InterfaceType.wifi.ipv4, port: 4004)
        let address = "http://\(NWInterface.InterfaceType.wifi.ipv4 ?? "localhost"):\(4004)"
        serverAddress = address
        imageAddress = address.appending("/images")
    }
    
    func startServer() {
        server.start()
        isServerStarted = true
    }
    
    func stopServer() {
        server.stop()
        isServerStarted = false
    }
}

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    var body: some View {
        VStack {
            Group {
                Text("Server Address: \(viewModel.serverAddress)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Images Address: \(viewModel.imageAddress)")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            Spacer()
                .frame(height: 50)
            HStack(spacing: 50) {
                Button(action: {
                    viewModel.startServer()
                }, label: {
                    Text("Start")
                })
                .disabled(viewModel.isServerStarted)
                Button(action: {
                    viewModel.stopServer()
                }, label: {
                    Text("Stop")
                })
                .disabled(!viewModel.isServerStarted)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
