//
//  ViewController.swift
//  Project0v1
//
//  Created by Michael on 2/21/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import WebKit
import Material
import Motion

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate{

    //Properties
    var urlToLoad:String
    var indexNum:Int
    var IMEI:UInt32 = arc4random()//0 to stay intact
    let webArray:WebviewsArray
    var root:BigBrother
    let historyPath = NSHomeDirectory() + "/Documents/.Usr/Caches/History/"
    //UI
    lazy var webView: WKWebView = {
        () -> WKWebView in
        let config = WKWebViewConfiguration()
        let tempWebView = WKWebView(frame: .zero, configuration: config)
        tempWebView.navigationDelegate = self
        tempWebView.uiDelegate = self
        return tempWebView
    }()

    var upperToolBar:UIView!
    var lowerToolBar:Toolbar!
    var progBar:UIProgressView!
    var tempImageView:UIImageView!
    let refreshButton = IconButton(image: Icon.close)
    let urlFieldButton = UIButton(type: .roundedRect)
    var quitFullScreenButton:UIButton!
    var scrollTo = FABButton(image: Icon.check, tintColor: Color.amber.accent1)
    var cumulativeChange:CGFloat = 0
    var scrollInitY:CGFloat = 0
    //---
    var navigationStatus:NavigationStatus = .homePage{
        didSet{
            switch navigationStatus {
            case .finished:
                refreshButton.isHidden = false
                animateRefreshButtonIcon(icon: Icon.cameraRear)
                urlFieldButton.setTitle(webView.url?.host, for: .normal)
                if webView.url?.absoluteString.hasPrefix("https") ?? false{
                    animateUrlFieldButtonIcon(icon: Icon.clear)
                }
            case .comitted:
                refreshButton.isHidden = false
                animateRefreshButtonIcon(icon: Icon.cm.close)
                urlFieldButton.setTitle(webView.url?.host, for: .normal)
                animateUrlFieldButtonIcon(icon: nil)
            case .homePage:
                refreshButton.isHidden = true
                urlFieldButton.setTitle("Search", for: .normal)
                urlFieldButton.setImage(Icon.search, for: .normal)
            }
        }
    }
    
    var scrollStatus:WebviewScrollStatus = .intact{
        didSet{
            switch scrollStatus {
            case .comitted:
                upperToolBar.alpha = 1
            case .finished:
                activateFullScreenUtilities()
                upperToolBar.alpha = 0
            case .intact:
                upperToolBar.alpha = 1
                deactivateFullScreenUtilities()
            }
        }
    }
    
    init(URL url:String, NO num:Int, IMEI imei:UInt32, WebArray wa:WebviewsArray, ROOT toolbarc:BigBrother){
        urlToLoad = url
        indexNum = num
        webArray = wa
        root = toolbarc
        if imei != 0{
            IMEI = imei
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") }
    
    override func viewWillAppear(_ animated: Bool) {
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)//to fix the crash when coming back
        if webView.estimatedProgress >= 1.0{
            dismissTempImage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLowerBar()
        initWebview()
        initUpperBar()
        initTempImage()
        initProgBar()
        initFullScreenUtilities()
        initScrollTo()
        attachLongPressHandler(webView: webView)
        webArray.updatePointer(Pointer: self, forIndex: self.indexNum)
        isMotionEnabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        self.webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame == nil{
            webView.load(navigationAction.request)
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if !(webView.backForwardList.backList.isEmpty && webView.backForwardList.forwardList.isEmpty){
            webArray.updateOffset(forIndex: indexNum, OFFSET: 0)
        }
        webArray.updateUrl(forIndex: indexNum, URL: String(describing: webView.url!))
        navigationStatus = .comitted
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        reloadScripts()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webArray.updateTitle(forIndex: indexNum, TITLE: webView.title!)
        dismissTempImage()
        updatePreviewFoto()
        navigationStatus = .finished
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            self.progBar?.alpha = 1.0
            self.progBar?.setProgress(Float(self.webView.estimatedProgress), animated: true)
            
            if(webView.estimatedProgress >= 1.0) {
                UIView.animate(withDuration: 0.4, delay: 0.2, options: UIViewAnimationOptions.curveEaseInOut, animations: { () -> Void in
                    self.progBar?.alpha = 0.0
                }, completion: { (finished:Bool) -> Void in
                    self.progBar?.progress = 0
                })
            }
            if(webView.estimatedProgress >= 0.8) {
                self.dismissTempImage()
            }
        }
        else if keyPath == "title" {
            webArray.updateTitle(forIndex: indexNum, TITLE: webView.title!)
            webArray.updateUrl(forIndex: indexNum, URL: String(describing: webView.url!))
            if webView.title! != ""{saveToHistory()}
        }
        
    }

}

// helper methods

extension WebViewController{
    
    func loadUrl(Url:String) -> WebViewController{
        if let url = URL(string: Url) {webView.load(URLRequest(url: url))}
        return self
    }
    
    func updatePreviewFoto(){
        guard let lastImage = self.webView.screenshot() else {return}// return when open in background
        let fullPath = NSHomeDirectory().appending("/Documents/.Usr/Caches/")
        saveImage(currentImage: lastImage, persent: 0.1, imageName: "temp1.jpeg")
        if getSize(path: fullPath.appending("temp1.jpeg")) <= getSize(path: fullPath.appending("temp.jpeg")){
            try! FileManager.default.removeItem(at: URL(string: "file://" + fullPath.appending("temp1.jpeg"))!)
            return
        }
        try! FileManager.default.removeItem(at: URL(string: "file://" + fullPath.appending("temp1.jpeg"))!)
        asyncSaveImage(currentImage: lastImage, persent: 0.1, imageName: String(IMEI) + ".jpeg")
    }
    
    func getSize(path:String)->Int
    {
        if FileManager.default.fileExists(atPath: path){
            let fileinfo = try! FileManager.default.attributesOfItem(atPath: path)
            let size = fileinfo[FileAttributeKey.size] as! Int
            return size
        }else {
            return 0
        }
    }
    
    func transitionToSwitcher() -> SwitcherViewController{
        updatePreviewFoto()
        initTempImage()
        let swC = SwitcherViewController(toPage: webArray.activeViewIndex, WebArray: webArray,ROOT: root)
        root.transition(to: swC)
        return swC
    }
}

private extension WebViewController{
    
    func numberOfDocuments(atPath:String, filterTypes: [String])->String{
        let files = try! FileManager.default.contentsOfDirectory(atPath: atPath)
        if filterTypes.count == 0 {
            return String(describing:files.count)
        }
        else {
            let filteredfiles = NSArray(array: files).pathsMatchingExtensions(filterTypes)
            return String(describing:filteredfiles.count)
        }
        
    }
    
    func saveToHistory(){
        let fileManager = FileManager.default
        var historyList = [[String]]()
        let timeStamp = Date().timeIntervalSince1970
        let date = Date(timeIntervalSince1970: timeStamp)
        let dformatter = DateFormatter()
        dformatter.dateFormat = "MM-dd-yyyy"
        let fileName = dformatter.string(from: date)+".plist"
        
        if !fileManager.fileExists(atPath: historyPath){
            try! fileManager.createDirectory(atPath: historyPath,
                                             withIntermediateDirectories: true, attributes: nil)
        }
        
        if fileManager.fileExists(atPath: historyPath.appending(fileName)){
           if let covers = (NSArray(contentsOf: URL(string: "file://" + historyPath.appending(fileName))!) as? [[String]]){
            if covers[covers.count-1][0] == String(describing: webView.url!){
                return
            }
            historyList = covers
            historyList.append([String(describing: webView.url!), webView.title!,historyList[0][2],"0"])
            NSArray(array: historyList).write(toFile: historyPath.appending(fileName), atomically: true)
            return
            }
        }
        
        historyList.append([String(describing: webView.url!), webView.title!, numberOfDocuments(atPath: historyPath,filterTypes: ["plist"]),"0"])
        NSArray(array: historyList).write(toFile: historyPath.appending(fileName), atomically: true)
        
    }
    
    func saveImage(currentImage: UIImage, persent: CGFloat, imageName: String){
            if let imageData = UIImageJPEGRepresentation(currentImage, persent) as NSData? {
                let fullPath = NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending(imageName)
                imageData.write(toFile: fullPath, atomically: true)
                //print("fullPath=\(fullPath)")
            }
    }
    
    func asyncSaveImage(currentImage: UIImage, persent: CGFloat, imageName: String){
        DispatchQueue.global().async {
            if let imageData = UIImageJPEGRepresentation(currentImage, persent) as NSData? {
                let fullPath = NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending(imageName)
                imageData.write(toFile: fullPath, atomically: true)
                //print("fullPath=\(fullPath)")
            }
        }
        
    }
    
    func initTempImage(){
        if tempImageView != nil{
            tempImageView?.isHidden = false
            let fullPath = NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending(String(IMEI)).appending(".jpeg")
            if let savedImage = UIImage(contentsOfFile: fullPath) {
                tempImageView.image = savedImage
            } else {
                tempImageView.image = UIImage(named: "default")!
            }
            return
        }
        tempImageView = UIImageView()
        tempImageView.frame = CGRect(x: 0,y: 45+UIApplication.shared.statusBarFrame.height,width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height-85-UIApplication.shared.statusBarFrame.height)
     //view.layout(tempImageView).centerHorizontally().top(50).width(UIScreen.main.bounds.width).bottom(40)
        tempImageView.contentMode = .scaleAspectFill
        tempImageView.motionIdentifier = (String(IMEI))
        let fullPath = NSHomeDirectory().appending("/Documents/.Usr/Caches/").appending(String(IMEI)).appending(".jpeg")
        if let savedImage = UIImage(contentsOfFile: fullPath) {
            tempImageView.image = savedImage
        } else {
            tempImageView.image = UIImage(named: "default")!
        }
        self.view.addSubview(tempImageView)
    }
    
    func dismissTempImage(){
        tempImageView?.isHidden = true
    }
    
    func initUpperBar(){
        
        var statusBarOffsetAdjustment: CGFloat {
            return UIApplication.shared.statusBarFrame.height
        }
        upperToolBar = UIView()
        upperToolBar.backgroundColor = Color.grey.lighten5
        upperToolBar.depthPreset = .depth1
        
        urlFieldButton.backgroundColor = Color.grey.lighten3
        urlFieldButton.cornerRadiusPreset = .cornerRadius3
        urlFieldButton.setTitle(webView.title ?? "", for: .normal)
        //urlFieldButton.setImage(Icon.search, for: .normal)
        urlFieldButton.tintColor = Color.grey.darken4
        //urlFieldButton.titleLabel?.motionIdentifier = "urlField"
        urlFieldButton.addTarget(self, action: #selector(handleUrlField(button:)), for: .touchUpInside)
        
        refreshButton.tintColor = Color.grey.darken4
    view.layout(upperToolBar).centerHorizontally().top().width(UIScreen.main.bounds.width).height(45+statusBarOffsetAdjustment)
        upperToolBar.layout(urlFieldButton).top(statusBarOffsetAdjustment+5).bottom(10).horizontally(left: 10, right: 10)
        
        urlFieldButton.layout(refreshButton).right(5).centerVertically()
        upperToolBar.motionIdentifier = "upperToolBar"
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
        backButton.addTarget(self, action: #selector(handleBack(button:)), for: .touchUpInside)
        
        forwardButton = FlatButton(image: Icon.cm.skipForward, tintColor: .white)
        forwardButton.pulseColor = .white
        forwardButton.addTarget(self, action: #selector(handleForward(button:)), for: .touchUpInside)
        
        menuButton = FlatButton(image: Icon.cm.menu, tintColor: .white)
        menuButton.pulseColor = .white
        menuButton.addTarget(self, action: #selector(handleMenu(button:)), for: .touchUpInside)
        
        homeButton = FlatButton(image: Icon.cm.shuffle, tintColor: .white)
        homeButton.pulseColor = .white
        homeButton.addTarget(self, action: #selector(handleHome(button:)), for: .touchUpInside)
        
        toolButton = FlatButton(image: Icon.cm.check, tintColor: .white)
        toolButton.pulseColor = .white
        toolButton.addTarget(self, action: #selector(handleTool(button:)), for: .touchUpInside)
        
        switcherButton = FlatButton(image: Icon.cm.settings, tintColor: .white)
        switcherButton.pulseColor = .white
        switcherButton.addTarget(self, action: #selector(handleSwitcher(button:)), for: .touchUpInside)
        
        lowerToolBar = Toolbar()
        view.layout(lowerToolBar).centerHorizontally().bottom().width(screenWidth).height(40)
        lowerToolBar.centerViews = [backButton, forwardButton,menuButton,homeButton, toolButton, switcherButton]
        lowerToolBar.backgroundColor = Color.blue.darken2
        lowerToolBar.motionIdentifier = "LowerToolbar"
        
    }
    
    func initProgBar(){
        var statusBarOffsetAdjustment: CGFloat {
            return UIApplication.shared.statusBarFrame.height
        }
        progBar = UIProgressView(progressViewStyle:UIProgressViewStyle.bar)
        upperToolBar.layout(progBar).centerHorizontally().bottom().width(UIScreen.main.bounds.width)
        progBar.progressTintColor = Color.blue.darken2
        progBar.progress = 0
        //progBar.motionIdentifier = String(IMEI) + "1"
    }
    
    func initScrollTo(){
        if let offset = webArray.getOffset(forIndex: indexNum), offset != 0{
            scrollTo.addTarget(self, action: #selector(handleScrollTo), for: .touchUpInside)
            view.layout(scrollTo).right(10).bottom(50).width(40).height(40)
        }
    }
    
    func initWebview(){
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        var statusBarOffsetAdjustment: CGFloat {
            return UIApplication.shared.statusBarFrame.height
        }
        /////////////////////////////////////////////
        
        /*let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self*/
        self.webView.frame = CGRect(x: 0,y: 45+UIApplication.shared.statusBarFrame.height,width: screenWidth,height: screenHeight-85-statusBarOffsetAdjustment)
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        self.webView.scrollView.delegate = self
        //self.webView.motionIdentifier = "webView"//String(IMEI)
        self.view.addSubview(webView)
        let fullPath = NSHomeDirectory().appending("/Documents/.Usr/Caches/temp.jpeg")
        if getSize(path: fullPath) == 0{
            asyncSaveImage(currentImage: self.webView.screenshot()!, persent: 0.1, imageName: "temp.jpeg")
        }
        if urlToLoad == "homePage"{
            root.transition(to: HomePageNavigationController(rootViewController: HomePageController(currentPage: indexNum,path: "", url: nil, webarray: webArray, shouldDisplayKeyboard: false, shouldShowLowerTool:true, shouldShowBackForthButton:false)))
            return
        }
        if let url = URL(string: urlToLoad), webView.url == nil {webView.load(URLRequest(url: url))}
    }
    
    func initFullScreenUtilities(){
        quitFullScreenButton = UIButton()
        quitFullScreenButton.alpha = 1
        quitFullScreenButton.addTarget(self, action: #selector(handleQuitFullScreen(button:)), for: .touchUpInside)
        quitFullScreenButton.frame = CGRect(x: 0, y: view.bounds.height-10, width: view.frame.width, height: 10)
        quitFullScreenButton.isEnabled = false
        view.addSubview(quitFullScreenButton)
    }
    
    func activateFullScreenUtilities(){
        quitFullScreenButton.isEnabled = true
    }
    
    func deactivateFullScreenUtilities(){
        quitFullScreenButton.isEnabled = false
    }
    
    @objc func handleScrollTo(){
        if let offset = webArray.getOffset(forIndex: indexNum){
            var yOffset = offset
            if webView.scrollView.contentSize.height-webView.frame.height < offset{
                yOffset = webView.scrollView.contentSize.height-webView.frame.height
            }
            if yOffset < 0{yOffset = 0}
            webView.scrollView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)
        }
    }
    
    @objc
    func handleQuitFullScreen(button: UIButton) {
        offsetToolBarsIn()
    }

    @objc
    func handleUrlField(button: UIButton) {
        urlFieldButton.titleLabel?.transition(.position(x:urlFieldButton.frame.minX+urlFieldButton.titleLabel!.frame.width/2,y:urlFieldButton.frame.midY))
        if let url = webView.url{
            present(HomePageNavigationController(rootViewController: HomePageController(currentPage: indexNum,path: "", url: String(describing: url), webarray: webArray, shouldDisplayKeyboard: true, shouldShowLowerTool:false, shouldShowBackForthButton:true)), animated: true)
        }
        present(HomePageNavigationController(rootViewController: HomePageController(currentPage: indexNum,path: "", url: nil, webarray: webArray, shouldDisplayKeyboard: false, shouldShowLowerTool:false, shouldShowBackForthButton: true )), animated: true)
    }
    
    @objc
    func handleBack(button: UIButton) {
        webView.goBack()
    }
    
    @objc
    func handleForward(button: UIButton) {
        //webView.goForward()
        let flabutton = FlatButton(frame: .zero)
        flabutton.backgroundColor = Color.red.lighten3
        flabutton.addTarget(self, action: #selector(startSearch), for: .touchUpInside)
        let flabutton1 = FlatButton(frame: .zero)
        flabutton1.backgroundColor = Color.red.lighten3
        flabutton1.addTarget(self, action: #selector(toPrv), for: .touchUpInside)
        let flabutton2 = FlatButton(frame: .zero)
        flabutton2.backgroundColor = Color.red.lighten3
        flabutton2.addTarget(self, action: #selector(toNxt), for: .touchUpInside)
        let flabutton3 = FlatButton(frame: .zero)
        flabutton3.backgroundColor = Color.red.lighten3
        let flabutton4 = FlatButton(frame: .zero)
        flabutton4.backgroundColor = Color.red.lighten3
        root.present(HomeMenuViewController(buttons:[flabutton,flabutton1,flabutton2,flabutton3]), animated: false)
    }
    
    @objc
    func handleMenu(button: UIButton) {
        if let ur = webView.url{
            if let tit = webView.title, tit != ""{
                root.present(NavigationController(rootViewController: AddToBookmarkViewController(tit1e:tit, url:String(describing: ur))), animated: true)
            }
            else{
                root.present(NavigationController(rootViewController: AddToBookmarkViewController(tit1e:"Untitled", url:String(describing: ur))), animated: true)
            }
        }
    }
    
    @objc
    func handleHome(button: UIButton) {
        root.transition(to: AppNavigationController(rootViewController:FavTableViewController(
            Root:root, WebArray:webArray, webVC:indexNum, path:"", password:nil, folderName:nil)))
        /*"hangge.com123456"
        let a = FavDataStructure(path: "",passw0rd: "hangge.com123456")
        a.saveBookmark(title: "helloMoto", url: "www.shabi.com")
        a.deleteBookmark(index: 0)
        print(a.readBookmarkList())
        print(a.getBookmarkURL(index: 0))
        print(a.getFullList())*/
    }
    
    @objc
    func handleSwitcher(button: UIButton) {
        _ = transitionToSwitcher()
    }
    
    @objc
    func handleTool(button: UIButton) {
        root.transition(to: AppNavigationController(rootViewController:HistoryViewController(Root: root, WebArray: webArray, webVC:indexNum)))
    }
    
}

extension WKWebView {
    func screenshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImage
    }
}

extension UIView {
    func screenShot() -> UIImage? {
        guard frame.size.height > 0 && frame.size.width > 0 else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension WebViewController: UIScrollViewDelegate{
    func offsetToolBarsOut(length:CGFloat){
        var frameChange = 0
        
        var statusBarOffsetAdjustment: CGFloat {
            return UIApplication.shared.statusBarFrame.height
        }
        
        if upperToolBar.frame.maxY > statusBarOffsetAdjustment{
            frameChange += 1
            var changedY = 0-length
            if changedY < statusBarOffsetAdjustment-upperToolBar.frame.height{
                changedY = statusBarOffsetAdjustment-upperToolBar.frame.height
            }
            //UIView.animate(withDuration: 0.01, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.upperToolBar.frame = CGRect(x:0,y:changedY, width: Screen.width, height: self.upperToolBar.frame.height)
                self.upperToolBar.alpha = 1 - (length / self.upperToolBar.frame.height)
            //})
        }
        
        if lowerToolBar.frame.minY < view.bounds.height{
            frameChange += 1
            var changedY = view.bounds.height-40+length
            if changedY > view.bounds.height{
                changedY = view.bounds.height
            }
            //UIView.animate(withDuration: 0.01, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.lowerToolBar.frame = CGRect(x:0,y:changedY, width: self.lowerToolBar.frame.width, height: self.lowerToolBar.frame.height)
            //})
        }
        if frameChange > 0{
            //UIView.animate(withDuration: 0.01, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.webView.frame = CGRect(x:0,y:self.upperToolBar.frame.maxY, width: self.webView.frame.width, height: self.lowerToolBar.frame.minY-self.upperToolBar.frame.maxY)
            self.webView.scrollView.contentOffset = CGPoint(x:webView.scrollView.contentOffset.x,y: scrollInitY)
            
            //})
        }
        else{
            scrollStatus = .finished
        }
    }
    
    func offsetToolBarsOut(){
        var statusBarOffsetAdjustment: CGFloat {
            return UIApplication.shared.statusBarFrame.height
        }
        UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
            self.upperToolBar.alpha = 0
            self.upperToolBar.frame = CGRect(x:0,y:statusBarOffsetAdjustment-self.upperToolBar.frame.height, width: self.upperToolBar.frame.width, height: self.upperToolBar.frame.height)
            
            self.lowerToolBar.frame = CGRect(x:0,y:self.view.bounds.height, width: self.lowerToolBar.frame.width, height: self.lowerToolBar.frame.height)
            
            self.webView.frame = CGRect(x:0,y:self.upperToolBar.frame.maxY, width: self.upperToolBar.frame.width, height: self.lowerToolBar.frame.minY-self.upperToolBar.frame.maxY)
        })
        scrollStatus = .finished
    }
    
    func offsetToolBarsIn(){
        upperToolBar.alpha = 1
       
        UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
            self.upperToolBar.frame = CGRect(x:0,y:0, width: self.upperToolBar.frame.width, height: self.upperToolBar.frame.height)
            
            self.lowerToolBar.frame = CGRect(x:0,y:self.view.bounds.height-40, width: self.lowerToolBar.frame.width, height: self.lowerToolBar.frame.height)
            
            self.webView.frame = CGRect(x:0,y:self.upperToolBar.frame.maxY, width: self.upperToolBar.frame.width, height: self.lowerToolBar.frame.minY-self.upperToolBar.frame.maxY)
        })
        if webView.scrollView.contentOffset.y >= webView.scrollView.contentSize.height - 600{
            webView.scrollView.contentOffset.y = webView.scrollView.contentSize.height
        }
        scrollStatus = .intact
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard tempImageView.isHidden == true else{return}
        scrollTo.animate([.fadeOut]){[weak self] in
            self?.scrollTo.isHidden = true
        }
        if scrollStatus == .comitted{
            let offset = scrollView.contentOffset.y - scrollInitY
            if cumulativeChange + offset > 0{
                cumulativeChange += offset
                offsetToolBarsOut(length: cumulativeChange)
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard tempImageView.isHidden == true else{return}
        if scrollStatus == .intact{
            scrollStatus = .comitted
            cumulativeChange = 0
            scrollInitY = webView.scrollView.contentOffset.y
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard tempImageView.isHidden == true else{return}
        var statusBarOffsetAdjustment: CGFloat {
            return UIApplication.shared.statusBarFrame.height
        }
        
        if velocity.y <= -0.33 && scrollStatus == .finished{
            offsetToolBarsIn()
        }
        if scrollStatus == .comitted{
            if upperToolBar.frame.maxY < statusBarOffsetAdjustment + upperToolBar.frame.height/2{
                offsetToolBarsOut()
            }
            else{
                offsetToolBarsIn()
            }
        }
        if velocity.y == 0 && velocity.x == 0{
            updatePreviewFoto()
            webArray.updateOffset(forIndex: indexNum, OFFSET: scrollView.contentOffset.y)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard tempImageView.isHidden == true else{return}
        if scrollView.contentOffset.y >= 0 && scrollView.contentOffset.y <= scrollView.contentSize.height-webView.frame.height{
            updatePreviewFoto()
            webArray.updateOffset(forIndex: indexNum, OFFSET: scrollView.contentOffset.y)
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if scrollStatus == .finished{
            offsetToolBarsIn()
            return false
        }
        else{
            return true
        }
    }
}

extension WebViewController{
    func animateRefreshButtonIcon(icon:UIImage?){
        refreshButton.animate(.fadeOut,
                              .completion({self.refreshButton.image = icon}),
                              .duration(0.15))
        Motion.delay(0.2) { [weak self] in
            self?.refreshButton.animate(.fadeIn)
        }
    }
    
    func animateUrlFieldButtonIcon(icon:UIImage?){
        urlFieldButton.imageView?.animate(.fadeOut,
                              .completion({self.urlFieldButton.setImage(icon, for: .normal)}),
                              .duration(0.15))
        Motion.delay(0.2) { [weak self] in
            self?.urlFieldButton.imageView?.animate(.fadeIn)
        }
    }
}

extension WebViewController{
    func reloadScripts() {
        webView.configuration.userContentController.removeAllUserScripts()
        injectDocumentJS()
        injectSearchJS()
    }
    func injectDocumentJS(){
        let bundle = Bundle(for: WebViewController.self)
        let js:String
        if let path = bundle.path(forResource: "document", ofType: "js"){try! js = String(contentsOfFile: path)}
        else{return}
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        self.webView.configuration.userContentController.addUserScript(script)
    }
    func injectSearchJS(){
        let bundle = Bundle(for: WebViewController.self)
        let js:String
        if let path = bundle.path(forResource: "search", ofType: "js"){try! js = String(contentsOfFile: path)}
        else{return}
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        self.webView.configuration.userContentController.addUserScript(script)
    }
}

extension WKWebView {
    public func getUrlAtPoint(x: CGFloat, y: CGFloat, completion: @escaping ([String:String]?) -> Void) {
        let javascript = "duckduckgoDocument.myAppGetHTMLElementsAtPoint(\(Int(x)), \(Int(y)))"
        evaluateJavaScript(javascript) { (result, error) in
            print("jsEvaed!")
            print(result)
            if let text = result as? String {
                var resDic = [String:String]()
                let splitedArray = text.components(separatedBy: "·")
                for i in splitedArray{
                    if i.hasPrefix("IMG|"){
                        resDic["IMG"] = i.replacingOccurrences(of: "IMG|", with: "")
                    }
                    if i.hasPrefix("A|"){
                        resDic["URL"] = i.replacingOccurrences(of: "A|", with: "")
                    }
                    if i.hasPrefix("IMGName|"){
                        resDic["IMGName"] = i.replacingOccurrences(of: "IMGName|", with: "")
                    }
                    if i.hasPrefix("AName|"){
                        resDic["URLName"] = i.replacingOccurrences(of: "AName|", with: "").replacingOccurrences(of: "\n", with: "")
                    }
                }
                completion(resDic)
            } else {
                completion(nil)
            }
        }
    }
    
    public func search(_ text:String){
        let javascript = "GetAllOccurencesOfText('\(text)')"
        evaluateJavaScript(javascript) { (result, error) in
            print(result)
        }
    }
    
    public func search_prv(completion: @escaping ([String]?) -> Void){
        let javascript = "PrvForMe()"
        evaluateJavaScript(javascript) { (result, error) in
            print(result)
            if let resStr = result as? String{
                let resArr = resStr.components(separatedBy: ",")
                print(resArr)
                if resArr.count == 4{
                    print(resArr)
                    completion(resArr)
                }
                else{
                    print("nil")
                    completion(nil)
                }
            }
        }
    }
    public func search_nxt(completion: @escaping ([String]?) -> Void){
        let javascript = "NxtForMe()"
        evaluateJavaScript(javascript) { (result, error) in
            if let resStr = result as? String{
                let resArr = resStr.components(separatedBy: ",")
                print(resArr)
                if resArr.count == 4{
                    
                    completion(resArr)
                }
                else{
                    print("nil")
                    completion(nil)
                }
            }
        }
    }
}

extension Sequence {
    func compactMap<T>(_ transform: (Self.Element) throws -> T?) rethrows -> [T] {
        return try flatMap(transform)
    }
}

extension WebViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerWithDescriptionFragment(_ descriptionFragment: String) -> UIGestureRecognizer? {
        return webView.scrollView.subviews.compactMap({ $0.gestureRecognizers }).joined().first(where: { $0.description.contains(descriptionFragment) })
    }
    
    private func attachLongPressHandler(webView: WKWebView) {
        //let nativeHighlightLongPressRecognizer = gestureRecognizerWithDescriptionFragment("action=_highlightLongPressRecognized:") as? UILongPressGestureRecognizer
        
        if let nativeLongPressRecognizer = gestureRecognizerWithDescriptionFragment("action=_longPressRecognized:") as? UILongPressGestureRecognizer {
            nativeLongPressRecognizer.removeTarget(nil, action: nil)
            nativeLongPressRecognizer.addTarget(self, action: #selector(onLongPress))
        }
    }
    
    @objc func onLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        if let nativeHighlightLongPressRecognizer = gestureRecognizerWithDescriptionFragment("action=_highlightLongPressRecognized:") as? UILongPressGestureRecognizer, nativeHighlightLongPressRecognizer.isEnabled{
            nativeHighlightLongPressRecognizer.isEnabled = false
            nativeHighlightLongPressRecognizer.isEnabled = true
        }
        
        let x = sender.location(in: webView).x
        let y = sender.location(in: webView).y
        webView.getUrlAtPoint(x: x, y: y)  { [weak self] (result) in
            guard let result = result else { return }
            let point = CGPoint(x: x, y: y)
            self?.launchContextualMenu(forContent: result, atPoint: point)
        }
    }
    
    func launchContextualMenu(forContent result: [String:String], atPoint point: CGPoint) {
        let alert = UIAlertController(title: nil, message: "", preferredStyle: .actionSheet)
        if let url = result["URL"]{
            var url1 = url
            if url.count > 40{
                url1 = url1[..<url1.index(url1.startIndex, offsetBy: 18)] + "..." + url1[url1.index(url1.endIndex, offsetBy: -18)...]
            }
            alert.message = url1
            alert.addAction(newTabAction(forUrl: url))
            alert.addAction(backgroundTabAction(forUrl: url, atPoint: point))
            alert.addAction(copyAction(forUrl: url))
        }
        if let img = result["IMG"]{
            
        }
        //alert.addAction(shareAction(forUrl: url, atPoint: point))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    private func copyAction(forUrl url: String) -> UIAlertAction {
        return UIAlertAction(title: "Copy Url", style: .default) { (action) in
            UIPasteboard.general.string = url
        }
    }
    
    private func newTabAction(forUrl url: String) -> UIAlertAction {
        return UIAlertAction(title: "Open in new tab", style: .default) { [weak self] action in
            if let strongSelf = self {
                let swC = strongSelf.transitionToSwitcher()
                Motion.delay(0.35){swC.addTab(url: url)}
            }
        }
    }
    
    private func backgroundTabAction(forUrl url: String, atPoint point: CGPoint) -> UIAlertAction {
        return UIAlertAction(title: "Open in background", style: .default) { [weak self] action in
            if let strongSelf = self {
                strongSelf.animateOpenInBackground(atPoint: point)
                let newTab = WebViewController(URL: url, NO: strongSelf.webArray.activeViewIndex + 1, IMEI: 0, WebArray: strongSelf.webArray,ROOT: strongSelf.root)
                _ = newTab.loadUrl(Url: url)
                strongSelf.webArray.insert(tab: newTab, to: strongSelf.webArray.activeViewIndex + 1, withURL: url)
            }
        }
    }
    
    func animateOpenInBackground(atPoint point: CGPoint){
        let newTabView = UIView()
        var centerPoint = point
        let viewIniSize = CGSize(width: 0, height: 0)
        centerPoint.y += viewIniSize.height*2
        newTabView.backgroundColor = Color.grey.lighten2
        newTabView.frame = CGRect(center: centerPoint, size: viewIniSize)
        view.addSubview(newTabView)
        newTabView.animate(.fadeOut,
                           .position(x: Screen.width/2, y: Screen.height),
                           .size(CGSize(width: Screen.width-40, height: 100)),
                           .completion {
                            newTabView.removeFromSuperview()
            })
    }
    
    @objc func startSearch(){
        webView.search("林子")
    }
    @objc func toPrv(){
        webView.search_prv(){ [weak self] (result) in
            guard let resArr = result else {return}
            let currentIndex = resArr[2]
            let totalIndex = resArr[3]
            let atPointY = resArr[0]
            let atPointX = resArr[1]
            if atPointY != "0", let yPos = Float(atPointY),let xPos = Float(atPointX){
                let cgp = CGPoint(x:CGFloat(xPos), y:CGFloat(yPos))
                self?.webView.scrollView.setContentOffset(cgp, animated: true)
            }
        }
    }
    @objc func toNxt(){
        webView.search_nxt(){ [weak self] (result) in
            guard let resArr = result else {return}
            let currentIndex = resArr[2]
            let totalIndex = resArr[3]
            let atPointY = resArr[0]
            let atPointX = resArr[1]
            if atPointY != "0", let yPos = Float(atPointY),let xPos = Float(atPointX){
                let cgp = CGPoint(x:CGFloat(xPos), y:CGFloat(yPos))
                self?.webView.scrollView.setContentOffset(cgp, animated: true)
            }
        }
    }
}

