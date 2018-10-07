//
//  LikeStore.swift
//  Animations
//
//  Created by Joshua Fisher on 4/25/18.
//  Copyright © 2018 Joshua Fisher. All rights reserved.
//

import ReactiveSwift
import Result

class LikesStore {
    let updated: Signal<(), NoError>
    
    private var likes = Set<URL>()
    private let updatedObs: Signal<(), NoError>.Observer
    
    init() {
        (updated, updatedObs) = Signal<(), NoError>.pipe()
    }
    
    func contains(_ identifier: URL) -> Bool {
        return likes.contains(identifier)
    }
    
    func like(_ identifier: URL) {
        likes.insert(identifier)
        updatedObs.send(value: ())
    }
    
    func unlike(_ identifier: URL) {
        likes.remove(identifier)
        updatedObs.send(value: ())
    }
}
