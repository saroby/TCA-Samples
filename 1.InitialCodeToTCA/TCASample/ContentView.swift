//
//  ContentView.swift
//  TCASample
//
//  Created by Louis on 5/3/24.
//

import SwiftUI
import SwiftData
import ComposableArchitecture


struct ItemDatabase {
    var fetchAll: () throws -> [Item]
    var add: (Item) throws -> Void
    var delete: (Item) throws -> Void
    
}

extension ItemDatabase: DependencyKey {
    static let liveValue = Self.init { // dependancy에 접근했을 때 사용되는 default 로직을 구현
        return []
    } add: { item in
    } delete: { item in
    }
}

extension DependencyValues {
    var itemDatabase: ItemDatabase {
        get { self[ItemDatabase.self] }
        set { self[ItemDatabase.self] = newValue }
    }
}

@Reducer
struct ContentFeature {
    @Dependency(\.itemDatabase) var itemDatabase
    
    @ObservableState
    struct State: Equatable {
        var items: [Item] = []
    }
    
    enum Action {
        case fetchAll
        case addItem
        case deleteItems(offsets: IndexSet)
        case add(Item)
        case delete(Item)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchAll:
                return .run { send in
                    let items = try itemDatabase.fetchAll()
                    for item in items {
                        await send(.add(item))
                    }
                }
            case .addItem:
                return .run { send in
                    let item = Item(timestamp: Date())
                    try itemDatabase.add(item)
                    await send(.add(item))
                }
            case .deleteItems(let offsets):
                return .run { [items = offsets.map { state.items[$0] }] send in
                    for item in items {
                        try itemDatabase.delete(item)
                        await send(.delete(item))
                    }
                }
            case .add(let item):
                state.items.append(item)
                return .none
            case .delete(let item):
                if let index = state.items.firstIndex(of: item) {
                    state.items.remove(at: index)
                }
                return .none
            }
        }
    }
}


struct ContentView: View {
    let store: StoreOf<ContentFeature>
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(store.items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete {
                    store.send(.deleteItems(offsets: $0), animation: .default)
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button {
                        store.send(.addItem, animation: .default)
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                store.send(.fetchAll)
            }
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    ContentView(store: .init(initialState: ContentFeature.State(), reducer: { ContentFeature() }, withDependencies: { dependencies in
        //        dependencies.itemDatabase.
    }))
    .modelContainer(for: Item.self, inMemory: true)
}
