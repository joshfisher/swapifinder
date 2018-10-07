//
//  FindPersonViewController.swift
//  Animations
//
//  Created by Joshua Fisher on 4/20/18.
//  Copyright © 2018 Joshua Fisher. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import Result

class FindPersonViewController: UINavigationController {
    let searchController: UISearchController

    let likesStore = LikesStore()
    
    let allPeopleStore = AllPeopleStore()
    let allPeopleViewModel: PeopleViewModel
    let peopleViewController: PeopleViewController
    
    let searchStore = SearchPersonStore()
    let searchViewModel: PeopleViewModel
    let searchResultsViewController: PeopleViewController
    
    init() {
        allPeopleViewModel = PeopleViewModel(store: allPeopleStore, likes: likesStore, refresh: likesStore.updated)
        peopleViewController = PeopleViewController(viewModel: allPeopleViewModel)
        
        searchViewModel = PeopleViewModel(store: searchStore, likes: likesStore, refresh: likesStore.updated)
        searchResultsViewController = PeopleViewController(viewModel: searchViewModel)
        searchController = UISearchController(searchResultsController: searchResultsViewController)
        
        allPeopleStore.reload()
        
        super.init(nibName: nil, bundle: nil)
        
        viewControllers = [peopleViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchBar.reactive.continuousTextValues.observeValues(searchStore.search(for:))

        peopleViewController.definesPresentationContext = true
        peopleViewController.navigationItem.searchController = searchController
        peopleViewController.navigationItem.title = "SWAPI People"

        let refresh = UIRefreshControl()
        refresh.reactive.refresh = CocoaAction(Action<(), (), NoError> { [unowned self] _ in
            SignalProducer(self.allPeopleStore.reload)
        })
        peopleViewController.tableView.refreshControl = refresh
    }
}
