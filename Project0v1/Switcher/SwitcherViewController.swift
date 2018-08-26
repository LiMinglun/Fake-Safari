//
//  SwitcherViewController.swift
//  Project0v1
//
//  Created by Michael on 2/22/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material
import Motion

let yOffsetSpeed: CGFloat = 200.0
let xOffsetSpeed: CGFloat = 200.0

class SwitcherViewController: UIViewController,UICollectionViewDelegate {

    var collectionView : UICollectionView?
    let webArray:WebviewsArray
    let layout = BouncyLayout(damping: 1, frequency: 2.5)
    let focusPage:Int
    var collectionViewTap:UITapGestureRecognizer?
    var collectionViewPan:UIPanGestureRecognizer?
    var root:BigBrother
    var insets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    let cellWidth = UIScreen.main.bounds.width
    let cellHeight = UIScreen.main.bounds.height/4 - (UIScreen.main.bounds.height/4).truncatingRemainder(dividingBy: 2)
    var currentOffset:Float = -10{
        didSet{
            saveCurrrentOffset(OFFSET: currentOffset)
        }
    }
    
    init(toPage pageNum:Int, WebArray wa:WebviewsArray, ROOT Root:BigBrother) {
        focusPage = pageNum
        webArray = wa
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        root = Root
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView!.reloadData()
        let offset = readCurrentOffset()
        if offset.x != 0 || webArray.count<4{
            scrollTo(index: focusPage, animated: false)}
        else{collectionView?.setContentOffset(offset, animated: false)}
        
       
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initViewBackground()
        initCollectionView()
        initAddButton()
        initGesture()
        isMotionEnabled = true
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        root.statusBarStyle = .lightContent
        root.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        root.statusBarStyle = .default
        root.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

extension SwitcherViewController: UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return webArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCell", for: indexPath) as! TabCell
        
        var fullPath = NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending("error").appending(".jpeg")
        if let info = webArray.getWebInfo(AT: indexPath.row){
            fullPath = NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending(info["image"]!).appending(".jpeg")
            let host = URL(string: info["url"] ?? "")!.host
            cell.titleLabel.text = host
            if (info["title"] ?? "").isEmpty{cell.titleLabel2.text=host}else{cell.titleLabel2.text=info["title"]}
            cell.contentView.motionIdentifier = info["image"]
            
        }
        
        if let savedImage = UIImage(contentsOfFile: fullPath) {
            cell.image = savedImage
            let yOffset = ((collectionView.contentOffset.y - cell.frame.origin.y) / savedImage.height) * yOffsetSpeed
            let xOffset = ((collectionView.contentOffset.x - cell.frame.origin.x) / savedImage.width) * xOffsetSpeed
            cell.offset(CGPoint(x: xOffset,y :yOffset))
        } else {
            cell.image = UIImage(named: "default")!
            let yOffset = ((collectionView.contentOffset.y - cell.frame.origin.y) / UIImage(named: "default")!.height) * yOffsetSpeed
            let xOffset = ((collectionView.contentOffset.x - cell.frame.origin.x) / UIImage(named: "default")!.width) * xOffsetSpeed
            cell.offset(CGPoint(x: xOffset,y :yOffset))
        }
        
        return cell
    }
}

private extension SwitcherViewController{
    
    func saveCurrrentOffset(OFFSET num:Float){
        let index = String(describing: num)
        let filePath:String = NSHomeDirectory() + "/Documents/.Usr/Caches/SwitcherOffset.txt"
        try! index.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
    }
    
    func readCurrentOffset() -> CGPoint{
        if let tData = NSData(contentsOf: URL(string: "file://" + NSHomeDirectory() + "/Documents/.Usr/Caches/SwitcherOffset.txt")!){
            let txtData:String = (NSString(data: tData as Data, encoding: String.Encoding.utf8.rawValue))! as String
            let yTemp = Float(txtData)!
            let point = CGPoint(x: 0, y: CGFloat(yTemp))
            return point
        }
        return CGPoint(x: -1, y: -1)
    }
    
