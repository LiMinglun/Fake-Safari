//
//  HistoryViewController.swift
//  Project0v1
//
//  Created by Michael on 3/6/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material
import Motion
import SCLAlertView

class HistoryViewController: UIViewController{
    
    var tableView:TableView?
    let historyPath = NSHomeDirectory() + "/Documents/.Usr/Caches/History/"
    var root:BigBrother
    let webArray:WebviewsArray
    var historyList:[String]?
    var historyContent:[[[String]]]?
    let currentWebVC:Int
    let controller = UISearchController(searchResultsController: nil)
    //let persei = MenuView()
    var filteredContent:[[[String]]] = [[[String]]]()
    var filteredList = [String]()
    //weak var fatherController:FABMenuController?
    var gestureHold:UILongPressGestureRecognizer?
    var gestureTap:UITapGestureRecognizer?
    var homeButton: FABButton!
    var backButton: FABButton!
    var deleteButton: FABButton!
    var wipeButton: FABButton!
    
    init(Root:BigBrother, WebArray:WebviewsArray, webVC:Int) {
        root = Root
        webArray = WebArray
        currentWebVC = webVC
        tableView=TableView(frame: CGRect(), style: .plain)
        super.init(nibName: nil, bundle: nil)
        if !FileManager.default.fileExists(atPath: historyPath){
            try! FileManager.default.createDirectory(atPath: historyPath,
                                             withIntermediateDirectories: true, attributes: nil)
        }
        historyList = getFilesList(atPath: historyPath, filterTypes: ["plist"])
        var arr2 = [String](repeating: "", count: historyList!.count)
        historyContent = [[[String]]](repeating: [[""]], count: historyList!.count)
        for i in historyList!{
            var history = getFileContent(atPath: historyPath + i)
            arr2[historyList!.count-1 - Int(history[0][2])!] = i
            historyContent![historyList!.count-1 - Int(history[0][2])!] = history.reversed()
        }
        historyList = arr2
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initSearchView()
        //tableView?.setContentOffset(CGPoint(x:0, y:controller.searchBar.bounds.height), animated: false)
        tableView?.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initNavigationItem()
        initBackground()
        initTableView()
        initButtons()
        initGesture()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

private extension HistoryViewController{
    
    func initNavigationItem() {
        navigationItem.titleLabel.text = "History"
        let searchButton = IconButton(image: Icon.cm.search)
        searchButton.addTarget(self, action: #selector(handleSearchButton(button:)), for: .touchUpInside)
        navigationItem.rightViews = [searchButton]
    }
    
    func initButtons(){
        let homeButtonSize = CGSize(width: 56, height: 56)
        let homeButtonSize2 = CGSize(width: 46, height: 46)
        let bottomInset: CGFloat = 24
        let bottomInset2: CGFloat = 84
        let bottomInset3: CGFloat = 144
        let rightInset: CGFloat = 24
        
        homeButton = FABButton(image: Icon.home, tintColor: .white)
        homeButton.pulseColor = .white
        homeButton.backgroundColor = Color.orange.base
        //homeButton.motionIdentifier = "LowerToolbar"
        homeButton.addTarget(self, action: #selector(handleHomeButton(button:)), for: .touchUpInside)
        view.layout(homeButton)
            .bottom(bottomInset)
            .right(rightInset)
            .size(homeButtonSize)
        
        backButton = FABButton(image: Icon.arrowBack, tintColor: .white)
        backButton.pulseColor = .white
        backButton.backgroundColor = Color.orange.base
        //backButton.motionIdentifier = "LowerToolbar"
        backButton.addTarget(self, action: #selector(handleBackButton(button:)), for: .touchUpInside)
        //backButton.isHidden = true
        view.layout(backButton)
            .bottom(bottomInset)
            .right(rightInset-100)
            .size(homeButtonSize2)
        
        deleteButton = FABButton(image: Icon.visibilityOff, tintColor: .white)
        deleteButton.pulseColor = .white
        deleteButton.backgroundColor = Color.red.base
        //deleteButton.motionIdentifier = "LowerToolbar"
        deleteButton.addTarget(self, action: #selector(handleDeleteButton(button:)), for: .touchUpInside)
        //deleteButton.isHidden = true
        view.layout(deleteButton)
            .bottom(bottomInset2)
            .right(rightInset-100)
            .size(homeButtonSize2)
        
        wipeButton = FABButton(image: Icon.clear, tintColor: .white)
        wipeButton.pulseColor = .white
        wipeButton.backgroundColor = Color.blue.base
        //deleteButton.motionIdentifier = "LowerToolbar"
        wipeButton.addTarget(self, action: #selector(handleWipeButton(button:)), for: .touchUpInside)
        //wipeButton.isHidden = true
        view.layout(wipeButton)
            .bottom(bottomInset3)
            .right(rightInset-100)
            .size(homeButtonSize2)
    }
    
    func initGesture(){
        gestureHold = UILongPressGestureRecognizer(target: self, action: #selector(handleHold))
        gestureHold?.delegate = self
        gestureHold?.minimumPressDuration = 0.8
        gestureTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gestureTap?.delegate = self
        self.view.addGestureRecognizer(gestureTap!)
        self.view.addGestureRecognizer(gestureHold!)
    }
    
    func initBackground(){
        self.view.backgroundColor=Color.grey.lighten4
    }
    
    func initTableView(){
        
        tableView!.dataSource=self
        tableView!.delegate=self
        tableView!.backgroundColor = UIColor.clear
        self.tableView!.register(HistoryTableViewCell.self,
                                 forCellReuseIdentifier: "HistoryTableViewCell")
        tableView?.allowsMultipleSelectionDuringEditing = true
        self.view.addSubview(tableView!)
        
        view.layout(tableView!).edges()
    }
    
    func initSearchView(){
        controller.searchResultsUpdater = self
        controller.hidesNavigationBarDuringPresentation = false
        controller.dimsBackgroundDuringPresentation = false
        controller.searchBar.searchBarStyle = .prominent
        controller.searchBar.sizeToFit()
        //self.tableView!.tableHeaderView = controller.searchBar
    }
    
    func initPersei(){
       // tableView!.addSubview(persei)
    }
    
    func getFilesList(atPath: String, filterTypes: [String]) -> [String] {
        let files = try! FileManager.default.contentsOfDirectory(atPath: atPath)
        if filterTypes.count == 0 {
            return files
        }
        else {
            let filteredfiles = NSArray(array: files).pathsMatchingExtensions(filterTypes)
            return filteredfiles
        }
    }
    
    func getFileContent(atPath: String) -> [[String]] {
        if FileManager.default.fileExists(atPath: atPath){
            if let covers = (NSArray(contentsOf: URL(string: "file://" + atPath)!) as? [[String]]){
                return covers
            }
        }
        return [[]]
    }
    
    func parseHeader(content:String) -> String{
        let month = ["January","February","March","April","May","June","July","August","September","October", "November","December"]
        let index = content.index(content.startIndex, offsetBy:10)
        let result = content[..<index]
        var resultArr = result.components(separatedBy:"-")
        resultArr[0] = month[Int(resultArr[0])!-1]
        return resultArr[0] + " " + resultArr[1] + ", " + resultArr[2]
    }
}

extension HistoryViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.controller.isActive {
            return filteredList.count
        } else {
            return historyList!.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.tintColor = UIColor.clear
        headerView.textLabel?.textColor = Color.grey.darken1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.controller.isActive {
            return parseHeader(content: filteredList[section])
        } else {
            return parseHeader(content: (historyList?[section])!)
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if self.controller.isActive {
            return filteredContent[section].count
        } else {
            return historyContent![section].count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath) as! HistoryTableViewCell
        cell.backgroundColor = UIColor.clear
        cell.dividerColor = Color.grey.lighten2
       // cell.delegate = self
        if self.controller.isActive {
            cell.textLabel?.text = filteredContent[indexPath.section][indexPath.row][1]
            cell.detailTextLabel?.text = filteredContent[indexPath.section][indexPath.row][0]
        } else {
            cell.textLabel?.text = historyContent![indexPath.section][indexPath.row][1]
            cell.detailTextLabel?.text = historyContent![indexPath.section][indexPath.row][0]
        }
        return cell
    }
}

extension HistoryViewController:UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        if tableView.isEditing == true{
            reverseSelectionState(at: indexPath)
            }
        else{
            if controller.isActive{
                let url = filteredContent[indexPath.section][indexPath.row][0]
                controller.isActive = false
                root.transition(to: (self.webArray.forceGetIntance(AT: currentWebVC)).loadUrl(Url: url))
            }else{
                controller.isActive = false
                root.transition(to: (self.webArray.forceGetIntance(AT: currentWebVC)).loadUrl(Url: historyContent![indexPath.section][indexPath.row][0]))
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if controller.isActive{
            if filteredContent[indexPath.section][indexPath.row][3] == "1"{
                cell.isSelected = true
            }
        }else{
            if historyContent![indexPath.section][indexPath.row][3] == "1"{
                cell.isSelected = true
            }
        }
    }
    
}

extension HistoryViewController: TableViewDelegate {
   
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension HistoryViewController: UISearchResultsUpdating
{
    //实时搜索
    func updateSearchResults(for searchController: UISearchController) {
        filteredContent.removeAll()
        filteredList.removeAll()
        let searchText = controller.searchBar.text!
        DispatchQueue.global().async {[weak self] () -> () in
            guard let strongSelf = self else { return }
            for sectionIndex in 0..<strongSelf.historyContent!.count{
                var filteredSection = [[String]]()
                for rowsIndex in 0..<strongSelf.historyContent![sectionIndex].count{
                    if strongSelf.historyContent![sectionIndex][rowsIndex][0].containsIgnoringCase(find: searchText) || strongSelf.historyContent![sectionIndex][rowsIndex][1].containsIgnoringCase(find: searchText){
                        var row = strongSelf.historyContent![sectionIndex][rowsIndex]
                        row.append("")
                        row.append("")
                        row[4]="\(sectionIndex)"
                        row[5]="\(rowsIndex)"
                        filteredSection.append(row)
                    }
                }
                if !filteredSection.isEmpty{
                    strongSelf.filteredContent.append(filteredSection)
                    strongSelf.filteredList.append(strongSelf.historyList![sectionIndex])
                }
            }
            DispatchQueue.main.async {self?.tableView?.reloadData()}
        }
        
    }
}

extension HistoryViewController:UIGestureRecognizerDelegate{
    
    @objc func handleBackButton(button: UIButton) {
        guard tableView?.isEditing == true else {return}
        animateButtonsOut()
        tableView?.setEditing(false, animated: true)
        //bad implementation - remove selected tag
        if controller.isActive{
            for i in 0..<filteredContent.count{
                for j in 0..<filteredContent[i].count{
                    filteredContent[i][j][3] = "0"
                }
            }
        }
        for i in 0..<historyContent!.count{
            for j in 0..<historyContent![i].count{
                historyContent![i][j][3] = "0"
            }
        }
        
        Motion.delay(0.2) { [weak self] in
            self?.tableView?.reloadData()}
    }
    
    @objc func handleDeleteButton(button: UIButton) {
        multiDelete()
    }
    
    @objc func handleWipeButton(button: UIButton) {
        let alert = SCLAlertView()
        _ = alert.addButton("The Last Day") {
            self.lastDayDelete()
        }
        
        _ = alert.addButton("All") {
            if !FileManager.default.fileExists(atPath: self.historyPath){return}
            try! FileManager.default.removeItem(atPath: self.historyPath)
            self.filteredContent.removeAll()
            self.filteredList.removeAll()
            self.historyContent?.removeAll()
            self.historyList?.removeAll()
            self.tableView?.reloadData()
        }
        
         _ = alert.showWarning("Warning", subTitle: "This will clear all browsing tracks within selected time period.")
        /*
        let clearHistoryController = UIAlertController(title: "" , message: "This will clear all browsing tracks within selected time period. Clear history for:", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "The Last Day", style: .destructive, handler: { (action) -> Void in
            self.lastDayDelete()
        } )
        
        let wipeAction = UIAlertAction(title: "All", style: .destructive, handler: { (action) -> Void in
            if !FileManager.default.fileExists(atPath: self.historyPath){return}
            try! FileManager.default.removeItem(atPath: self.historyPath)
            self.filteredContent.removeAll()
            self.filteredList.removeAll()
            self.historyContent?.removeAll()
            self.historyList?.removeAll()
            self.tableView?.reloadData()
            
        })
        
        clearHistoryController.addAction(cancelAction)
        clearHistoryController.addAction(deleteAction)
        clearHistoryController.addAction(wipeAction)
        if let presentedVC = presentedViewController {
            presentedVC.present(clearHistoryController, animated: true, completion: nil)
        } else {
            present(clearHistoryController, animated: true, completion: nil)
        }*/
    }
    
    @objc func handleSearchButton(button: UIButton) {
        present(controller, animated: true)
    }
    
    @objc func handleHomeButton(button: UIButton) {
        controller.isActive = false
        root.transition(to: webArray.forceGetIntance(AT: currentWebVC))
    }
    
    @objc func handleTap (sender:UITapGestureRecognizer) {
        let touchPoint = sender.location(ofTouch: 0, in: tableView)
        guard let indexPath = tableView?.indexPathForRow(at: touchPoint) else{return}
        var pulsePoint = sender.location(ofTouch: 0, in: (tableView?.cellForRow(at: indexPath) as! HistoryTableViewCell))
        pulsePoint.x -= 30
        (tableView?.cellForRow(at: indexPath) as! HistoryTableViewCell).pulse(point: pulsePoint)
        Motion.delay(0.15) { [weak self] in
            self?.tableView((self?.tableView!)!, didSelectRowAt: indexPath)}
        
    }
    
    @objc
    func handleHold(sender:UITapGestureRecognizer){
        guard tableView?.isEditing == false else {return}
        let touchPoint = sender.location(ofTouch: 0, in: tableView)
        guard let indexPath = tableView?.indexPathForRow(at: touchPoint) else{return}

        if (sender.state == UIGestureRecognizerState.began)
        {
           /* let queue = DispatchQueue(label: "tempTRNA")
            queue.async {[weak self] () -> () in
                self?.virginHistoryContent = self?.historyContent
                self?.virginFilteredContent = (self?.filteredContent)!
            }*/
            
            animateButtonsIn()
            self.tableView!.setEditing(true, animated:true)
            Motion.delay(0.1) { [weak self] in
                self?.selectItem(at: indexPath)}
            
        }
    }
    
    func animateButtonsIn(){
        
        homeButton.animate([.position(CGPoint(x: homeButton.frame.midX+100, y:homeButton.frame.midY )),
                           .duration(0.6)])
        
        backButton.animate([.position(CGPoint(x: backButton.frame.midX-100, y:backButton.frame.midY )),
                           .duration(0.6)])
        
        Motion.delay(0.3) { [weak self] in
            self?.deleteButton.animate([.position(CGPoint(x: (self?.deleteButton.frame.midX)!-100, y:(self?.deleteButton.frame.midY)! )),
                                        .duration(0.6)])
            
            Motion.delay(0.3) { [weak self] in
                self?.wipeButton.animate([.position(CGPoint(x:(self?.wipeButton.frame.midX)!-100, y:(self?.wipeButton.frame.midY)! )),
                                          .duration(0.6)])
            }
            
        }
        
    }
    
    func animateButtonsOut(){
        
        homeButton.animate([.position(CGPoint(x: homeButton.frame.midX-100, y:homeButton.frame.midY )),
                            .duration(0.6)])
        
        backButton.animate([.position(CGPoint(x: backButton.frame.midX+100, y:backButton.frame.midY )),
                            .duration(0.6)])
        
        Motion.delay(0.3) { [weak self] in
            self?.deleteButton.animate([.position(CGPoint(x: (self?.deleteButton.frame.midX)!+100, y:(self?.deleteButton.frame.midY)! )),
                                        .duration(0.6)])
            
            Motion.delay(0.3) { [weak self] in
                self?.wipeButton.animate([.position(CGPoint(x:(self?.wipeButton.frame.midX)!+100, y:(self?.wipeButton.frame.midY)! )),
                                          .duration(0.6)])
            }
            
        }
        
    }
    
    func selectItem(at:IndexPath){
        guard let cell = tableView?.cellForRow(at: at) else{return}
        cell.setSelected(true, animated: true)
        if controller.isActive{
            let originalSection = Int(filteredContent[at.section][at.row][4])!
            let originalRow = Int(filteredContent[at.section][at.row][5])!
            filteredContent[at.section][at.row][3] = "1"
            historyContent![originalSection][originalRow][3] = "1"
        }
        else{
            historyContent![at.section][at.row][3] = "1"
        }
    }
    
    func deselectItem(at:IndexPath){
        guard let cell = tableView?.cellForRow(at: at) else{return}
        cell.setSelected(false, animated: true)
        if controller.isActive{
            let originalSection = Int(filteredContent[at.section][at.row][4])!
            let originalRow = Int(filteredContent[at.section][at.row][5])!
            filteredContent[at.section][at.row][3] = "0"
            historyContent![originalSection][originalRow][3] = "0"
        }
        else{
            historyContent![at.section][at.row][3] = "0"
        }
    }
    
    func isSelected(at:IndexPath)->Bool{
        guard (tableView?.cellForRow(at: at)) != nil else{return false}
        if controller.isActive{
            return filteredContent[at.section][at.row][3] == "1"
        }
        else{
            return historyContent![at.section][at.row][3] == "1"
        }
    }
    
    func reverseSelectionState(at:IndexPath){
        if isSelected(at: at){deselectItem(at: at)}
        else{selectItem(at: at)}
    }
    
    func deleteItem(at indexPath:IndexPath, type:String){
         if type == "filtered" {
            let originalSection = Int(self.filteredContent[indexPath.section][indexPath.row][4])!
            let originalRow = Int(self.filteredContent[indexPath.section][indexPath.row][5])!
            //fix originalROw after
            for i in indexPath.row+1..<self.filteredContent[indexPath.section].count{
                self.filteredContent[indexPath.section][i][5] = "\(Int(self.filteredContent[indexPath.section][i][5])!-1)"
            }
            self.historyContent![originalSection].remove(at: originalRow)
            self.filteredContent[indexPath.section].remove(at: indexPath.row)
            if self.controller.isActive{ tableView?.deleteRows(at: [indexPath], with: .left)}
        } else if type == "history"{
            self.historyContent![indexPath.section].remove(at: indexPath.row)
            if !self.controller.isActive{tableView?.deleteRows(at: [indexPath], with: .left)}
        }
    }

    
    func multiDelete(){
        var fileIndex = 0
        if controller.isActive{
            for i in (0..<filteredContent.count).reversed(){
                for j in (0..<filteredContent[i].count).reversed(){
                    if filteredContent[i][j][3] == "1"{
                        let indexPath = IndexPath(row: j, section: i)
                        deleteItem(at: indexPath,type: "filtered")
                    }
                }
               /* if filteredContent[i].count == 0{
                    filteredContent.remove(at: i)
                    filteredList.remove(at: i)
                    tableView?.deleteSections(IndexSet(integer:i) , with: .left)
                }*/
            }
        }
        for section in (0..<historyContent!.count).reversed(){
            for row in (0..<historyContent![section].count).reversed(){
                if historyContent![section][row][3] == "1"{
                    let indexPath = IndexPath(row: row, section: section)
                    deleteItem(at: indexPath,type: "history")
                }
            }
            var listToSave = self.historyContent![section]
            let filePath = self.historyPath.appending(self.historyList![section])
            //save and re-index docs
            if listToSave.isEmpty{
                try! FileManager.default.removeItem(at: URL(string: "file://" + filePath)!)
     /*           historyContent?.remove(at: section)
                historyList?.remove(at: section)
                if !controller.isActive{tableView?.deleteSections(IndexSet(integer:section) , with: .left)}*/
            }
            else{
                for i in 0..<listToSave.count{
                    listToSave[i][2] = String(describing:fileIndex)
                    listToSave[i][3] = "0"
                }
                fileIndex += 1
                NSArray(array: listToSave).write(toFile: filePath, atomically: true)
            }
        }
    }
    
    func lastDayDelete(){
        let timeStamp = Date().timeIntervalSince1970
        let date = Date(timeIntervalSince1970: timeStamp)
        let dformatter = DateFormatter()
        dformatter.dateFormat = "MM-dd-yyyy"
        let fileName = dformatter.string(from: date)+".plist"
        if !FileManager.default.fileExists(atPath: self.historyPath+fileName){
            return
        }
        try! FileManager.default.removeItem(atPath: self.historyPath+fileName)
        if controller.isActive == true{
            if filteredList.contains(fileName){
                filteredList.remove(at: 0)
                filteredContent.remove(at: 0)
            }
        }
        historyContent?.remove(at: 0)
        historyList?.remove(at: 0)
        tableView?.deleteSections(IndexSet(integer:0) , with: .left)
        //write
        var fileIndex = 0
        for section in (0..<historyContent!.count).reversed(){
            var listToSave = self.historyContent![section]
            let filePath = self.historyPath.appending(self.historyList![section])
            //save and re-index docs
            for i in 0..<listToSave.count{
                listToSave[i][2] = String(describing:fileIndex)
                listToSave[i][3] = "0"
            }
            fileIndex += 1
            NSArray(array: listToSave).write(toFile: filePath, atomically: true)
        }
        
    }
}

extension String {
    func contains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
    func containsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    func positionOf(sub:String, backwards:Bool = false)->Int {
        var pos = -1
        if let range = range(of:sub, options: backwards ? .backwards : .literal ) {
            if !range.isEmpty {
                pos = self.distance(from:startIndex, to:range.lowerBound)
            }
        }
        return pos
    }
}
