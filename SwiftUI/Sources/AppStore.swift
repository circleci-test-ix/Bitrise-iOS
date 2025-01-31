import APIKit
import Combine
import Core
import Foundation
import SwiftUI

final class AppStore: ObservableObject {
    var objectWillChange = PassthroughSubject<AppStore, Never>()

    var apps: [App] = [] {
        didSet {
            objectWillChange.send(self)
        }
    }

    init(apps: [App] = []) {
        self.apps = apps

        let req = MeAppsRequest()
        Session.shared.send(req) { [weak self] r in
            switch r {
            case .success(let res):
                self?.apps = res.data
            case .failure(let error):
                print("\(error)")
            }
        }
    }
}

typealias App = MeApps.App

extension App: Identifiable {
    public var id: String {
        return slug
    }
}
