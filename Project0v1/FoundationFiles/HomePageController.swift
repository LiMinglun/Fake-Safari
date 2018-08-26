//
//  HomePageController.swift
//  Project0v1
//
//  Created by Michael on 3/25/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material
import Motion

let cellTextHeight:CGFloat = 30

class HomePageController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, TextFieldDelegate{
    
    
    
    let collectionViewInset = UIEdgeInsets(top: 20, left: (Screen.width - 4*60)/5, bottom: 20, right: (Screen.width - 4*60)/5) //use CellSize =?>60
    let cellSize:CGFloat = 60
    let homeButtonSize2 = CGSize(width: 46, height: 46)
    let homeButtonSize = CGSize(width: 56, height: 56)
    var orig1:CGPoint = CGPoint()
    var orig2:CGPoint = CGPoint()
    var tag = true
    let bottomInset: CGFloat = 24
    let rightInset: CGFloat = 24
    let currentPath:String
    var shouldBecomeFistResponder:Bool
    var shouldShowToolBar:Bool
    var shouldShowBackButton:Bool
    var lowerToolBar:Toolbar!
    var upperToolBar:UIView!
    let urlField = TextField()
    var homeButton: FABButton!
    
    fileprivate var currentWeb = 0
    fileprivate var rootFavData:FavDataStructure
    fileprivate let layout = UICollectionViewFlowLayout()
    fileprivate var collectionView:UICollectionView!
    fileprivate var longPressGesture: UILongPressGestureRecognizer!
    fileprivate let webArray:WebviewsArray
    fileprivate let currentUrl:String?
    
