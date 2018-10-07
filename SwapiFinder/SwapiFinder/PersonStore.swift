//
//  PersonStore.swift
//  Animations
//
//  Created by Joshua Fisher on 4/18/18.
//  Copyright © 2018 Joshua Fisher. All rights reserved.
//

import ReactiveSwift
import Result

typealias PeoplePage = (people: [SWAPI.Person], next: URL?)
typealias PeopleResult = Result<PeoplePage, AnyError>

// fetch a page of people from url
private func fetchPeople(from url: URL) -> SignalProducer<PeopleResult, NoError> {
    let request = URLRequest(url: url)
    return URLSession.shared.reactive.data(with: request)
        // try a few times
        .retry(upTo: 3)
        // try to transform the response data into `PeopleResult`
        // throw api error, if any
        .attemptMap({ (data, response) -> PeopleResult in
            let httpResponse = response as! HTTPURLResponse
            if 200 ... 300 ~= httpResponse.statusCode {
                let result = try JSONDecoder().decode(SWAPI.Results<SWAPI.Person>.self, from: data)
                let page = PeoplePage(people: result.results, next: result.next)
                return .success(page)
            } else {
                throw SWAPI.Error(httpResponse.statusCode)
            }
        })
        // convert either transport or api error into `PeopleResult.failure`
        .flatMapError({ error -> SignalProducer<PeopleResult, NoError> in
            return SignalProducer(value: .failure(AnyError(error)))
        })
}

// recursive func to combine people fetched so far with subsequent pages
private func fetchPeople(from url: URL, combiningWith previousPeople: [SWAPI.Person], nextTrigger: Signal<(), NoError>) -> SignalProducer<PeopleResult, NoError> {
    // fetch a page of people, `.flatMap(.concat, ...)` because it doesn't make sense to interrupt fetching next page in order to fetch the page after that
    return fetchPeople(from: url).flatMap(.concat, { results -> SignalProducer<PeopleResult, NoError> in
        if case let .success(ppl, next) = results {
            // combine with people we've already fetched
            let peopleSoFar = previousPeople + ppl
            if let next = next {
                // THIS IS THE INTERESTING PART
                // returns a `.flatten(.concat)`ed compound SignalProducer that
                // 1. sends value with the result of all the people fetched so far
                // 2. waits forever for `nextTrigger` value
                // 3. then, after `nextTrigger`, fetch the next page inside a whole new set of `SignalProducer`s that do the same thing
                return SignalProducer([
                    SignalProducer(value: .success((peopleSoFar, next))),
                    SignalProducer.never.take(until: nextTrigger),
                    fetchPeople(from: next, combiningWith: peopleSoFar, nextTrigger: nextTrigger)
                ]).flatten(.concat)
            } else {
                // last page, send the results
                return SignalProducer(value: .success((peopleSoFar, nil)))
            }
        } else {
            // failed for some reason
            return SignalProducer(value: results)
        }
    })
}

protocol PersonStore {
    var people: Property<PeopleResult> { get }
    func reload()
    func nextPage()
}

class AllPeopleStore: PersonStore {
    let people: Property<PeopleResult>
    
    private let reloadSig, nextPageSig: Signal<(), NoError>
    private let reloadObs, nextPageObs: Signal<(), NoError>.Observer
    
    init() {
        let (reloadSig, reloadObs) = Signal<(), NoError>.pipe()
        let (nextPageSig, nextPageObs) = Signal<(), NoError>.pipe()
        
        // reload signal values interrupts internal signal producers, resetting the list of already-fetched people (bc `.flatMap(.latest, ...)`)
        let values = reloadSig.flatMap(.latest, { _ in fetchPeople(from: SWAPI.peopleUrl, combiningWith: [], nextTrigger: nextPageSig) })

        people = Property(initial: .success(([], nil)), then: values)
        (self.reloadSig, self.reloadObs) = (reloadSig, reloadObs)
        (self.nextPageSig, self.nextPageObs) = (nextPageSig, nextPageObs)
    }
    
    func reload() {
        reloadObs.send(value: ())
    }
    
    func nextPage() {
        nextPageObs.send(value: ())
    }
}

class SearchPersonStore: PersonStore {
    let people: Property<PeopleResult>
    
    private let searchSig: Signal<String?, NoError>
    private let searchObs: Signal<String?, NoError>.Observer
    
    private let nextPageSig: Signal<(), NoError>
    private let nextPageObs: Signal<(), NoError>.Observer
    
    init() {
        let (searchSig, searchObs) = Signal<String?, NoError>.pipe()
        let (nextPageSig, nextPageObs) = Signal<(), NoError>.pipe()
        
        let values = searchSig
            .flatMap(.latest, { query -> SignalProducer<PeopleResult, NoError> in
                guard let query = query, query.count > 2 else {
                    return SignalProducer(value: .success(([], nil)))
                }
                return fetchPeople(from: SWAPI.peopleSeachUrl(query: query), combiningWith: [], nextTrigger: nextPageSig)
            })
        
        people = Property(initial: .success(([], nil)), then: values)
        
        (self.searchSig, self.searchObs) = (searchSig, searchObs)
        (self.nextPageSig, self.nextPageObs) = (nextPageSig, nextPageObs)
    }
    
    func search(for query: String?) {
        searchObs.send(value: query)
    }
    
    func reload() {
        searchObs.send(value: nil)
    }
    
    func nextPage() {
        nextPageObs.send(value: ())
    }
}
