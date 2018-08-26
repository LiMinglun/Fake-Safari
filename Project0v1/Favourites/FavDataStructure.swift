//
//  FavDataStructure.swift
//  Project0v1
//
//  Created by Michael on 3/13/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import CryptoSwift

class FavDataStructure: NSObject{
    let dataPath:String!
    let password:String?
    let initPath = NSHomeDirectory() + "/Documents/.Usr/BookMarks/"
    let fileManager = FileManager.default
    let bmPath:String!
    let currentPath:String!
    
    init(path:String, passw0rd:String?) {
        currentPath = path
        dataPath = initPath + path
        password = passw0rd
        bmPath = dataPath+"file.plist"
        super.init()
        if !fileManager.fileExists(atPath: initPath){
            try! fileManager.createDirectory(atPath: initPath,
                                                     withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func saveBookmark(title:String, url:String){
        
        if let key = password{
            let urlName = encrypt(string: url, key: key)
            let fileName = encrypt(string: title, key: key)
            
            if var origList = initBooklistFile(){
                origList.append(["url":urlName,"title":fileName,"type":"bookmark"])
                NSArray(array: origList).write(toFile: bmPath, atomically: true)
            }
            else{
                NSArray(array: [["url":urlName,"title":fileName,"type":"bookmark"]]).write(toFile: bmPath, atomically: true)
            }
        }
        else{
            if var origList = initBooklistFile(){
                origList.append(["url":url,"title":title,"type":"bookmark"])
                NSArray(array: origList).write(toFile: bmPath, atomically: true)
            }
            else{
                NSArray(array: [["url":url,"title":title,"type":"bookmark"]]).write(toFile: bmPath, atomically: true)
            }
        }
    }
    
    func readBookmarkList()->[String]?{
        guard let rawList = initBooklistFile() else{return nil}
        var titleList = [String]()
        for i in rawList{
            if i["type"] == "bookmark"{
                titleList.append(i["title"]!)
            }
        }
        
        if let key = password{
            var decryptedList = [String]()
            for item in titleList{
                if let resultstr = decrypt(string: item, key: key){
                    decryptedList.append(resultstr)
                }
            }
            return decryptedList
        }
        else{
            return titleList
        }
    }
    
    func getFolderList()->[String]?{
        guard let rawList = initBooklistFile() else{return nil}
        var titleList = [String]()
        for i in rawList{
            if i["type"] == "folder"{
                titleList.append(i["title"]!)
            }
        }
        
        if let key = password{
            var decryptedList = [String]()
            for item in titleList{
                if let resultstr = decrypt(string: item, key: key){
                    decryptedList.append(resultstr)
                }
            }
            return decryptedList
        }
        else{
            return titleList
        }
    }
    
    func getFullFolderList(Path:String, Depth:Int)->[[String]]?{
        var rawList = [[String:String]]()
        let filePath = initPath+Path+"file.plist"
        if fileManager.fileExists(atPath: filePath){
            if let covers = (NSArray(contentsOf: URL(string: "file://" + filePath)!) as? [[String:String]]){
                rawList = covers
            }
        }
        else{
            return nil
        }
        
        var titleList = [[String]]()
        for i in rawList{
            if i["type"] == "folder"{
                var inset = 1
                for _ in 0..<Depth{
                    inset += 1
                }
                titleList.append([i["title"]!,Path+i["title"]!+"/","\(inset)"])
                if let childList = getFullFolderList(Path: Path+"\(i["title"]!)/", Depth: Depth+1){
                    for j in childList{
                        titleList.append(j)
                    }
                }
            }
        }
        print(titleList)
        return titleList
    }
    
    func getFullList()->[String]?{
        guard let rawList = initBooklistFile() else{return nil}
        var titleList = [String]()
        for i in rawList{
            if i["type"] == "folder"||i["type"] == "bookmark"{
                titleList.append(i["title"]!)
            }
        }
        
        if let key = password{
            var decryptedList = [String]()
            for item in titleList{
                if let resultstr = decrypt(string: item, key: key){
                    decryptedList.append(resultstr)
                }
            }
            return decryptedList
        }
        else{
            return titleList
        }
    }
    
    func getBookmarkURL(index:Int)->String?{
        guard let rawList = initBooklistFile() else{return nil}
        guard rawList.count > index else {return nil}
        guard rawList[index]["type"] == "bookmark" else{return nil}
        guard let url = rawList[index]["url"] else{return nil}
        if let key = password{
            return decrypt(string: url, key: key)
        }
        else{
            return url
        }
    }
    
    func getType(index:Int)->String?{
        guard let rawList = initBooklistFile() else{return nil}
        guard rawList.count > index else {return nil}
        return rawList[index]["type"]
    }
    
    func rename(index:Int, newName:String?){
        guard var rawList = initBooklistFile() else{return}
        guard rawList.count > index else {return}
        guard newName != nil else{return}
        if getType(index: index) == "folder"{
            let origPath = dataPath + getRawName(index: index)!
            var targetPath = ""
            if let passkey = password{
                targetPath = dataPath + encrypt(string: newName!, key: passkey)
            }
            else{
                targetPath = dataPath + newName!
            }
            do {try fileManager.moveItem(atPath: origPath, toPath: targetPath)}
            catch {return}
        }
        rawList[index]["title"] = newName
        NSArray(array: rawList).write(toFile: bmPath, atomically: true)
    }
    
    func getRawName(index:Int)->String?{
        guard let rawList = initBooklistFile() else{return nil}
        guard rawList.count > index else {return nil}
        return rawList[index]["title"]
    }
    
    func deleteBookmark(index:Int){
        guard var rawList = initBooklistFile() else{return}
        guard rawList.count > index else {return}
        guard rawList[index]["type"] == "bookmark" else{return}
        rawList.remove(at: index)
        NSArray(array: rawList).write(toFile: bmPath, atomically: true)
    }
    
    func deleteFolder(index:Int){
        guard var rawList = initBooklistFile() else{return}
        guard rawList.count > index else {return}
        guard rawList[index]["type"] == "folder" else{return}
        let fileName = rawList[index]["title"]
        let newPath = dataPath+fileName!+"/"
        rawList.remove(at: index)
        NSArray(array: rawList).write(toFile: bmPath, atomically: true)
        if fileManager.fileExists(atPath: newPath){
            try! fileManager.removeItem(atPath: newPath)
        }
    }
    
    func deleteItem(at: Int){
        let type = getRawName(index: at)
        if type == "folder"{
            deleteFolder(index: at)
        }
        else if type == "bookmark"{
            deleteBookmark(index: at)
        }
    }
    
    func getAllItem()->[[String:String]]{
        let enumeratorAtPath = fileManager.enumerator(atPath: initPath)
        let rawItemList = enumeratorAtPath?.allObjects as! [String]
        var resultList = [[String:String]]()
        for i in rawItemList{
            if i.contains(find: "file.plist"){
                let filePath = initPath + i
                if var covers = (NSArray(contentsOf: URL(string: "file://" + filePath)!) as? [[String:String]]){
                    if let passKey = password{
                        for j in 0..<covers.count{
                            if covers[j]["type"] == "bookmark"{
                                covers[j]["title"] = decrypt(string: covers[j]["title"]!, key: passKey) ?? ""
                            
                                covers[j]["url"] = decrypt(string: covers[j]["url"]!, key: passKey) ?? ""
                                resultList.append(covers[j])
                            }
                        }
                    }
                    else{
                        for j in covers{
                            if j["type"] == "bookmark"{
                            resultList.append(j)
                            }
                        }
                    }
                    
                }
            }
        }
        return resultList
    }
    
    func deleteFolder(title:String){
        if let key = password{
            let newPath = dataPath+encrypt(string: title, key: key)+"/"
            let fileName = encrypt(string: title, key: key)
            
            if var origList = initBooklistFile(){
                for item in (0..<origList.count){
                    if origList[item]["type"] == "folder"&&origList[item]["title"]==fileName{
                        origList.remove(at: item)
                        break
                    }
                }
                NSArray(array: origList).write(toFile: bmPath, atomically: true)
            }
            if fileManager.fileExists(atPath: newPath){
                try! fileManager.removeItem(atPath: newPath)
            }
        }
        else{
            let newPath = dataPath+title+"/"
            let fileName = title
            
            if var origList = initBooklistFile(){
                for item in (0..<origList.count){
                    if origList[item]["type"] == "folder"&&origList[item]["title"]==fileName{
                        origList.remove(at: item)
                        break
                    }
                }
                NSArray(array: origList).write(toFile: bmPath, atomically: true)
            }
            if fileManager.fileExists(atPath: newPath){
                try! fileManager.removeItem(atPath: newPath)
            }
        }

    }
    
    func reorder(origIndex:Int, targetIndex:Int){
        guard var rawList = initBooklistFile() else{return}
        let fromDataItem = rawList[origIndex]
        rawList.remove(at: origIndex)
        rawList.insert(fromDataItem, at: targetIndex)
        NSArray(array: rawList).write(toFile: bmPath, atomically: true)
    }
    
    func move(objectsIndexs:[Int], targetData:FavDataStructure){
        guard let rawList = initBooklistFile() else{return}
        let indexs = objectsIndexs.sorted(by: >)
        
        for item in indexs{
                if rawList[item]["type"] == "folder"{
                    let folderName:String
                    if let passw = password{
                        folderName = targetData.createFolder(title: decrypt(string: rawList[item]["title"]!, key: passw)!)
                        targetData.deleteFolder(title: folderName)
                    }
                    else{
                        folderName = targetData.createFolder(title: rawList[item]["title"]!)
                        targetData.deleteFolder(title: folderName)
                    }
                    let folderPath = dataPath+rawList[item]["title"]!+"/"
                    let targetPath = targetData.dataPath+folderName
                    do {try fileManager.moveItem(atPath: folderPath, toPath: targetPath)}
                    catch let e{print(e);break}
                    if var neoEle = self.deleteElement(index: item){
                        neoEle["title"] = folderName
                        targetData.createElement(element: neoEle)
                    }
                }
                else{
                    if let neoEle = self.deleteElement(index: item){
                        targetData.createElement(element: neoEle)
                    }
                }
        }
    }
    
    func createFolder(title:String)->String{
        
        if let key = password{
            var newPath = dataPath+encrypt(string: title, key: key)+"/"
            var fileName = encrypt(string: title, key: key)
            var index = 0
            while fileManager.fileExists(atPath: newPath){
                index+=1
                newPath = dataPath+encrypt(string: title+"(\(index))", key: key)+"/"
                fileName = encrypt(string: title+"(\(index))", key: key)
            }
            
            if var origList = initBooklistFile(){
                origList.append(["title":fileName,"type":"folder"])
                NSArray(array: origList).write(toFile: bmPath, atomically: true)
            }
            else{
                NSArray(array: [["title":fileName,"type":"folder"]]).write(toFile: bmPath, atomically: true)
            }
            try! fileManager.createDirectory(atPath: newPath,
                                                 withIntermediateDirectories: true, attributes: nil)
            return fileName
        }
        else{
            var newPath = dataPath+title+"/"
            var fileName = title
            var index = 0
            while fileManager.fileExists(atPath: newPath){
                index+=1
                newPath = dataPath + title + "(\(index))" + "/"
                fileName = title + "(\(index))"
            }
            
            if var origList = initBooklistFile(){
                origList.append(["title":fileName,"type":"folder"])
                NSArray(array: origList).write(toFile: bmPath, atomically: true)
            }
            else{
                NSArray(array: [["title":fileName,"type":"folder"]]).write(toFile: bmPath, atomically: true)
            }
            if !fileManager.fileExists(atPath: newPath){
                try! fileManager.createDirectory(atPath: newPath,
                                                 withIntermediateDirectories: true, attributes: nil)
            }
            return fileName
        }
    }
    
}

//Helper Methods
private extension FavDataStructure{
    
    private func deleteElement(index:Int)->[String:String]?{
        guard var rawList = initBooklistFile() else{return nil}
        guard rawList.count > index else {return nil}
        let returnty = rawList[index]
        rawList.remove(at: index)
        NSArray(array: rawList).write(toFile: bmPath, atomically: true)
        return returnty
    }
    
    private func createElement(element:[String:String]){
        guard var rawList = initBooklistFile() else{return}
        rawList.append(element)
        NSArray(array: rawList).write(toFile: bmPath, atomically: true)
    }
    
    func initBooklistFile()->[[String:String]]?{
        if fileManager.fileExists(atPath: bmPath){
            if let covers = (NSArray(contentsOf: URL(string: "file://" + bmPath)!) as? [[String:String]]){
                return covers
            }
        }
        else{
            NSArray(array: [[String:String]]()).write(toFile: bmPath, atomically: true)
        }
        return nil
    }
    
    func encrypt(string:String, key:String)->String{
        let aes = try! AES(key: key.bytes, blockMode: .ECB)
        let rawResult = try! string.encryptToBase64(cipher: aes)!
        let result = rawResult.replacingOccurrences(of: "/", with: "_")
        return result
    }
    
    func decrypt(string:String, key:String)->String?{
        let aes = try! AES(key: key.bytes, blockMode: .ECB)
        let processedStr = string.replacingOccurrences(of: "_", with: "/")
        let result:String?
        do {
            result = try processedStr.decryptBase64ToString(cipher: aes)
        }
        catch{
            return nil
        }
        return result
    }
}
