//
//  BaseViewController.swift
//  Pods
//
//  Created by MacMini-2 on 30/08/17.
//
//

#if os(macOS)
    import Cocoa
#else
    import UIKit
#endif

public extension UIViewController {
    
    public struct AssociatedKeys {
        static var viewWillAppearOnceKey = "once_viewWillAppear"
        static var viewDidAppearOnceKey = "once_viewDidAppear"
    }
    
    public func getBookValue(key: UnsafeRawPointer) -> Bool {
        return (objc_getAssociatedObject(self, key) as? Bool) ?? false
    }
    
    public func setBoolValue(key: UnsafeRawPointer, value: AnyObject?) {
        if getBookValue(key: key) { return }
        objc_setAssociatedObject(self, key, value, .OBJC_ASSOCIATION_RETAIN)
    }
    
    public var alreadyCalledViewWillAppearOnce: Bool {
        get {
            return getBookValue(key: &AssociatedKeys.viewWillAppearOnceKey)
        }
        set {
            setBoolValue(key: &AssociatedKeys.viewWillAppearOnceKey, value: newValue as AnyObject?)
        }
    }
    
    public var alreadyCalledViewDidAppearOnce: Bool {
        get {
            return getBookValue(key: &AssociatedKeys.viewDidAppearOnceKey)
        }
        set {
            setBoolValue(key:&AssociatedKeys.viewDidAppearOnceKey, value: newValue as AnyObject?)
        }
    }
    
    public func callOnce( flag: inout Bool, closure: () -> Void) {
        if !flag {
            closure()
            flag = true
        }
    }
    
    public func viewWillAppearOnce(fromFunction: String = #function, closure: () -> Void) {
        guard fromFunction == "viewWillAppear" else {
            return
        }
        callOnce(flag: &alreadyCalledViewWillAppearOnce, closure: closure)
    }
    
    public func viewDidAppearOnce(fromFunction: String = #function, closure: () -> Void) {
        guard fromFunction == "viewDidAppear" else {
            return
        }
        callOnce(flag: &alreadyCalledViewDidAppearOnce, closure: closure)
    }

}


@IBDesignable
open class BaseViewController: UIViewController , UINavigationControllerDelegate {
    
    open var baseLayout : AppBaseLayout!
    open var aView : BaseView!
    
    open var btnName: UIButton!
    open var navigationTitleString : String!
    
    @IBInspectable open var TitleNavigation : String {
        get {
            return self.navigationItem.title!
        }
        set {
            self.navigationItem.title = newValue
            navigationTitleString = newValue
        }
    }
    
    @IBInspectable open var displayMenu: Bool
        {
        get {
            return self.displayMenu
        }
        set {
            self.displayMenuButton(image: nil)
        }
    }

    
    // MARK: - Lifecycle -
    override open func awakeFromNib() {
        
    }
    
    required public init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init(iView: BaseView){
        super.init(nibName: nil, bundle: nil)
        aView = iView
    }
    
    required public init(iView: BaseView, andNavigationTitle titleString: String){
        
        super.init(nibName: nil, bundle: nil)
        aView = iView
        
        navigationTitleString = titleString
        AppUtility.executeTaskInMainQueueWithCompletion { [weak self] in
            if self == nil{
                return
            }
            self!.navigationItem.title = self!.navigationTitleString
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.loadViewControls()
        self.setViewlayout()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AppUtility.executeTaskInMainQueueWithCompletion { [weak self] in
            if self == nil{
                return
            }
            self!.navigationItem.title = self!.navigationTitleString
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppUtility.executeTaskInMainQueueWithCompletion { [weak self] in
            if self == nil{
                return
            }
            self!.navigationItem.title = self!.navigationTitleString
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppUtility.executeTaskInMainQueueWithCompletion { [weak self] in
            if self == nil{
                return
            }
            
            self!.navigationItem.title = self!.navigationTitleString
            self!.aView.endEditing(true)
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    deinit{
        
        print("BaseView Controller Deinit Called")
        NotificationCenter.default.removeObserver(self)
        
        if aView != nil && aView.superview != nil{
            aView.releaseObject()
            aView.removeFromSuperview()
            aView = nil
        }
        
        if baseLayout != nil{
            baseLayout.releaseObject()
            baseLayout = nil
        }
        
        navigationTitleString = nil
    }
    
    // MARK: - Layout -
    
    open func loadViewControls(){
        
        self.view.backgroundColor = Color.appPrimaryBG.value
        self.view.addSubview(aView)
        self.view.isExclusiveTouch = true
        self.view.isMultipleTouchEnabled = true
    }
    
    open func setViewlayout(){
        
        /*  baseLayout Allocation   */
        baseLayout = AppBaseLayout()
    }
    
    public func expandViewInsideView(){
        baseLayout.expandView(aView, insideView: self.view)
    }
    
    
    // MARK: - Public Interface -
    
    public func displayMenuButton(image : UIImage?){
        if image == nil{
            let barButtonItem = BaseDrawerMenuItem(target: self, action: #selector(openslider))
            
            self.navigationItem.leftBarButtonItem = barButtonItem
            
            return
        }
        var origImage : UIImage? = image
        var tintedImage : UIImage? = origImage!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        
        btnName = UIButton()
        btnName.setImage(tintedImage!, for: UIControlState())
        btnName.tintColor = UIColor.white
        btnName.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnName.addTarget(self, action: #selector(openslider), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnName)
        
        origImage = nil
        tintedImage = nil
    }
    
    public func openslider() {
        self.view.endEditing(true)
        self.present(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
    }
    
    public func HideMenuButton(){
        self.navigationItem.leftBarButtonItem = nil
    }

    // MARK: - User Interaction -
    
    
    // MARK: - Internal Helpers -
    
    
    // Mark - UINavigationControllerDelegate
    
}
