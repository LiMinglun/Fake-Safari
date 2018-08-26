//
//  AddToBookmarkViewController.swift
//  Project0v1
//
//  Created by Michael on 3/23/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material

class AddToBookmarkViewController: UIViewController {
    fileprivate var titleField: ErrorTextField!
    fileprivate var urlField: TextField!
    fileprivate var locationLabel: UILabel!
    fileprivate var locationButton: Button!
    fileprivate var homeButton: FABButton!
    fileprivate var confirmButton: FABButton!
    fileprivate var keyboardHeight:CGFloat = 0
    private var tag = true
    private var tag2 = true
    private var webTitle = ""
    private var webUrl = ""
    fileprivate var pref = [String:String]()
    let homeButtonSize2 = CGSize(width: 46, height: 46)
    let bottomInset: CGFloat = 24
    let bottomInset3: CGFloat = 84
    let rightInset: CGFloat = 24
    var orig1:CGPoint = CGPoint()
    var orig2:CGPoint = CGPoint()
    
    /// A constant to layout the textFields.
    fileprivate let constant: CGFloat = 40
    
    init(tit1e:String, url:String){
        super.init(nibName: nil, bundle: nil)
        webTitle = tit1e
        webUrl = url
        pref = (statusBarController as! BigBrother).readPreference()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.titleLabel.text = "Add Bookmark"
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillShow(notif:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        refreshLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.grey.lighten5
        
        prepareTitleField()
        prepareUrlField()
        prepareLocation()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if tag{
            orig1 = CGPoint(x: view.bounds.width - rightInset - homeButtonSize2.width, y: view.bounds.height - bottomInset - homeButtonSize2.height)
            orig2 = CGPoint(x: view.bounds.width - rightInset - homeButtonSize2.height, y: view.bounds.height - bottomInset3 - homeButtonSize2.height)
            prepareButton()
            tag = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = titleField.becomeFirstResponder()
        if tag2{
            titleField.selectAll(nil)
            tag2 = false
        }
    }
    
    @objc func keyboardWillShow(notif:NSNotification){
        let dic:NSDictionary = notif.userInfo! as NSDictionary
        let a:AnyObject? = dic.object(forKey: UIKeyboardFrameEndUserInfoKey) as AnyObject
        keyboardHeight = a?.cgRectValue.size.height ?? 0
        print(view.bounds)
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.homeButton.frame = CGRect(x:self.orig1.x-self.homeButtonSize2.width*1.5+self.rightInset,y:self.view.bounds.height-self.keyboardHeight-self.confirmButton.frame.height, width: self.homeButton.frame.width, height: self.homeButton.frame.height)
            self.confirmButton.frame = CGRect(x:self.orig2.x+self.rightInset,y:self.view.bounds.height-self.confirmButton.frame.height-self.keyboardHeight, width: self.confirmButton.frame.width, height: self.confirmButton.frame.height)
            
        })
        
    }
}

extension AddToBookmarkViewController {
    fileprivate func prepareTitleField() {
        titleField = ErrorTextField()
        titleField.placeholder = "Title"
        titleField.text = webTitle
        
        titleField.detail = "Bookmark Title Should Not Be Empty"
        titleField.isClearIconButtonEnabled = true
        titleField.delegate = self
        titleField.isPlaceholderUppercasedWhenEditing = true
        titleField.placeholderAnimation = .hidden
        
        view.layout(titleField).top(constant).left(20).right(20)
    }
    
    fileprivate func prepareUrlField() {
        urlField = TextField()
        urlField.text = webUrl
        urlField.isUserInteractionEnabled = false
        view.layout(urlField).top(constant+30+titleField.bounds.height).left(20).right(20)
    }
    
    func refreshLocation(){
        pref = (statusBarController as! BigBrother).readPreference()
        if let folderName = pref["addBMFolderName"], let folderPath = pref["addBMFolderPath"]{
            if folderPath == ""{
                locationButton.image = Icon.starBorder
            }
            else{
                locationButton.image = Icon.work
            }
            locationButton.title = "  " + folderName
        }
        else{
            locationButton.image = Icon.starBorder
            locationButton.title = "  Bookmarks"
        }
    }
    
