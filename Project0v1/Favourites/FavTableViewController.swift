//
//  FavTableViewController.swift
//  Project0v1
//
//  Created by Michael on 3/13/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material
import Motion
import SCLAlertView

class FavTableViewController: UIViewController{
    var tableView:TableView?
    let currentPath:String!
    let currentData:FavDataStructure!
    let currentFolderName:String?
    var selectedCellIndex=[Int]()
    var moveCellIndex=[Int]()
    var filteredCell=[[String:String]]()
    let passkey:String?
    
    var root:BigBrother
    let webArray:WebviewsArray
    let controller = UISearchController(searchResultsController: nil)
    let currentWebVC:Int
    
    var gestureHold:UILongPressGestureRecognizer?
    var gestureTap:UITapGestureRecognizer?
    
    var homeButton: FABButton!
    var backButton: FABButton!
    var deleteButton: FABButton!
    var moreButton: FABButton!
    var confirmButton: FABButton!
    var renameButton: FABButton!
    let numLabel = UILabel()
    
    init(Root:BigBrother, WebArray:WebviewsArray, webVC:Int, path:String, password:String?, folderName:String?){
        root = Root
        webArray = WebArray
        currentWebVC = webVC
        tableView=TableView(frame: CGRect(), style: .plain)
        currentPath = path
        currentData = FavDataStructure(path: currentPath, passw0rd: password)
        currentFolderName = folderName
        passkey = password
        super.init(nibName: nil, bundle: nil)
        initButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView?.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        
        if (navigationController as! AppNavigationController).moveMode == true{
            numLabel.text = String(describing: (navigationController as! AppNavigationController).moveList!.moveCellIndex.count)
            layoutMoveModeButtons()
        }
        else{
           layoutNormalModeButtons()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initNavigationItem()
        initBackground()
        initTableView()
        initGesture()
        initSearchView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedCellIndex.removeAll()
        filteredCell.removeAll()
        tableView?.isEditing = false
        controller.isActive = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension FavTableViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        guard let fullListCount = currentData.getFullList()?.count else {return 0}
        if self.controller.isActive{
            return filteredCell.count
        }
        else{
            return fullListCount
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath) as! HistoryTableViewCell
        guard let fullList = currentData.getFullList() else {return cell}
        cell.backgroundColor = UIColor.clear
        cell.dividerColor = Color.grey.lighten2
        if self.controller.isActive {
            
            cell.textLabel?.text = filteredCell[indexPath.row]["title"]
            cell.imageView?.image = Icon.favorite
        } else {
            cell.textLabel?.text = fullList[indexPath.row]
            if currentData.getType(index: indexPath.row) == "folder"{
                cell.imageView?.image = Icon.work
            }
            else{
                cell.imageView?.image = Icon.favorite
            }
        }
        return cell
    }
}

extension FavTableViewController: TableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension FavTableViewController:UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if tableView.isEditing == true{
            reverseSelectionState(at: indexPath)
            if selectedCellIndex.count>1{
                renameButton.isHidden = true
            }
        }
        else{
            if controller.isActive{
                if let url = filteredCell[indexPath.row]["url"]{
                    controller.isActive = false
                    root.transition(to: (self.webArray.forceGetIntance(AT: currentWebVC)).loadUrl(Url: url))
                }
            }
            else{
                let list = currentData.getFullList()
                let type = currentData.getType(index: indexPath.row)
                if type == "bookmark"{
                    controller.isActive = false
                    if let url = currentData.getBookmarkURL(index: indexPath.row){
                        root.transition(to: (self.webArray.forceGetIntance(AT: currentWebVC)).loadUrl(Url: url))}
                }
                else if type == "folder"{
                    let rawName = currentData.getRawName(index: indexPath.row)
                    navigationController?.pushViewController(FavTableViewController(
                        Root:root, WebArray:webArray, webVC:currentWebVC, path:currentPath+rawName!+"/", password:passkey, folderName:list![indexPath.row]), animated: true)
                    controller.isActive = false
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if controller.isActive{
            /*for i in selectedCellIndex{
                if i == filteredCellIndex[indexPath.row]{
                    cell.isSelected = true
                    return
                }
            }*/
        }else{
            for i in selectedCellIndex{
                if i == indexPath.row{
                    cell.isSelected = true
                    return
                }
            }
        }
    }
    
}

extension FavTableViewController:UIGestureRecognizerDelegate{
    
    @objc func handleBackButton(button: UIButton) {
        if tableView!.isEditing{
            self.tableView!.setEditing(false, animated:true)
            animateButtonsOut()
            selectedCellIndex.removeAll()
            Motion.delay(0.25) { [weak self] in
            self?.tableView?.reloadData()
            }
        }
        else{
            if (navigationController as! AppNavigationController).moveMode{
                (navigationController as! AppNavigationController).moveMode = false
                animateMoveOut()
                (navigationController as! AppNavigationController).moveList?.moveCellIndex.removeAll()
                (navigationController as! AppNavigationController).moveList = nil
            }
        }
    }
    
    @objc func handleConfirmButton(button: UIButton) {
        guard let origInstance = (navigationController as! AppNavigationController).moveList else{return}
        guard origInstance.currentPath != self.currentPath else{handleBackButton(button: backButton)
            return
        }
        origInstance.currentData.move(objectsIndexs: origInstance.moveCellIndex, targetData: self.currentData)
        tableView?.reloadData()
        origInstance.tableView?.reloadData()
        (navigationController as! AppNavigationController).moveMode = false
        animateMoveOut()
        (navigationController as! AppNavigationController).moveList?.moveCellIndex.removeAll()
        (navigationController as! AppNavigationController).moveList = nil
    }
    
    @objc func handleDeleteButton(button: UIButton) {
        if let menu = self.presentedViewController{
            (menu as! MenuViewController).goBack()
        }
        multiDelete()
    }
    
    @objc func handleRenameButton(button: UIButton) {
        if let menu = self.presentedViewController{
            (menu as! MenuViewController).goBack()
        }
        let appearance = SCLAlertView.SCLAppearance(
            kTextFieldHeight: 60,
            showCloseButton: true
        )
        let alert = SCLAlertView(appearance: appearance)
        let txt = alert.addTextField()
        _ = alert.addButton("Confirm") {
            self.currentData.rename(index: self.selectedCellIndex[0], newName: txt.text)
            self.tableView?.setEditing(false, animated: true)
            self.selectedCellIndex.removeAll()
            self.animateButtonsOut()
            Motion.delay(0.25) { [weak self] in
                self?.tableView?.reloadData()}
            
        }
        _ = alert.showEdit("Rename", subTitle:"Enter New Name")
        Motion.delay(0.25) {
            txt.becomeFirstResponder()}
    }
    
    @objc func handleMoreButton(button: UIButton) {
        let buttonHeight:CGFloat = 50
        var move: FlatButton
        move = FlatButton(title: "Move", titleColor: .black)
        move.addTarget(self, action: #selector(handleMoveButton), for: .touchUpInside)
        var delete: FlatButton
        delete = FlatButton(title: "Delete", titleColor: .black)
        delete.addTarget(self, action: #selector(handleDeleteButton), for: .touchUpInside)
        var rename: FlatButton
        rename = FlatButton(title: "Rename", titleColor: .black)
        rename.addTarget(self, action: #selector(handleRenameButton), for: .touchUpInside)
        var createFolder: FlatButton
        createFolder = FlatButton(title: "New folder", titleColor: .black)
        createFolder.addTarget(self, action: #selector(handleCreateFolderButton), for: .touchUpInside)
        
        let buttons = [move,delete,rename,createFolder]
        
        for i in buttons{
            i.pulseColor = .lightGray
            i.contentHorizontalAlignment = .left
            i.titleEdgeInsets = EdgeInsets(top: 0, left: 25, bottom: 0, right: 0)
            i.frame.size = CGSize(width: Screen.width, height: buttonHeight)
        }
        root.present(MenuViewController(buttons:buttons), animated: false)
    }
    
    @objc func handleMoveButton(button: UIButton) {
        if let menu = self.presentedViewController{
            (menu as! MenuViewController).goBack()
        }
        (navigationController as! AppNavigationController).moveMode = true
        self.tableView!.setEditing(false, animated:true)
        (navigationController as! AppNavigationController).moveList = self
        numLabel.text = String(describing: selectedCellIndex.count)
        moveCellIndex = selectedCellIndex
        selectedCellIndex.removeAll()
        Motion.delay(0.25) { [weak self] in
            self?.tableView?.reloadData()
        }
        animateMoveIn()
        //currentData.move(objectsIndexs: selectedCellIndex, targetIndex: <#T##Int#>)
    }
    
    @objc func handleCreateFolderButton(button: UIButton) {
        if let menu = self.presentedViewController{
            (menu as! MenuViewController).goBack()
        }
        let appearance = SCLAlertView.SCLAppearance(
            kTextFieldHeight: 60,
            showCloseButton: true
        )
        let alert = SCLAlertView(appearance: appearance)
        let txt = alert.addTextField()
        _ = alert.addButton("Confirm") { [weak self] in
            if let text = txt.text{
                _ = self?.currentData.createFolder(title: text)
                self?.tableView?.setEditing(false, animated: true)
                self?.selectedCellIndex.removeAll()
                self?.animateButtonsOut()
                Motion.delay(0.25) { [weak self] in
                self?.tableView?.reloadData()}
                
            }
        }
        _ = alert.showEdit("Create folder", subTitle:"Enter folder name")
        Motion.delay(0.25) {
            txt.becomeFirstResponder()}
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
            self?.tableView((self?.tableView!)!, didSelectRowAt: indexPath)
        }
    }
    
    @objc
    func handleHold(sender:UITapGestureRecognizer){
        guard (navigationController as! AppNavigationController).moveMode == false else {return}
        guard tableView?.isEditing == false else {return}
        guard !controller.isActive else {return}
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
                self?.selectItem(at: indexPath)
            }
        }
    }
    
    func animateButtonsIn(){
        print("aniIn")
        homeButton.animate([.position(CGPoint(x: homeButton.frame.midX+100, y:homeButton.frame.midY )),
                            .duration(0.6)])
        
        backButton.animate([.position(CGPoint(x: backButton.frame.midX-100, y:backButton.frame.midY )),
                            .duration(0.6)])
        
        Motion.delay(0.14) { [weak self] in
            self?.moreButton.animate([.position(CGPoint(x:(self?.moreButton.frame.midX)!-100, y:(self?.moreButton.frame.midY)! )),
                                      .duration(0.6)])
            
            
            Motion.delay(0.14) { [weak self] in
                self?.deleteButton.animate([.position(CGPoint(x: (self?.deleteButton.frame.midX)!-100, y:(self?.deleteButton.frame.midY)! )),
                                            .duration(0.6)])
                Motion.delay(0.14) { [weak self] in
                    self?.renameButton.animate([.position(CGPoint(x: (self?.renameButton.frame.midX)!-100, y:(self?.renameButton.frame.midY)! )),
                                                .duration(0.6)])
                }
            }
            
        }
        
    }
    
    func animateButtonsOut(){
        print("aniOut")
        homeButton.animate([.position(CGPoint(x: homeButton.frame.midX-100, y:homeButton.frame.midY )),
                            .duration(0.6)])
        
        backButton.animate([.position(CGPoint(x: backButton.frame.midX+100, y:backButton.frame.midY )),
                            .duration(0.6)])
        
        Motion.delay(0.14) { [weak self] in
            self?.moreButton.animate([.position(CGPoint(x:(self?.moreButton.frame.midX)!+100, y:(self?.moreButton.frame.midY)! )),
                                      .duration(0.6)])
            
            
            Motion.delay(0.14) { [weak self] in
                self?.deleteButton.animate([.position(CGPoint(x: (self?.deleteButton.frame.midX)!+100, y:(self?.deleteButton.frame.midY)! )),
                                            .duration(0.6)])
                Motion.delay(0.14) { [weak self] in
                    self?.renameButton.animate([.position(CGPoint(x: (self?.renameButton.frame.midX)!+100, y:(self?.renameButton.frame.midY)! )),
                                                .duration(0.6)])
                }
            }
            
        }
        
    }
    
    func animateMoveIn(){
        print("aniMIn")
        confirmButton.animate([.position(CGPoint(x: confirmButton.frame.midX-100, y:confirmButton.frame.midY )),
                            .duration(0.6)])
        
        Motion.delay(0.14) { [weak self] in
            self?.moreButton.animate([.position(CGPoint(x:(self?.moreButton.frame.midX)!+100, y:(self?.moreButton.frame.midY)! )),
                                     .duration(0.6)])
            
            
            Motion.delay(0.14) { [weak self] in
                self?.deleteButton.animate([.position(CGPoint(x: (self?.deleteButton.frame.midX)!+100, y:(self?.deleteButton.frame.midY)! )),
                                            .duration(0.6)])
                Motion.delay(0.14) { [weak self] in
                    self?.renameButton.animate([.position(CGPoint(x: (self?.renameButton.frame.midX)!+100, y:(self?.renameButton.frame.midY)! )),
                                                .duration(0.6)])
                }
            }
            
        }
        
    }
    
    func animateMoveOut(){
        print("aniMOut")
        homeButton.animate([.position(CGPoint(x: homeButton.frame.midX-100, y:homeButton.frame.midY )),
                            .duration(0.6)])
        
        backButton.animate([.position(CGPoint(x: backButton.frame.midX+100, y:backButton.frame.midY )),
                            .duration(0.6)])
        
        Motion.delay(0.2) { [weak self] in
            self?.confirmButton.animate([.position(CGPoint(x: (self?.confirmButton.frame.midX)!+100, y:(self?.confirmButton.frame.midY)! )),
                                        .duration(0.6)])
        }
    }
}

extension FavTableViewController: UISearchResultsUpdating
{
    //实时搜索
    func updateSearchResults(for searchController: UISearchController) {
        if homeButton.frame.midX > UIScreen.main.bounds.width{
            animateButtonsOut()
        }
        tableView?.isEditing = false
        selectedCellIndex.removeAll()
        let itemList = currentData.getAllItem()
        selectedCellIndex.removeAll()
        filteredCell.removeAll()
        let searchText = controller.searchBar.text!
        DispatchQueue.global().async {[weak self] () -> () in
            guard let strongSelf = self else { return }
            for item in itemList{
                if item["title"]!.containsIgnoringCase(find: searchText)||item["url"]!.containsIgnoringCase(find: searchText){
                    strongSelf.filteredCell.append(item)
                }
            }
            DispatchQueue.main.async {self?.tableView?.reloadData()}
        }
    }
}

private extension FavTableViewController{
    func selectItem(at:IndexPath){
        guard let cell = tableView?.cellForRow(at: at) else{return}
        print("select ")
        cell.setSelected(true, animated: true)
        if controller.isActive{
            //selectedCellIndex.append(filteredCellIndex[at.row])
        }
        else{
            selectedCellIndex.append(at.row)
        }
    }
    
    func deselectItem(at:IndexPath){
        guard let cell = tableView?.cellForRow(at: at) else{return}
        print("deselect")
        cell.setSelected(false, animated: true)
        if controller.isActive{
            /*for i in 0..<selectedCellIndex.count{
                if selectedCellIndex[i] == filteredCellIndex[at.row]{
                    selectedCellIndex.remove(at: i)
                    break
                }
            }*/
        }
        else{
            for i in 0..<selectedCellIndex.count{
                if selectedCellIndex[i] == at.row{
                    selectedCellIndex.remove(at: i)
                    break
                }
            }
        }
    }
    
    func isSelected(at:IndexPath)->Bool{
        guard (tableView?.cellForRow(at: at)) != nil else{return false}
        if controller.isActive{
           /* for i in 0..<selectedCellIndex.count{
                if selectedCellIndex[i] == filteredCellIndex[at.row]{
                    return true
                }
            }*/
            return false
        }
        else{
            for i in 0..<selectedCellIndex.count{
                if selectedCellIndex[i] == at.row{
                    return true
                }
            }
            return false
        }
    }
    
    func reverseSelectionState(at:IndexPath){
        if isSelected(at: at){deselectItem(at: at)}
        else{selectItem(at: at)}
    }
    
    func multiDelete(){
        guard var fullList = currentData.getFullList() else {return}
        selectedCellIndex.sort()
        for i in selectedCellIndex.reversed(){
            if currentData.getType(index: i) == "folder"{
                 currentData.deleteFolder(title: fullList[i])
            }
            else{
                currentData.deleteBookmark(index: i)
            }
            if !controller.isActive{
                tableView?.deleteRows(at: [IndexPath(row: i, section: 0)], with: .left)
            }
        }
        selectedCellIndex.removeAll()
        updateSearchResults(for: controller)
        Motion.delay(0.3) { [weak self] in
            self?.tableView?.reloadData()
        }
    }
}

private extension FavTableViewController{
    
    func initNavigationItem() {
        if let title = currentFolderName{
            navigationItem.titleLabel.text = title
        }
        else{
            navigationItem.titleLabel.text = "Bookmarks"
        }
        
        let searchButton = IconButton(image: Icon.cm.search)
        searchButton.addTarget(self, action: #selector(handleSearchButton(button:)), for: .touchUpInside)
        navigationItem.rightViews = [searchButton]
    }
    
    func initButtons(){
        let homeButtonSize = CGSize(width: 56, height: 56)
        let homeButtonSize2 = CGSize(width: 46, height: 46)
        let bottomInset: CGFloat = 24
        let bottomInset2: CGFloat = 144
        let bottomInset3: CGFloat = 84
        let bottomInset4: CGFloat = 204
        let rightInset: CGFloat = 24
        
        homeButton = FABButton(image: Icon.home, tintColor: .white)
        homeButton.pulseColor = .white
        homeButton.backgroundColor = Color.orange.base
        homeButton.motionIdentifier = "HomeButton"
        homeButton.addTarget(self, action: #selector(handleHomeButton(button:)), for: .touchUpInside)
        view.layout(homeButton)
            .bottom(bottomInset)
            .right(rightInset)
            .size(homeButtonSize)
        
        backButton = FABButton(image: Icon.arrowBack, tintColor: .white)
        backButton.pulseColor = .white
        backButton.backgroundColor = Color.orange.base
        backButton.motionIdentifier = "BackButton"
        backButton.addTarget(self, action: #selector(handleBackButton(button:)), for: .touchUpInside)
        view.layout(backButton)
            .bottom(bottomInset)
            .right(rightInset-100)
            .size(homeButtonSize2)
        
        deleteButton = FABButton(image: Icon.visibilityOff, tintColor: .white)
        deleteButton.pulseColor = .white
        deleteButton.backgroundColor = Color.red.base
        deleteButton.motionIdentifier = "DeleteButton"
        deleteButton.addTarget(self, action: #selector(handleDeleteButton(button:)), for: .touchUpInside)
        view.layout(deleteButton)
            .bottom(bottomInset2)
            .right(rightInset-100)
            .size(homeButtonSize2)
        
        moreButton = FABButton(image: Icon.menu, tintColor: .white)
        moreButton.pulseColor = .white
        moreButton.backgroundColor = Color.blue.base
        moreButton.motionIdentifier = "MoreButton"
        moreButton.addTarget(self, action: #selector(handleMoreButton(button:)), for: .touchUpInside)
        view.layout(moreButton)
            .bottom(bottomInset3)
            .right(rightInset-100)
            .size(homeButtonSize2)
        
        renameButton = FABButton(image: Icon.addCircle, tintColor: .white)
        renameButton.pulseColor = .white
        renameButton.backgroundColor = Color.blue.base
        renameButton.motionIdentifier = "RenameButton"
        renameButton.addTarget(self, action: #selector(handleRenameButton(button:)), for: .touchUpInside)
        view.layout(renameButton)
            .bottom(bottomInset4)
            .right(rightInset-100)
            .size(homeButtonSize2)
        
        confirmButton = FABButton(image: Icon.check, tintColor: .white)
        confirmButton.pulseColor = .white
        confirmButton.backgroundColor = Color.blue.base
        confirmButton.motionIdentifier = "ConfirmButton"
        confirmButton.addTarget(self, action: #selector(handleConfirmButton(button:)), for: .touchUpInside)
        view.layout(confirmButton)
            .bottom(bottomInset3)
            .right(rightInset-100)
            .size(homeButtonSize2)
        numLabel.frame = CGRect(x: confirmButton.frame.maxX+8, y: confirmButton.frame.minY+10, width: confirmButton.frame.width/2, height: confirmButton.frame.height/2)
        numLabel.backgroundColor = Color.blue.lighten2
        numLabel.layer.cornerRadius = numLabel.frame.height/2
        numLabel.layer.masksToBounds = true
        numLabel.textColor = Color.grey.lighten5
        numLabel.textAlignment = .center
        numLabel.motionIdentifier = "numLabel"
        confirmButton.addSubview(numLabel)
    }
    
    func layoutMoveModeButtons(){
        let homeButtonSize = CGSize(width: 56, height: 56)
        let homeButtonSize2 = CGSize(width: 46, height: 46)
        let bottomInset: CGFloat = 24
        let bottomInset2: CGFloat = 144
        let bottomInset3: CGFloat = 84
        let bottomInset4: CGFloat = 204
        let rightInset: CGFloat = 24
        backButton.removeFromSuperview()
        deleteButton.removeFromSuperview()
        moreButton.removeFromSuperview()
        confirmButton.removeFromSuperview()
        homeButton.removeFromSuperview()
        
        
        homeButton = FABButton(image: Icon.home, tintColor: .white)
        homeButton.pulseColor = .white
        homeButton.backgroundColor = Color.orange.base
        homeButton.motionIdentifier = "HomeButton"
        homeButton.addTarget(self, action: #selector(handleHomeButton(button:)), for: .touchUpInside)
        backButton = FABButton(image: Icon.arrowBack, tintColor: .white)
        backButton.pulseColor = .white
        backButton.backgroundColor = Color.orange.base
        backButton.motionIdentifier = "BackButton"
        backButton.addTarget(self, action: #selector(handleBackButton(button:)), for: .touchUpInside)
        deleteButton = FABButton(image: Icon.visibilityOff, tintColor: .white)
        deleteButton.pulseColor = .white
        deleteButton.backgroundColor = Color.red.base
        deleteButton.motionIdentifier = "DeleteButton"
        deleteButton.addTarget(self, action: #selector(handleDeleteButton(button:)), for: .touchUpInside)
        moreButton = FABButton(image: Icon.clear, tintColor: .white)
        moreButton.pulseColor = .white
        moreButton.backgroundColor = Color.blue.base
        moreButton.motionIdentifier = "MoreButton"
        moreButton.addTarget(self, action: #selector(handleMoreButton(button:)), for: .touchUpInside)
        confirmButton = FABButton(image: Icon.check, tintColor: .white)
        confirmButton.pulseColor = .white
        confirmButton.backgroundColor = Color.blue.base
        confirmButton.motionIdentifier = "ConfirmButton"
        confirmButton.addTarget(self, action: #selector(handleConfirmButton(button:)), for: .touchUpInside)
        confirmButton.addSubview(numLabel)
        renameButton = FABButton(image: Icon.addCircle, tintColor: .white)
        renameButton.pulseColor = .white
        renameButton.backgroundColor = Color.blue.base
        renameButton.motionIdentifier = "RenameButton"
        renameButton.addTarget(self, action: #selector(handleRenameButton(button:)), for: .touchUpInside)
        
        view.layout(renameButton)
            .bottom(bottomInset4)
            .right(rightInset-100)
            .size(homeButtonSize2)
        
        view.layout(backButton)
            .bottom(bottomInset)
            .right(rightInset)
            .size(homeButtonSize2)
        
        
        view.layout(deleteButton)
            .bottom(bottomInset2)
            .right(rightInset-100)
            .size(homeButtonSize2)
        
        
        view.layout(moreButton)
            .bottom(bottomInset3)
            .right(rightInset-100)
            .size(homeButtonSize2)
        
        
        view.layout(confirmButton)
            .bottom(bottomInset3)
            .right(rightInset)
            .size(homeButtonSize2)
        
        
        view.layout(homeButton)
            .bottom(bottomInset)
            .right(rightInset-100)
            .size(homeButtonSize)
    }
    
    func layoutNormalModeButtons(){
        backButton.removeFromSuperview()
        deleteButton.removeFromSuperview()
        moreButton.removeFromSuperview()
        confirmButton.removeFromSuperview()
        homeButton.removeFromSuperview()
        renameButton.removeFromSuperview()
        initButtons()
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
}
