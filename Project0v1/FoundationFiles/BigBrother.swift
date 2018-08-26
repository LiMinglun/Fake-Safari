//  xietianziyilingzhuhou
//  BigBrother(tianzi).swift
//  Project0v1
//
//  Created by Michael on 2/22/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material

class BigBrother: ToolbarController {
    let userPath = NSHomeDirectory() + "/Documents/.Usr/"
    let userPreferencePath = NSHomeDirectory() + "/Documents/.Usr/" + "UserPreferences.plist"
    
    open override func prepare() {
        super.prepare()
        prepareStatusBar()
        prepareToolbar()
    }
    
    public func readPreference()->[String:String]{
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: userPath){
            try! fileManager.createDirectory(atPath: userPath,
                                             withIntermediateDirectories: true, attributes: nil)
        }
        if !fileManager.fileExists(atPath: userPreferencePath){
            let newDic = ["FirstLaunch":"true"]
            NSDictionary(dictionary: newDic).write(toFile: userPreferencePath, atomically: true)
            return newDic
        }
        else{
            if let covers = NSDictionary(contentsOf: URL(string: "file://" + userPreferencePath)!) as?[String:String]{
                return covers
            }
            else{
                let newDic = ["FirstLaunch":"false"]
                NSDictionary(dictionary: newDic).write(toFile: userPreferencePath, atomically: true)
                return newDic
            }
        }
    }
    
    public func writePreference(file:[String:String]){
        NSDictionary(dictionary: file).write(toFile: userPreferencePath, atomically: true)
    }
    
}

fileprivate extension BigBrother {
    
    func prepareStatusBar() {
        statusBarStyle = .default
        statusBar.backgroundColor = Color.clear
        displayStyle = DisplayStyle.full
    }
    
    func prepareToolbar() {
        toolbarAlignment = .bottom
        toolbar.frame.size.height = 0
    }
}