    fileprivate func prepareLocation() {
        locationLabel = UILabel()
        locationLabel.text = "LOCATION"
        locationLabel.font = UIFont.systemFont(ofSize: 15)
        locationLabel.textColor = Color.grey.base
        view.layout(locationLabel).top(constant+90+titleField.bounds.height+urlField.bounds.height).left(20)
        if let folderName = pref["addBMFolderName"], let folderPath = pref["addBMFolderPath"]{
            if folderPath == ""{
                locationButton = Button(image: Icon.starBorder)
            }
            else{
                locationButton = Button(image: Icon.work)
            }
            locationButton.title = "  " + folderName
        }
        else{
            locationButton = Button(image: Icon.starBorder)
            locationButton.title = "  Bookmarks"
        }
        locationButton.titleColor = Color.grey.base
        locationButton.contentHorizontalAlignment = .left
        locationButton.addTarget(self, action: #selector(handleLocationButton), for: .touchUpInside)
        
        view.layout(locationButton).top(constant+100+titleField.bounds.height+urlField.bounds.height+locationLabel.bounds.height).left(20).right(20)
    }
    
    fileprivate func prepareButton(){
        
        homeButton = FABButton(image: Icon.home, tintColor: .white)
        homeButton.pulseColor = .white
        homeButton.backgroundColor = Color.orange.base
        homeButton.addTarget(self, action: #selector(handleHomeButton), for: .touchUpInside)
        confirmButton = FABButton(image: Icon.check, tintColor: .white)
        confirmButton.pulseColor = .white
        confirmButton.backgroundColor = Color.blue.base
        confirmButton.addTarget(self, action: #selector(handleConfirmButton), for: .touchUpInside)
        homeButton.frame = CGRect(origin: orig1, size: homeButtonSize2)
        view.addSubview(homeButton)
        
        confirmButton.frame = CGRect(origin: orig2, size: homeButtonSize2)
        view.addSubview(confirmButton)
    }
}


extension AddToBookmarkViewController: TextFieldDelegate {
    
    @objc func handleLocationButton(){
        if let folderPath = pref["addBMFolderPath"]{
            navigationController?.pushViewController(folderTableView(folderPath), animated: true)
        }
        else{
            navigationController?.pushViewController(folderTableView(""), animated: true)
        }
    }
    
    @objc func handleHomeButton(){
        dismiss()
    }
    
    @objc func handleConfirmButton(){
        if (titleField.text?.isEmpty)!{
            titleField.isErrorRevealed = true
        }
        else{
            let pref = (statusBarController as! BigBrother).readPreference()
            let saveData:FavDataStructure
            if let folderPath = pref["addBMFolderPath"]{
                saveData = FavDataStructure(path: folderPath, passw0rd: nil)
            }
            else{
                saveData = FavDataStructure(path: "", passw0rd: nil)
            }
            saveData.saveBookmark(title: titleField.text!, url: urlField.text!)
            dismiss()
        }
    }
    
    func dismiss(){
        titleField?.resignFirstResponder()
        urlField?.resignFirstResponder()
        self.navigationController?.dismiss(animated: true)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        (textField as? ErrorTextField)?.isErrorRevealed = false
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.homeButton.frame = CGRect(x:self.orig1.x,y:self.orig1.y, width: self.homeButton.frame.width, height: self.homeButton.frame.height)
            self.confirmButton.frame = CGRect(x:self.orig2.x,y:self.orig2.y, width: self.confirmButton.frame.width, height: self.confirmButton.frame.height)
        })
    }
    
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        (textField as? ErrorTextField)?.isErrorRevealed = false
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if ((textField as? ErrorTextField)?.text?.isEmpty)!{
            (textField as? ErrorTextField)?.isErrorRevealed = true
        }
        else{
            titleField?.resignFirstResponder()
        }
        return true
    }
}

class folderTableView:UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    private var data:[[String]]
    private var tableView:TableView!
    private let selectedP:String
    
    init(_ selectedPath:String){
        selectedP = selectedPath
        let dataStruct = FavDataStructure(path:"", passw0rd:nil)
        data = dataStruct.getFullFolderList(Path: "", Depth: 0) ?? [[String]]()
        data.insert(["Favourites","","0"], at: 0)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.grey.lighten5
        
        tableView = TableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.register(FDUITableViewCell.self,
                           forCellReuseIdentifier: "HistoryTableViewCell")
        view.layout(tableView!).edges()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath) as! FDUITableViewCell
        cell.backgroundColor = UIColor.clear
        cell.dividerColor = Color.grey.lighten2
        cell.indentationLevel = Int(data[indexPath.row][2])!
        cell.textLabel?.text = data[indexPath.row][0]
        if data[indexPath.row][1] == selectedP{
            cell.imageView2.image = Icon.check
        }
        if indexPath.row == 0{
            cell.imageView?.image = Icon.starBorder
        }
        else{
            cell.imageView?.image = Icon.work
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        var mutaPref = (statusBarController as! BigBrother).readPreference()
        mutaPref["addBMFolderPath"] = data[indexPath.row][1]
        mutaPref["addBMFolderName"] = data[indexPath.row][0]
        (statusBarController as! BigBrother).writePreference(file: mutaPref)
        self.navigationController?.popViewController(animated: true)
    }
}

class FDUITableViewCell: UITableViewCell
{
    let imageView2 = UIImageView()
    var imageViewXOrigin:CGFloat = 0
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //imageView2.image = Icon.check
        self.contentView.layout(imageView2).centerVertically().right(10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        // Call super
        super.layoutSubviews();
        if(imageViewXOrigin == 0){
            imageViewXOrigin = self.imageView!.frame.origin.x}
        // Update the frame of the image view
        self.imageView!.frame = CGRect(x: self.imageViewXOrigin + (CGFloat(self.indentationLevel) * self.indentationWidth),y: self.imageView!.frame.origin.y,width: self.imageView!.frame.size.width, height: self.imageView!.frame.size.height);
    }
}