    func scrollTo(index:Int, animated:Bool){
        guard let collectionView = collectionView else { return }
        
        if webArray.count < 4{
            return
        }
        
        let pageOffset: CGFloat
        let proposedContentOffset: CGPoint
        
        if index >= webArray.count - 3 {
            pageOffset = collectionView.contentSize.height - collectionView.frame.size.height
            
        }
        else{
            pageOffset = CGFloat(index) * cellHeight - collectionView.contentInset.top
        }
        
        proposedContentOffset = CGPoint(x: 0, y: pageOffset)
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.collectionView?.setContentOffset(proposedContentOffset, animated: false)
        }){ [weak self] tag in
            self?.currentOffset = Float(pageOffset)
            return
        }
        
    }
    
    func removeTab(at indexP:IndexPath){
        let swipedCellIndex = indexP
            if (swipedCellIndex.row) < webArray.activeViewIndex{
                webArray.activeViewIndex -= 1
                webArray.deleteTab(at: swipedCellIndex.row)
                self.collectionView?.deleteItems(at: [swipedCellIndex])
                currentOffset = Float(collectionView!.contentOffset.y)
            }
            else if (swipedCellIndex.row) == webArray.activeViewIndex && (swipedCellIndex.row) != 0 {
                webArray.activeViewIndex -= 1
                webArray.deleteTab(at: swipedCellIndex.row)
                self.collectionView?.deleteItems(at: [swipedCellIndex])
                currentOffset = Float(collectionView!.contentOffset.y)
            }
            else if (swipedCellIndex.row) > webArray.activeViewIndex{
                webArray.deleteTab(at: swipedCellIndex.row)
                self.collectionView?.deleteItems(at: [swipedCellIndex])
                currentOffset = Float(collectionView!.contentOffset.y)
            }
            else if (swipedCellIndex.row) == webArray.activeViewIndex && (swipedCellIndex.row) == 0 && webArray.count != 1{
                webArray.deleteTab(at: swipedCellIndex.row)
                self.collectionView?.deleteItems(at: [swipedCellIndex])
                currentOffset = Float(collectionView!.contentOffset.y)
            }
            else if (swipedCellIndex.row) == webArray.activeViewIndex && (swipedCellIndex.row) == 0 && webArray.count == 1{
                if FileManager.default.fileExists(atPath: NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending(webArray.getWebInfo(AT: swipedCellIndex.row)!["image"]! + ".jpeg")){
                    let url = URL(string: "file://" + NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending(webArray.getWebInfo(AT: swipedCellIndex.row)!["image"]! + ".jpeg"))!
                    try! FileManager.default.removeItem(at: url)
                }
                webArray.updateUrl(forIndex: 0, URL: webArray.welcomePage)
                webArray.updateTitle(forIndex: 0, TITLE: "")
                webArray.updatePointer(Pointer: nil, forIndex: 0)
                transition(to: webArray.forceGetIntance(AT: 0))
            }
    }
    
    func initViewBackground() {
        view.backgroundColor = UIColor.black
    }
    
    func initAddButton(){
        var fabButton: FABButton!
        fabButton = FABButton(image: Icon.cm.add, tintColor: .white)
        fabButton.pulseColor = .white
        fabButton.backgroundColor = Color.red.base
        fabButton.motionIdentifier = "LowerToolbar"
        fabButton.addTarget(self, action: #selector(handleAddTab(button:)), for: .touchUpInside)
        view.layout(fabButton).bottom(45).right(45).width(45).height(45)
    }
    
    func initCollectionView() {
        collectionView?.backgroundColor = UIColor.clear
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.register(TabCell.self, forCellWithReuseIdentifier:"TabCell")
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView?.contentInset = UIEdgeInsets(top: insets.top, left: insets.left, bottom: insets.bottom, right: insets.right)
        view.addSubview(collectionView!)
        NSLayoutConstraint.activate([
            collectionView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView!.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        layout.itemSize = CGSize(
            width: cellWidth,
            height: cellHeight
        )
        layout.minimumLineSpacing = 10
        
    }
    
    func initGesture(){
        collectionViewTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        collectionViewPan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        collectionViewTap?.delegate = self
        collectionViewPan?.delegate = self
        //self.view.addGestureRecognizer(collectionViewTap!)
        self.view.addGestureRecognizer(collectionViewPan!)
    }
    
    func transition(to tab:WebViewController){
        webArray.activeViewIndex = tab.indexNum
        root.transition(to: tab)
    }
    
    func transition(to tab:HomePageNavigationController, over:WebViewController){
        webArray.activeViewIndex = over.indexNum
        root.transition(to: tab)
    }
    
    func restoreTab(){
        let newTab = WebViewController(URL: webArray.welcomePage, NO: 0, IMEI: 0, WebArray: webArray,ROOT: root)
        webArray.insert(tab: newTab, to: 0, withURL: webArray.welcomePage)
        Motion.delay(0.075) { [weak self] in
            self?.transition(to: newTab)
        }
    }
}

extension SwitcherViewController{

    func addTab(url: String){
        let newTab = WebViewController(URL: url, NO: webArray.activeViewIndex + 1, IMEI: 0, WebArray: webArray,ROOT: root)
        var scrollTime = 0.0
        if let visCells = collectionView?.indexPathsForVisibleItems{
            var visCellRows = [Int]()
            let currentCellPath = webArray.activeViewIndex
            for i in visCells{
                visCellRows.append(i.row)
            }
            visCellRows.sort()
            if let index = visCellRows.index(of: currentCellPath), index != visCellRows.count-1{
                
            }
            else{
                scrollTo(index: webArray.activeViewIndex, animated: true)
                scrollTime = 0.2
            }
        }
        Motion.delay(scrollTime) { [weak self] in
            guard let strongSelf = self else{return}
            strongSelf.webArray.insert(tab: newTab, to: strongSelf.webArray.activeViewIndex + 1, withURL: url)
            strongSelf.collectionView?.insertItems(at: [IndexPath(row: strongSelf.webArray.activeViewIndex + 1, section: 0)])
            Motion.delay(0.1) {
                if url == strongSelf.webArray.welcomePage{
                    strongSelf.transition(to: HomePageNavigationController(rootViewController: HomePageController(currentPage: newTab.indexNum,path: "", url: nil, webarray: strongSelf.webArray, shouldDisplayKeyboard: false, shouldShowLowerTool:true, shouldShowBackForthButton:false)), over: newTab)
                }
                else{
                    strongSelf.transition(to: newTab)
                }
            }
        }
    }
    
    @objc func handleAddTab(button: UIButton) {
        addTab(url: webArray.welcomePage)
    }
    
    @objc func handleTap (sender:UITapGestureRecognizer) {
        let touchPoint = sender.location(ofTouch: 0, in: collectionView)
        let indexPath = collectionView?.indexPathForItem(at: touchPoint)
        
        if (indexPath != nil) {
            
            collectionView?.cellForItem(at: indexPath!)!.animate(.scale(x: 0.95, y: 0.95, z: 0.95),
                                                                 .duration(0.09)
            )
            Motion.delay(0.015) { [weak self] in
                self?.transition(to: (self?.webArray.forceGetIntance(AT: indexPath!.row))!)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)!.animate(.scale(x: 0.95, y: 0.95, z: 0.95),
                                                             .duration(0.09)
        )
        Motion.delay(0.015) { [weak self] in
            guard let strongSelf = self else{return}
            let tab = strongSelf.webArray.forceGetIntance(AT: indexPath.row)
            if let tabUrl = strongSelf.webArray.getWebInfo(AT: indexPath.row)?["url"], tabUrl == "homePage"{
                strongSelf.transition(to: HomePageNavigationController(rootViewController: HomePageController(currentPage: indexPath.row,path: "", url: nil, webarray: strongSelf.webArray, shouldDisplayKeyboard: false, shouldShowLowerTool:true, shouldShowBackForthButton:false)), over: tab)
                
                return
                //strongSelf.transition(to: HomePageController(currentPage: indexPath.row,path: "", url: nil, webarray: strongSelf.webArray, shouldDisplayKeyboard: false, shouldShowLowerTool:true, shouldShowBackForthButton:false), over: tab)
            }
            
            strongSelf.transition(to: tab)
            
        }
    }
    
    @objc func handlePan (sender:UIPanGestureRecognizer) {
        let swipeLocation = sender.location(in: collectionView)
        let indexPath = collectionView?.indexPathForItem(at: swipeLocation)
        var swipedCell:TabCell?
        var swipedCellIndex:IndexPath?
        
        if let indexP = indexPath{
            if collectionView?.cellForItem(at: indexP) != nil{
                swipedCell = (collectionView?.cellForItem(at: indexP) as! TabCell)
            }
        }
        
        let visCell = self.collectionView?.indexPathsForVisibleItems
        if let visibleCell = visCell{
            for i in visibleCell {
                if (collectionView?.cellForItem(at: i) as! TabCell).center.x != (collectionView?.cellForItem(at: i) as! TabCell).initialX{
                    swipedCell = (collectionView?.cellForItem(at: i) as! TabCell)
                    swipedCellIndex = i
                }
            }
        }
        
        if sender.state == UIGestureRecognizerState.began{
            guard let collectionViewLayout = self.collectionView?.collectionViewLayout as? BouncyLayout else {return}
            let behaviors = collectionViewLayout.animator.behaviors
            collectionViewLayout.animator.removeAllBehaviors()
            for i in behaviors{
                collectionViewLayout.animator.addBehavior(i)
            }
            //do
        }
        else if sender.state == UIGestureRecognizerState.changed{
            
            let translation = sender.translation(in: self.view)
            swipedCell?.center.x += translation.x
            sender.setTranslation(CGPoint.zero, in: collectionView)
        }
        else if sender.state == UIGestureRecognizerState.ended || sender.state == UIGestureRecognizerState.cancelled{
            if let swipedcell = swipedCell{
                if (swipedcell.initialX - swipedcell.center.x) > 125 || sender.velocity(in: self.view).x < -950{
                    if let indexP = swipedCellIndex{
                        let cell = (collectionView?.cellForItem(at: indexP) as! TabCell)
                        cell.animate(.duration(0.1),
                                     .position(CGPoint(x: -200, y: cell.frame.midY) ),
                                     .completion({ [weak self] in
                                        cell.animate(.fadeOut)
                                        self?.removeTab(at: indexP)
                                     }))
                        
                        return
                    }
                }
                swipedcell.animate(.duration(0.3),
                                   .position(CGPoint(x: swipedcell.initialX,
                                                     y: swipedcell.center.y)),
                                   .completion({ [weak self] in
                                    
                                    var imageViewPosition = swipedCell?.center
                                    imageViewPosition?.x = swipedcell.initialX
                                    swipedcell.center = imageViewPosition!
                                    sender.setTranslation(CGPoint.zero, in: self?.collectionView)
                                    if let swiI = swipedCellIndex{
                                        self?.collectionView?.reloadItems(at: [swiI])
                                    }
                                   
                                   }))
                
            }
        }
    }
}

extension SwitcherViewController:UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension SwitcherViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = self.collectionView else {return}
        let visibleCellsIndex = collectionView.indexPathsForVisibleItems
        for i in visibleCellsIndex {
            guard let parallaxCell = collectionView.cellForItem(at: i) as? TabCell else {return}
            let yOffset = ((collectionView.contentOffset.y - parallaxCell.frame.origin.y) / parallaxCell.imageHeight) * yOffsetSpeed
            let xOffset = ((collectionView.contentOffset.x - parallaxCell.frame.origin.x) / parallaxCell.imageWidth) * xOffsetSpeed
            parallaxCell.offset(CGPoint(x: xOffset,y :yOffset))
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        /*guard let collectionViewLayout = self.collectionView?.collectionViewLayout as? BouncyLayout else {return}
        let behaviors = collectionViewLayout.animator.behaviors
        collectionViewLayout.animator.removeAllBehaviors()
        for i in behaviors{
            collectionViewLayout.animator.addBehavior(i)
        }*/
        currentOffset = Float((collectionView?.contentOffset.y)!)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        currentOffset = Float((collectionView?.contentOffset.y)!)
    }

}
