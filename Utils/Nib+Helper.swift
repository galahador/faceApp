//
//  Nib+Helper.swift
//  FaceApp
//
//  Created by tBug on 27.10.24..
//

import UIKit

public class ViewWithNib: UIView {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        NibSupport.setupNib(view: self)
        
        localizeView()
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
        NibSupport.setupNib(view: self)
        
        localizeView()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func localizeView() {
        // Override in children
    }
}

public class TableHeaderFooterViewWithNib: UITableViewHeaderFooterView {
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        NibSupport.setupNib(view: self)
        
        localizeView()
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NibSupport.setupNib(view: self)
        
        localizeView()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func localizeView() {
        // Override in children
    }
}

public class TableViewCellWithNib: UITableViewCell {
    
    init(reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        NibSupport.setupNib(view: self)
        
        localizeView()
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
        NibSupport.setupNib(view: self)
        
        localizeView()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func localizeView() {
        // Override in children
    }
}

private class NibSupport {
    
    static func setupNib(view: UIView) {
        let childView = self.loadNib(view: view)
        childView.translatesAutoresizingMaskIntoConstraints = false
        
        if view is UITableViewCell {
            addChildViewWithConstraints(view: (view as! UITableViewCell).contentView, childView: childView)
        } else {
            addChildViewWithConstraints(view: view, childView: childView)
        }
    }
    
    private static func addChildViewWithConstraints(view: UIView, childView: UIView) {
        view.addSubview(childView)
        
        constraint(view: view, child:childView, attribute:.width)
        constraint(view: view, child:childView, attribute:.height)
        constraint(view: view, child:childView, attribute:.top)
        constraint(view: view, child:childView, attribute:.leading)
    }
    
    private static func constraint(view:UIView, child:UIView, attribute:NSLayoutConstraint.Attribute) -> Void {
        let constraint = NSLayoutConstraint(
            item: child,
            attribute: attribute,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: view,
            attribute: attribute,
            multiplier: 1.0,
            constant: 0)
        
        view.addConstraint(constraint)
    }
    
    private static func loadNib(view: UIView) -> UIView {
        let bundle = Bundle(for: type(of: view))
        
        let nib = UINib(nibName: nibName(view: view), bundle: bundle)
        return nib.instantiate(withOwner: view, options: nil)[0] as! UIView
    }
    
    private static func nibName(view: UIView) -> String {
        return type(of: view).description().components(separatedBy: ".").last!
    }
    
}
