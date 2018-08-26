//
//  HomeMenuViewController.swift
//  Project0v1
//
//  Created by Michael on 4/18/18.
//  Copyright © 2018 apple. All rights reserved.
//


import UIKit
import Material
import Motion

class HomeMenuViewController:UIViewController{
    
    let backgroundButton = UIButton()
    let buttonList:[FlatButton]
    private var buttonCount = 0
    private var buttonRowCount:Int = 0
    private var menuHeight:CGFloat = 0
    private let lowerToolBarHeight:CGFloat = 40
    private var buttonSize:CGSize = CGSize(width: 100, height: 150)
    private var cellInset:CGFloat = 20
    private let menuView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.extraLight))
    private var viewPan:UIPanGestureRecognizer?
    
    init(buttons:[FlatButton]){
        buttonList = buttons
        buttonCount = buttons.count
        buttonRowCount = Int(Float(buttons.count) / 4 + Float(0.75))
        buttonSize = CGSize(width: (Screen.width-5*cellInset)/4, height: (Screen.width-5*cellInset)/4*1.5)
        menuHeight = 2*cellInset
        menuHeight += lowerToolBarHeight
        menuHeight += CGFloat(buttonRowCount) * buttonSize.height
        super.init(nibName: nil, bundle: nil)
        if buttonCount<=0{
            self.dismiss(animated: true)
        }
        self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.isMotionEnabled = false
        //self.backgroundButton.transition(.fadeOut)
        //self.menuView.transition(.position(CGPoint(x:Screen.width/2,y:view.frame.height+menuHeight)))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initBackground()
        initMenuView()
        initLowertoolBar()
        initGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backgroundButton.animate(.background(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)),
                                 .duration(0.15))
        //menuView.frame = CGRect(x:0,y:view.frame.height-menuHeight, width: Screen.width, height: menuHeight)
        //menuView.animate(.position(x:Screen.width/2, y:view.bounds.height-menuHeight/2))
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.menuView.alpha = 1
            self.menuView.frame = CGRect(x:0,y:self.view.frame.height-self.menuHeight, width: Screen.width, height: self.menuHeight)})
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initBackground(){
        self.view.backgroundColor = UIColor.clear
        backgroundButton.frame = view.frame
        backgroundButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.0)
        view.addSubview(backgroundButton)
        backgroundButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
    }
    
    private func initMenuView(){
        //menuView.backgroundColor = Color.grey.lighten5
        menuView.frame = CGRect(x:0,y:view.frame.height+menuHeight, width: Screen.width, height: menuHeight)
        view.addSubview(menuView)
        menuView.alpha = 0
        var currentIndex:[String:CGFloat] = ["row":1,"column":1]{
            didSet{
                if currentIndex["column"]! > 4{
                    currentIndex["row"]! += 1
                    currentIndex["column"] = 1
                }
            }
        }
        for button in buttonList{
            
            menuView.contentView.layout(button)
                .left((currentIndex["column"]!-1)*buttonSize.width+currentIndex["column"]!*cellInset)
                .top((currentIndex["row"]!-1)*buttonSize.height+currentIndex["row"]!*cellInset)
                .height(buttonSize.height).width(buttonSize.width)

            currentIndex["column"]! += 1
        }
        
    }
    
    let lowerView = UIView()
    private func initLowertoolBar(){
        
        let bacButton = FlatButton(image: Icon.arrowDownward)
        bacButton.tintColor = Color.red.base
        bacButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        lowerView.alpha = 0
        lowerView.backgroundColor = Color.blue.darken1
        view.layout(lowerView).bottom().horizontally().height(lowerToolBarHeight)
        lowerView.layout(bacButton).center().height(lowerToolBarHeight).width(lowerToolBarHeight)
        lowerView.animate(.fade(1))
    }
    
    private func initGesture(){
        viewPan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        viewPan?.delegate = self
        self.view.addGestureRecognizer(viewPan!)
    }
    
    @objc func handlePan (sender:UIPanGestureRecognizer) {
        let origYPosition = view.frame.height-menuHeight
        if sender.state == UIGestureRecognizerState.began{
            
        }
        else if sender.state == UIGestureRecognizerState.changed{
            let translation = sender.translation(in: self.view)
            if menuView.frame.minY + translation.y >= origYPosition{
                menuView.center.y += translation.y
                print(menuView.center.y)
            }
            sender.setTranslation(CGPoint.zero, in: menuView)
        }
        else if sender.state == UIGestureRecognizerState.ended || sender.state == UIGestureRecognizerState.cancelled{
            if menuView.frame.minY > origYPosition{
                goBack()
            }
        }
        
    }
    
    @objc public func goBack(){
        
        backgroundButton.animate(.background(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0)),
                                 .duration(0.15))
        lowerView.animate(.fadeOut)
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.menuView.alpha = 0
            self.menuView.frame = CGRect(x:0,y:self.view.frame.height+self.menuHeight, width: Screen.width, height: self.menuHeight)}, completion: {(boo:Bool) in self.dismiss(animated: false)} )
    }
}

extension HomeMenuViewController:UIGestureRecognizerDelegate{
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
            gestureRecognizer.location(in: menuView).y < 0
        {
            return false
        }
        return true
    }
}


