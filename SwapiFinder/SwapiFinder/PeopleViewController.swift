//
//  SelectKindViewController.swift
//  Animations
//
//  Created by Joshua Fisher on 4/15/18.
//  Copyright © 2018 Joshua Fisher. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import Result
import Dwifft

class PeopleViewController: UITableViewController {
    private let viewModel: PeopleViewModel
    
    init(viewModel: PeopleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 64
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        viewModel.items.producer
            .observe(on: QueueScheduler.main)
            .combinePrevious([])
            .map(Dwifft.diff)
            .startWithValues(update(with:))
        
        viewModel.error.observe(on: QueueScheduler.main).observeValues { [unowned self] error in
            let alert = UIAlertController(title: "Could not fetch people from SWAPI", message: "\(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction.ok)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func update(with diff: [DiffStep<PersonCellModel>]) {
        let inserts = diff.filter({ $0.isInsert }).sorted(by: { $0.idx < $1.idx }).map({ IndexPath(row: $0.idx, section: 0) })
        let deletes = diff.filter({ !$0.isInsert }).sorted(by: { $0.idx < $1.idx }).map({ IndexPath(row: $0.idx, section: 0) })
        
        tableView.beginUpdates()
        tableView.deleteRows(at: deletes, with: .automatic)
        tableView.insertRows(at: inserts, with: .left)
        tableView.endUpdates()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.items.value[indexPath.row]
        switch model {
        case let .person(name, liked, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier, for: indexPath)
            if liked {
                cell.textLabel?.attributedText = .liked(name)
            } else {
                cell.textLabel?.text = name
            }
            return cell

        case .loading:
            return tableView.dequeueReusableCell(withIdentifier: LoadingCell.identifier, for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell is LoadingCell {
            viewModel.needsMore()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if case .person = viewModel.items.value[indexPath.row] {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard case let .person(_, liked, id) = viewModel.items.value[indexPath.row] else {
            return nil
        }
        
        if liked {
            return [UITableViewRowAction(style: .default, title: "Unlike") { _, _ in
                self.viewModel.unlike(id)
            }]
        } else {
            return [UITableViewRowAction(style: .default, title: "Like") { _, _ in
                self.viewModel.like(id)
            }]
        }
    }
}

extension DiffStep {
    var isInsert: Bool { if case .insert = self { return true }; return false }
}

extension NSAttributedString {
    static func liked(_ name: String) -> NSAttributedString {
        return NSAttributedString(string: name, attributes: [.foregroundColor: UIColor.red])
    }
}
