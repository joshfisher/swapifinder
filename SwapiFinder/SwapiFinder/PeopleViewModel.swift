//
//  FindPersonViewModel.swift
//  Animations
//
//  Created by Joshua Fisher on 4/19/18.
//  Copyright © 2018 Joshua Fisher. All rights reserved.
//

import ReactiveSwift
import Result
import Dwifft

enum PersonCellModel: Equatable {
    case person(name: String, liked: Bool, identifier: URL)
    case loading
    
    static func==(_ lhs: PersonCellModel, _ rhs: PersonCellModel) -> Bool {
        switch (lhs, rhs) {
        case let (.person(a, aLiked, aId), .person(b, bLiked, bId)): return a == b && aLiked == bLiked && aId == bId
        case (.loading, .loading): return true
        default: return false
        }
    }
}

class PeopleViewModel {
    let items: Property<[PersonCellModel]>
    let error: Signal<AnyError, NoError>
    
    private typealias PersonCellModelsResult = Result<[PersonCellModel], AnyError>
    
    private let store: PersonStore
    private let likes: LikesStore

    init(store: PersonStore, likes: LikesStore, refresh: Signal<(), NoError>) {
        self.store = store
        self.likes = likes
        
        // regenerating cell models should happen when
        // 1. the list of people changed, either from reloading, fetching more or searching
        // 2. refresh triggers, probably after liking/unliking
        let merged = SignalProducer.combineLatest(store.people.producer, refresh.producer.prefix(value: ())).map({ $0.0 })
        let updateCellModels = merged.map { result -> [PersonCellModel] in
            switch result {
            case let .success((people, url)):
                var items = people.map { PersonCellModel.person(name: $0.name, liked: likes.contains($0.url), identifier: ($0.url)) }
                if url != nil {
                    items.append(.loading)
                }
                return items
            case .failure:
                return []
            }
        }
        
        items = Property(initial: [], then: updateCellModels)
        
        self.error = store.people.signal.map({ result -> AnyError? in
            switch result {
            case let .failure(error):
                return error
            default:
                return nil
            }
        }).skipNil()
    }
    
    func needsMore() {
        store.nextPage()
    }
    
    func like(_ identfier: URL) {
        likes.like(identfier)
    }
    
    func unlike(_ identifier: URL) {
        likes.unlike(identifier)
    }
}
