//
//  LoadingCell.swift
//  Animations
//
//  Created by Joshua Fisher on 4/17/18.
//  Copyright © 2018 Joshua Fisher. All rights reserved.
//

import UIKit

class LoadingCell: UITableViewCell {
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(indicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        indicator.startAnimating()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        indicator.center = contentView.center
    }
}
