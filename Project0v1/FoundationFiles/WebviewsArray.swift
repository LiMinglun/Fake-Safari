//
//  WebviewsArray.swift
//  Project0v1
//
//  Created by Michael on 2/22/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit

class WebviewsArray: NSObject {

    var count:Int = 0
    let welcomePage = "homePage"
    let filePathInfo:String = NSHomeDirectory() + "/Documents/.Usr/Caches/webTab.plist"
    let filePathIndex:String = NSHomeDirectory() + "/Documents/.Usr/Caches/lastPage.txt"
    var root = BigBrother()
    
    var activeViewIndex:Int = 0{
        didSet{
            saveCurrrentIndex(INDEX: activeViewIndex)
        }
    }
    
    private var webTabs = [[Any?]](){
        didSet{
            //print(webTabs)
            count = webTabs.count
            writeToFile()
        }
    }
    
    override init() {
        print("fullpath:" + NSHomeDirectory())
        super.init()
        
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/.Usr/Caches/"){
            try! FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/.Usr/Caches/", withIntermediateDirectories: true, attributes: nil)
        }
        
        if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/.Usr/Caches/webTab.plist") && FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/.Usr/Caches/lastPage.txt") {
            if let covers = (NSArray(contentsOf: URL(string: "file://" + NSHomeDirectory() + "/Documents/.Usr/Caches/webTab.plist")!) as? [[String:String]]){
                if covers.count != 0{
                    for i in 0...covers.count-1{
                        webTabs.append([covers[i],nil])
                    }
                }
                else{resetWebTabs()}//file broken
            }
            else{resetWebTabs()}//file broken
            
            if let tData = NSData(contentsOf: URL(string: "file://" + NSHomeDirectory() + "/Documents/.Usr/Caches/lastPage.txt")!){
                let txtData:String = (NSString(data: tData as Data, encoding: String.Encoding.utf8.rawValue))! as String
                activeViewIndex = Int(txtData)!
            }
            else{resetWebTabs()}//file broken
        }
        else{resetWebTabs()}//first-time launch or file broken
        
        count = webTabs.count
    }
    
}

extension WebviewsArray{
    
    func move(from fromIndex: Int, to toIndex: Int){
        //fix index
        if fromIndex < webTabs.count-1{//not the last one
            for i in (fromIndex + 1)...webTabs.count-1{
                if let tabInstance = webTabs[i][1]{
                    (tabInstance as! WebViewController).indexNum -= 1}
            }
        }
        let a = webTabs.remove(at: fromIndex)
        webTabs.insert(a, at: toIndex)
        if toIndex < webTabs.count-1{//not the last one
            for i in (toIndex + 1)...webTabs.count-1{
                if let tabInstance = webTabs[i][1]{
                    (tabInstance as! WebViewController).indexNum += 1}
            }
        }
        
    }
    
    func getInstance(AT index:Int) -> WebViewController?{
        if webTabs.count-1 >= index{
            return webTabs[index][1] as? WebViewController
        }
        else{return nil}
    }
    
    func forceGetIntance(AT num:Int) -> WebViewController{
        if webTabs[num][1] != nil{
            return webTabs[num][1] as! WebViewController
        }
        else{
            let covers = webTabs[num][0] as! [String:String]
            let newTab = WebViewController(URL: covers["url"]!, NO: num, IMEI: UInt32(covers["image"]!)!, WebArray: self, ROOT: root)
            webTabs[num][1] = newTab
            return newTab
        }
    }
    
    func getWebInfo(AT index:Int) -> [String:String]?{
        if webTabs.count-1 >= index{
            return webTabs[index][0] as? [String:String]
        }
        else{return nil}
    }
    
    func updatePointer(Pointer pointer:WebViewController?, forIndex index:Int){
        if webTabs.count-1 >= index{
            webTabs[index][1] = pointer
        }
    }
    
    func mutateIMEI(forIndex index:Int, to imei:UInt32){
        if webTabs.count-1 >= index{
            var covers = webTabs[index][0]! as! [String:String]
            covers["image"] = String(imei)
            webTabs[index][0] = covers
        }
    }
    
    func updateUrl(forIndex index:Int, URL url:String){
        if webTabs.count-1 >= index{
            var covers = webTabs[index][0]! as! [String:String]
            covers["url"] = url
            webTabs[index][0] = covers
        }
    }
    
    func updateOffset(forIndex index:Int, OFFSET offset:CGFloat){
        if webTabs.count-1 >= index{
            var covers = webTabs[index][0]! as! [String:String]
            covers["contentOffset"] = String(describing: offset)
            webTabs[index][0] = covers
        }
    }
    func getOffset(forIndex index:Int) -> CGFloat?{
        if webTabs.count-1 >= index{
            let covers = webTabs[index][0]! as! [String:String]
            if let ret = covers["contentOffset"], let ret2 = Float(ret){
                return CGFloat(ret2)
            }
            return nil
        }
        return nil
    }
    
    func updateTitle(forIndex index:Int, TITLE title:String){
        if webTabs.count-1 >= index{
            var covers = webTabs[index][0]! as! [String:String]
            covers["title"] = title
            webTabs[index][0] = covers
        }
    }
    
    func deleteTab(at indexNo:Int){
        //remove image
        if FileManager.default.fileExists(atPath: NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending((webTabs[indexNo][0] as! [String:String])["image"]! + ".jpeg")){
            let url = URL(string: "file://" + NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending((webTabs[indexNo][0] as! [String:String])["image"]! + ".jpeg"))!
            try! FileManager.default.removeItem(at: url)
        }
        //fix index
        if indexNo < webTabs.count-1{//not the last one
            for i in (indexNo + 1)...webTabs.count-1{
                if let tabInstance = webTabs[i][1]{
                    (tabInstance as! WebViewController).indexNum -= 1}
            }
        }
        //remove
        webTabs.remove(at: indexNo)
    }
    
    func insert(tab WebTab:WebViewController, to indexNo:Int, withURL url:String){
        //add
        WebTab.indexNum = indexNo
        webTabs.insert([["url":url,"image":String(WebTab.IMEI),"title":"","contentOffset":"0"],WebTab], at: indexNo)
        //fix index
        if (indexNo + 1) <= webTabs.count-1{//not the last one
            for i in (indexNo + 1)...webTabs.count-1{
                if let tabInstance = webTabs[i][1]{
                    (tabInstance as! WebViewController).indexNum += 1}
            }
        }
    }
    
}

private extension WebviewsArray{
    
    func resetWebTabs(){
            //delete all images
        webTabs.append([["url":welcomePage,"image":"0","title":"","contentOffset":"0"],nil])
            writeToFile()
            activeViewIndex = 0
            saveCurrrentIndex(INDEX: 0)
    }
    
    func writeToFile(){
        var dic = [[String:String]]()
        if webTabs.count == 0{
            NSArray(array: []).write(toFile: filePathInfo, atomically: true)
            return
        }
        for i in 0...webTabs.count-1{
            dic.append(webTabs[i][0] as! [String:String])
        }
        NSArray(array: dic).write(toFile: filePathInfo, atomically: true)
    }
    
    func saveCurrrentIndex(INDEX num:Int){
        if num < 0{
            try! String(0).write(toFile: filePathIndex, atomically: true, encoding: String.Encoding.utf8)
            return
        }
        let index = String(describing: num)
        try! index.write(toFile: filePathIndex, atomically: true, encoding: String.Encoding.utf8)
    }
    
}
