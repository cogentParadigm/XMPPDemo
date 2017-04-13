//
//  MessagesTableViewCell.swift
//  XMPPDemo
//
//  Created by Ali Gangji on 4/12/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import UIKit

class MessagesTableViewCell: UITableViewCell {
    
    lazy var primaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var secondaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var rightLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var photoView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 15
        return image
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(photoView)
        contentView.addSubview(primaryLabel)
        contentView.addSubview(secondaryLabel)
        contentView.addSubview(rightLabel)
        
        photoView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        photoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        photoView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        photoView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        primaryLabel.leftAnchor.constraint(equalTo: photoView.rightAnchor, constant: 16).isActive = true
        primaryLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        primaryLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        
        secondaryLabel.leftAnchor.constraint(equalTo: photoView.rightAnchor, constant: 16).isActive = true
        secondaryLabel.topAnchor.constraint(equalTo: primaryLabel.bottomAnchor, constant: 0).isActive = true
        secondaryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
        
        rightLabel.leftAnchor.constraint(equalTo: secondaryLabel.rightAnchor, constant: 10).isActive = true
        rightLabel.topAnchor.constraint(equalTo: primaryLabel.bottomAnchor, constant:0).isActive = true
        rightLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        rightLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func markUnread() {
        primaryLabel.font = UIFont.boldSystemFont(ofSize: 14)
        secondaryLabel.font = UIFont.boldSystemFont(ofSize: 12)
        rightLabel.font = UIFont.boldSystemFont(ofSize: 12)
    }
    
    func markRead() {
        primaryLabel.font = UIFont.systemFont(ofSize: 14)
        secondaryLabel.font = UIFont.systemFont(ofSize: 12)
        rightLabel.font = UIFont.systemFont(ofSize: 12)
    }
    
}
