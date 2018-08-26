//
//  MenuViewController.swift
//  Project0v1
//
//  Created by Michael on 3/21/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import Material
import Motion

class MenuViewController:UIViewController{
    
    let backgroundButton = UIButton()
    let buttonList:[FlatButton]
    private var buttonCount = 0
    private var menuHeight:CGFloat = 2
    private let menuView = UIView()
    private var viewPan:UIPanGestureRecognizer?
    private var buttonHeight:CGFloat = 0
    
    init(buttons:[FlatButton]){
        buttonList = buttons
        buttonCount = buttons.count
        for i in buttonList{
            menuHeight += i.frame.height
            buttonHeight = i.frame.height
        }
        super.init(nibName: nil, bundle: nil)
        if buttons.count<=0{
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
        initGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backgroundButton.animate(.background(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)),
                                 .duration(0.15))
        //menuView.frame = CGRect(x:0,y:view.frame.height-menuHeight, width: Screen.width, height: menuHeight)
        //menuView.animate(.position(x:Screen.width/2, y:view.bounds.height-menuHeight/2))
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
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
        menuView.backgroundColor = Color.grey.lighten5
        menuView.frame = CGRect(x:0,y:view.frame.height+menuHeight, width: Screen.width, height: menuHeight)
        view.addSubview(menuView)
        var topInset:CGFloat = 1
        for button in buttonList{
            menuView.layout(button).horizontally().top(topInset).height(buttonHeight)
            topInset+=buttonHeight
        }
        
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
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.menuView.frame = CGRect(x:0,y:self.view.frame.height+self.menuHeight, width: Screen.width, height: self.menuHeight)}, completion: {(boo:Bool) in self.dismiss(animated: false)} )
    }
}

extension MenuViewController:UIGestureRecognizerDelegate{
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
            gestureRecognizer.location(in: menuView).y < 0
        {
            return false
        }
        return true
    }
}

