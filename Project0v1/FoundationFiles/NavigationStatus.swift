//
//  NavigationStatus.swift
//  Project0v1
//
//  Created by Michael on 3/25/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit

enum NavigationStatus {
    case finished, comitted, homePage
    
    /*var title: String?{
        switch self {
            // case .read: return "Read"
            // case .unread: return "Unread"
        // case .more: return "More"
        case .flag: return "Flag"
        case .trash: return "Trash"
        }
    }
    
    var image: UIImage{
        switch self {
            // case .read, .unread: return
        // case .more: return
        case .flag: return UIImage(named: "Flag")!
        case .trash: return UIImage(named: "Trash")!
        }
    }
    
    var color: UIColor {
        switch self {
            // case .read, .unread: return #colorLiteral(red: 0, green: 0.4577052593, blue: 1, alpha: 1)
        // case .more: return #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
        case .flag: return #colorLiteral(red: 1, green: 0.5803921569, blue: 0, alpha: 1)
        case .trash: return #colorLiteral(red: 1, green: 0.2352941176, blue: 0.1882352941, alpha: 1)
        }
    }*/
}

enum WebviewScrollStatus {
    case intact, comitted, finished
}

