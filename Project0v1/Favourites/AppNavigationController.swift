//
//  AppNavigationController.swift
//  Project0v1
//
//  Created by Michael on 3/11/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material
import Motion

class AppNavigationController: NavigationController {
    var moveMode = false
    var moveList:FavTableViewController?
    
    open override func prepare() {
        super.prepare()
        
        guard let v = navigationBar as? NavigationBar else {
            return
        }
        self.view.transition(.translate(x: 0, y: UIScreen.main.bounds.height*2),
                             .duration(0.36))
        v.depthPreset = .depth1
        v.dividerColor = Color.grey.lighten2
    }
}

