//
//  TabCell.swift
//  Project0v1
//
//  Created by Michael on 2/22/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import WebKit
import Material
class TabCell: UICollectionViewCell {
    
    let titleLabel = UILabel()
    let titleLabel2 = UILabel()
    let imageView = UIImageView()
    let initialX:CGFloat
    
    private var gradient = CAGradientLayer()
    
    override init(frame: CGRect) {
        initialX = frame.midX
        super.init(frame: frame)
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 1.3]
        gradient.frame = contentView.frame
        
        imageView.frame = CGRect(x: contentView.frame.minX, y: contentView.frame.minY - 20, width: contentView.frame.width, height: UIScreen.main.bounds.height - 90)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        titleLabel.frame = CGRect(x: contentView.frame.minX + 10, y: contentView.frame.maxY - 20, width: contentView.frame.width - 20, height: 20)
        titleLabel.textAlignment = .left
        titleLabel.textColor = Color.grey.lighten2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font=UIFont.systemFont(ofSize: 12)
        
        titleLabel2.frame = CGRect(x: contentView.frame.minX + 10, y: contentView.frame.maxY - 50, width: contentView.frame.width - 20, height: 30)
        titleLabel2.textAlignment = .left
        titleLabel2.textColor = Color.grey.lighten3
        titleLabel2.lineBreakMode = .byTruncatingTail
        titleLabel2.font=UIFont.boldSystemFont(ofSize: 24)
        //imageView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        contentView.addSubview(imageView)
        contentView.layer.addSublayer(gradient)
        contentView.addSubview(titleLabel)
        contentView.addSubview(titleLabel2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var image: UIImage = UIImage() {
        didSet {
            imageView.image = image
        }
    }
    
    var imageHeight: CGFloat {
        return (imageView.image?.size.height) ?? 0.0
    }
    
    var imageWidth: CGFloat {
        return (imageView.image?.size.width) ?? 0.0
    }
    
    
    func offset(_ offset: CGPoint) {
        let newFrame = self.imageView.bounds.offsetBy(dx: offset.x, dy: offset.y)
        if newFrame.minY > contentView.frame.minY - 20{
            return
        }
        imageView.frame = newFrame
    }
    
}
