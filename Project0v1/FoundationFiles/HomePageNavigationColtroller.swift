//
//  HomePageNavigationController.swift
//  Project0v1
//
//  Created by Michael on 3/29/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material
import Motion

class HomePageNavigationController: UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        isMotionEnabled = true
        self.view.transition(.scale(0.95),
                             .fadeOut)
    }
}
