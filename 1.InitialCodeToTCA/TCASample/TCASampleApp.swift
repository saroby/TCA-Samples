//
//  TCASampleApp.swift
//  TCASample
//
//  Created by Louis on 5/3/24.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct TCASampleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: ContentFeature.State()) {
                ContentFeature()
            } withDependencies: {
                // dependancy에 접근했을 때 사용되는 default 로직을 사용하지 않고 바꿔 사용 할 수 있다.
                $0.itemDatabase.fetchAll = {
                    let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp)])
                    return try sharedModelContainer.mainContext.fetch(descriptor)
                }
                $0.itemDatabase.add = { item in
                    sharedModelContainer.mainContext.insert(item)
                }
                $0.itemDatabase.delete = { item in
                    sharedModelContainer.mainContext.delete(item)
                }
            })
        }
        .modelContainer(sharedModelContainer) // SwiftData instance의 생성에 사용되는 container 셋팅. 이 값을 넣지 않으면 swiftData Model을 저장할 곳이 없으므로 크러시 발생
    }
}
