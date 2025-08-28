//
//  WellnestApp.swift
//  Wellnest
//
//  Created by Heejung Yang on 7/31/25.
//

import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        LocalNotiManager.shared.localNotiDelegate()
        return true
    }
}

@main
struct WellnestApp: App {
    let container = CoreDataStack.shared
    
    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(\.managedObjectContext, container.viewContext)
        }
    }
}