    init(currentPage:Int, path:String, url:String?, webarray:WebviewsArray, shouldDisplayKeyboard: Bool, shouldShowLowerTool:Bool, shouldShowBackForthButton:Bool){
        rootFavData = FavDataStructure(path: path, passw0rd: nil)
        currentUrl = url
        webArray = webarray
        currentPath = path
        currentWeb = currentPage
        shouldBecomeFistResponder = shouldDisplayKeyboard
        shouldShowToolBar = shouldShowLowerTool
        shouldShowBackButton = shouldShowBackForthButton
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillShow(notif:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillHide(notif:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldBecomeFistResponder{
            _ = urlField.becomeFirstResponder()
            urlField.selectAll(nil)
            shouldBecomeFistResponder = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        urlField.resignFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUpperBar()
        initCollectionView()
        // init home button is in "did layout subview"
        
        // hide navigation bar
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = navigationController as? UIGestureRecognizerDelegate
        
        //
        isMotionEnabled = true
        //
        
        if shouldShowToolBar{
            initLowerBar()
            if currentPath == ""{
                view.motionIdentifier = String(describing: webArray.forceGetIntance(AT: currentWeb).IMEI)
            }
            //is homePage, so reduce collectionView size to accomondate lower bar& add motion identifier
        view.layout(collectionView).left().right().bottom(lowerToolBar.frame.height).top(upperToolBar.frame.height)
            
        }
        else{
            //is not a child view in home page
            if currentPath == ""{
            collectionView.transition(.scale(0.93),
                                      .fadeOut)}
            view.layout(collectionView).left().right().bottom().top(upperToolBar.frame.height)
        }
        
        isMotionEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if tag{
            orig1 = CGPoint(x: view.bounds.width - rightInset - homeButtonSize2.width, y: view.bounds.height - bottomInset - homeButtonSize2.height)
            if shouldShowBackButton{
                if shouldShowToolBar{
                    orig1 = CGPoint(x: view.bounds.width - rightInset - homeButtonSize2.width, y: view.bounds.height - bottomInset - lowerToolBar.frame.height - homeButtonSize2.height)
                }
                initHomeButton()
            }
            tag = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rootFavData.getFullList()?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollCell", for: indexPath) as! HomePageCell
        
        if let dataList = rootFavData.getFullList(){
            cell.lab.text = dataList[indexPath.row]
            cell.lab.sizeToFit()
            cell.lab.frame.size.width = cell.contentView.frame.width
            if rootFavData.getType(index: indexPath.row) == "folder"{
                cell.folderView.isHidden = false
            }
            else{
                let index = dataList[indexPath.row].index(dataList[indexPath.row].startIndex, offsetBy:1)
                cell.viewLabel.text = dataList[indexPath.row][dataList[indexPath.row].startIndex..<index].uppercased()
                cell.viewLabel.backgroundColor = generateColor(text: cell.viewLabel.text!)
            }
        }
        
        return cell
    }
    

    
    @objc func handleHomeButton(button: UIButton) {
        if urlField.isFirstResponder{
            urlField.resignFirstResponder()
            return
        }
        urlField.resignFirstResponder()
        navigationController?.popViewController(animated: true)
        if currentPath == ""{
            dismissAll()
        }
    }
    

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        (collectionView.cellForItem(at: indexPath) as! HomePageCell).viewLabel.animate(
                     .duration(0.05),
                     .scale(0.90),
                     .completion({
            if let a = collectionView.cellForItem(at: indexPath) as? HomePageCell{
                    a.viewLabel.animate([.scale(1),.duration(0.05)])}
                     }))
        
        
        
        if rootFavData.getType(index: indexPath.row) == "folder"{
            urlField.resignFirstResponder()
            navigationController?.pushViewController(HomePageController(currentPage: currentWeb,path: currentPath + rootFavData.getRawName(index: indexPath.row)!+"/", url: currentUrl, webarray: webArray, shouldDisplayKeyboard: false, shouldShowLowerTool:shouldShowToolBar, shouldShowBackForthButton:true), animated: true)
            //present(, animated: true)
        }
        else{
            if let url = rootFavData.getBookmarkURL(index: indexPath.row){
                urlField.resignFirstResponder()
                let tab = self.webArray.forceGetIntance(AT: currentWeb)
                tab.urlToLoad = url
                if tab.lowerToolBar != nil{
                    _ = tab.loadUrl(Url: url)
                }
                dismissAll()
                if shouldShowToolBar{
                    (statusBarController as! BigBrother).transition(to: tab)
                }
            }
        }
    }
    
    func generateColor(text:String)->UIColor{
        let colorList = [Color.red.accent1,Color.brown.lighten1,Color.blueGrey.lighten1,Color.amber.accent1,Color.blue.lighten1,Color.cyan.lighten1,Color.green.lighten1,Color.indigo.accent1,Color.lightBlue.darken2,Color.yellow.base,Color.orange.lighten1]
        
        let num = text.md5()
        let index = num.index(num.startIndex, offsetBy:1)
        let pseudoRandom = num[num.startIndex..<index]//.substring(to: index).lowercased()
        if let index = Int(pseudoRandom){
            return colorList[index]
        }
        else{
            if pseudoRandom == "a"{
                return colorList[10]
            }
            else if pseudoRandom == "b"{
                return colorList[0]
            }
            else if pseudoRandom == "c"{
                return colorList[1]
            }
            else if pseudoRandom == "d"{
                return colorList[2]
            }
            else if pseudoRandom == "e"{
                return colorList[3]
            }
            else if pseudoRandom == "f"{
                return colorList[4]
            }
            return colorList[10]
        }
    }
   

    
    @objc func handleSwitcher(button: UIButton) {
        updatePreviewFoto()
        dismissAll()
        view.motionIdentifier = String(describing: webArray.forceGetIntance(AT: currentWeb).IMEI)
        (statusBarController as! BigBrother).transition(to: SwitcherViewController(toPage: webArray.activeViewIndex, WebArray: webArray,ROOT: (statusBarController as! BigBrother)))
    }
    
    func dismissAll(){
        /*var rootVC = self.presentingViewController
        while let parent = rootVC?.presentingViewController {
            rootVC = parent
        }
        rootVC?.dismiss(animated: false, completion: nil)*/
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func updatePreviewFoto(){
        let lastImage:UIImage! = self.collectionView.screenShot()!
        asyncSaveImage(currentImage: lastImage, persent: 0.1, imageName: String(webArray.forceGetIntance(AT: currentWeb).IMEI) + ".jpeg")
    }
    
    func asyncSaveImage(currentImage: UIImage, persent: CGFloat, imageName: String){
        DispatchQueue.global().async {
            if let imageData = UIImageJPEGRepresentation(currentImage, persent) as NSData? {
                let fullPath = NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending(imageName)
                imageData.write(toFile: fullPath, atomically: true)
            }
        }
    }
}

//collectionView cell
class HomePageCell: UICollectionViewCell {
    
    let lab = UILabel()
    let viewLabel = UILabel()
    let folderView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lab.frame = CGRect(x: contentView.bounds.minX, y: contentView.bounds.maxY-cellTextHeight+5, width: contentView.bounds.width, height: cellTextHeight)
        lab.textColor = Color.grey.darken3
        lab.font = UIFont.systemFont(ofSize: 10)
        lab.textAlignment = .center
        lab.numberOfLines = 2
        contentView.addSubview(lab)
        
        viewLabel.frame = CGRect(x: contentView.bounds.minX, y: contentView.bounds.minY, width: contentView.bounds.width, height: contentView.bounds.width)
        viewLabel.backgroundColor = Color.green.lighten2
        viewLabel.layer.cornerRadius = viewLabel.frame.height/6
        viewLabel.layer.masksToBounds = true
        viewLabel.font = UIFont.systemFont(ofSize: 30)
        viewLabel.textColor = Color.grey.lighten5
        viewLabel.textAlignment = .center
        contentView.addSubview(viewLabel)
        
        folderView.image = Icon.work
        folderView.frame = CGRect(x: contentView.bounds.minX, y: contentView.bounds.minY, width: contentView.bounds.width, height: contentView.bounds.width)
        folderView.backgroundColor = UIColor.clear
        folderView.isHidden = true
        contentView.addSubview(folderView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //var collection = KDDragAndDropCollectionView()
}


// view initializers
extension HomePageController{
    
    func initHomeButton(){
        homeButton = FABButton(image: Icon.arrowBack, tintColor: .white)
        homeButton.pulseColor = .white
        homeButton.backgroundColor = Color.orange.base
        homeButton.addTarget(self, action: #selector(handleHomeButton), for: .touchUpInside)
        homeButton.frame = CGRect(origin: orig1, size: homeButtonSize)
        homeButton.motionIdentifier = "homeButton"
        view.addSubview(homeButton)
    }
    
    func initLowerBar(){
        var backButton: FlatButton!
        var forwardButton: FlatButton!
        var menuButton: FlatButton!
        var homeButton: FlatButton!
        var toolButton: FlatButton!
        var switcherButton: FlatButton!
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        var statusBarOffsetAdjustment: CGFloat {
            return UIApplication.shared.statusBarFrame.height
        }
        
        backButton = FlatButton(image: Icon.cm.skipBackward, tintColor: .white)
        backButton.pulseColor = .white
        backButton.isEnabled = false
        
        forwardButton = FlatButton(image: Icon.cm.skipForward, tintColor: .white)
        forwardButton.pulseColor = .white
        forwardButton.isEnabled = false
        
        menuButton = FlatButton(image: Icon.cm.menu, tintColor: .white)
        menuButton.pulseColor = .white
        menuButton.isEnabled = false
        
        homeButton = FlatButton(image: Icon.cm.shuffle, tintColor: .white)
        homeButton.pulseColor = .white
        homeButton.isEnabled = false
        
        toolButton = FlatButton(image: Icon.cm.check, tintColor: .white)
        toolButton.pulseColor = .white
        toolButton.isEnabled = false
        
        switcherButton = FlatButton(image: Icon.cm.settings, tintColor: .white)
        switcherButton.pulseColor = .white
        switcherButton.addTarget(self, action: #selector(handleSwitcher(button:)), for: .touchUpInside)
        
        lowerToolBar = Toolbar()
        view.layout(lowerToolBar).centerHorizontally().bottom().width(screenWidth).height(40)
        lowerToolBar.centerViews = [backButton, forwardButton,menuButton,homeButton, toolButton, switcherButton]
        lowerToolBar.backgroundColor = Color.blue.darken2
        lowerToolBar.motionIdentifier = "LowerToolbar"
        
    }
    
    func initCollectionView(){
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = Color.grey.lighten2
        collectionView.dataSource = self
        collectionView.delegate = self
        //collectionView.motionIdentifier = String(webArray.forceGetIntance(AT: currentWeb).IMEI)
    
        collectionView.register(HomePageCell.self, forCellWithReuseIdentifier: "CollCell")
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
        longPressGesture.minimumPressDuration = 0.8
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    func initUpperBar(){
        
        var statusBarOffsetAdjustment: CGFloat {
            return UIApplication.shared.statusBarFrame.height
        }
        upperToolBar = UIView()
        upperToolBar.backgroundColor = Color.grey.lighten5
        upperToolBar.depthPreset = .depth1
        upperToolBar.motionIdentifier = "uppBar"
        
        urlField.backgroundColor = Color.grey.lighten3
        urlField.cornerRadiusPreset = .cornerRadius3
        urlField.tintColor = Color.grey.darken4
        urlField.textInset = 8
        urlField.dividerActiveColor = Color.clear
        urlField.dividerNormalColor = Color.clear
        urlField.placeholder = "Search or enter website name"
        urlField.text = currentUrl ?? ""
        urlField.autocorrectionType = .no
        urlField.spellCheckingType = .no
        urlField.autocapitalizationType = .none
        urlField.returnKeyType = .search
        urlField.smartInsertDeleteType = .no
        urlField.placeholderAnimation = .hidden
        urlField.isClearIconButtonEnabled = true
        urlField.placeholderActiveColor = Color.blue.base
        //urlField.motionIdentifier = "urlField"
        urlField.delegate = self
        //upperToolBar.motionIdentifier = "upperToolBar"
        view.layout(upperToolBar).centerHorizontally().top().width(UIScreen.main.bounds.width).height(45+statusBarOffsetAdjustment)
        upperToolBar.layout(urlField).top(statusBarOffsetAdjustment+5).bottom(10).horizontally(left: 10, right: 10)
    }
}


// property delegates

extension HomePageController{
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("reordered")
        //rootFavData.reorder(origIndex: sourceIndexPath.row, targetIndex: destinationIndexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellSize, height: cellSize+cellTextHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return (Screen.width - 4*cellSize)/5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return collectionViewInset
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        print("target:\(proposedIndexPath)")
        print("original:\(originalIndexPath)")
        if rootFavData.getType(index: proposedIndexPath.row) == "folder"{
            print("\(proposedIndexPath) is folder")
            return originalIndexPath
        }
        rootFavData.reorder(origIndex: originalIndexPath.row, targetIndex: proposedIndexPath.row)
        return proposedIndexPath
    }
}

// delegate handlers
extension HomePageController{
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        urlField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let url = urlField.text{
            if url.isEmpty{
                urlField.resignFirstResponder()
                return true
            }
            urlField.resignFirstResponder()
            dismissAll()
            let tab = self.webArray.forceGetIntance(AT: currentWeb).loadUrl(Url: url)
            if shouldShowToolBar{
                (statusBarController as! BigBrother).transition(to: tab)
            }
        }
        else{
            urlField.resignFirstResponder()
        }
        return true
    }
    
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        let selectedIndexPath:IndexPath
        
        switch(gesture.state) {
        case .began:
            guard let indexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            selectedIndexPath = indexPath
            _ = urlField.resignFirstResponder()
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    @objc func keyboardWillShow(notif:NSNotification){
        guard shouldShowBackButton else {return}
        let dic:NSDictionary = notif.userInfo! as NSDictionary
        let a:AnyObject? = dic.object(forKey: UIKeyboardFrameEndUserInfoKey) as AnyObject
        let keyboardHeight = a?.cgRectValue.size.height ?? 0
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.homeButton.frame = CGRect(x:self.orig1.x+self.rightInset,y:self.view.bounds.height-keyboardHeight-self.homeButtonSize2.height, width: self.homeButtonSize2.width, height: self.homeButtonSize2.height)
        })
        homeButton.animate(.rotate(-90))
    }
    
    @objc func keyboardWillHide(notif:NSNotification){
        guard shouldShowBackButton else {return}
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.homeButton.frame = CGRect(x:self.orig1.x,y:self.orig1.y, width: self.homeButtonSize.width, height: self.homeButtonSize.height)
        })
        homeButton.animate(.rotate(0))
    }
}
