//
//  AppSnackBarController.swift
//  Project0v1
//
//  Created by Michael on 3/21/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material

class AppSnackbarController: SnackbarController {
    open override func prepare() {
        super.prepare()
        //delegate = self
    }
}

extension FavTableViewController{
    /*
    func prepareUndoButton() {
        undoButton = FlatButton(title: "Undo", titleColor: Color.yellow.base)
        undoButton.pulseAnimation = .backing
        undoButton.titleLabel?.font = snackbarController?.snackbar.textLabel.font
    }
    
    func prepareSnackbar() {
        guard let snackbar = snackbarController?.snackbar else {
            return
        }
        
        snackbar.text = "Reminder saved."
        snackbar.rightViews = [undoButton]
    }
    
    func animateSnackbar() {
        guard let sc = snackbarController else {
            return
        }
        sc.snackbar.text = "Remind123123er saved."
        _ = sc.animate(snackbar: .visible, delay: 1)
        _ = sc.animate(snackbar: .hidden, delay: 3)
    }*/
}
