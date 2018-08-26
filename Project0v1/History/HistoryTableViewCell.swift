//
//  HistoryTableViewCell.swift
//  Project0v1
//
//  Created by Michael on 3/9/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material
import SwipeCellKit

class HistoryTableViewCell: TableViewCell {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80)
        self.selectionStyle = .gray
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

