//
//  BrewBarApp.swift
//  BrewBar
//
//  Created by Thomas on 16/02/2021.
//

import Combine
import SwiftUI

@main
struct BrewBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusBarItem: NSStatusItem?
    let menu = NSMenu()
    
    @ObservedObject var outdatedApps = ListOfOutdatedApps()
    
    private var activeCancellable: AnyCancellable?
    
    override init() {
        super.init()
        self.subscribe()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        menu.delegate = self
        
        // Set view
        let contentView = ContentView().environmentObject(outdatedApps)
        let menuItem = NSMenuItem()
        let view = NSHostingView(rootView: contentView)
        view.frame = NSRect(x: 0, y: 0, width: 500, height: 500)
        menuItem.view = view
        menu.addItem(menuItem)
        menu.addItem(NSMenuItem(title: "Quit Silicon Info", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // Set initial app icon
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        self.upStatusBar()
    }
    
    
    func upStatusBar() {
        let itemImage = outdatedApps.iconApp
        itemImage.isTemplate = true
        statusBarItem?.button?.title = outdatedApps.statusText
        statusBarItem?.menu = menu
    }
    
    func subscribe() {
        activeCancellable = outdatedApps.$isLoaded.sink {_ in
            self.upStatusBar()
        }
    }
}

struct BrewAppVersions: Identifiable {
    let id = UUID()
    let appName: String
    let oldVersion: String
    let newVersion: String
}

class ListOfOutdatedApps: ObservableObject {
    @Published var isLoaded: Bool = false
    @Published var list: [BrewAppVersions] = []
    @Published var iconApp: NSImage = NSImage(named: "processor-icon") ?? NSImage()
    @Published var statusText: String = "Brew"
    
    init() {
        checkOutdatedApps()
    }
    
    func checkOutdatedApps() {
        DispatchQueue.global(qos: .background).async {
            print("avant")
            
            let outdatedList: String = self.shell2("/opt/homebrew/bin/brew livecheck --installed --newer-only -q")
            //            let outdatedList = """
            //            brave-browser : 88.1.20.103,120.103 ==> 88.1.20.108,120.108
            //            icu4c : 67.1 ==> 68.2
            //            openjdk : 15.0.1 ==> 15.0.2
            //            openssl@1.1 : 1.1.1i ==> 1.1.1j
            //            """
            var appList: [BrewAppVersions] = []
            
            // split lines and apps versions
            outdatedList.split(separator: "\n").forEach { line in
                let infos = line.split(separator: " ")
                appList.append(BrewAppVersions(appName: String(infos[0] ), oldVersion: String(infos[2] ), newVersion: String(infos[4] )))
            }
            
            DispatchQueue.main.async {
                self.list = appList
                self.iconApp = NSImage(named: "processor-icon-empty") ?? NSImage()
                self.statusText = "Brew Outdated"
                self.isLoaded = true
            }
            
            print("fin")
        }
    }
    
    func upgradeApps() {
        DispatchQueue.global(qos: .background).async {
            print("avant up")
            let waitForIt = self.shell2("/opt/homebrew/bin/brew upgrade")
            print(waitForIt)
            self.checkOutdatedApps()
            print("fin up")
        }
    }
    
    private func shell2(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
}
