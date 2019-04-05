//
//  Created by Prashant Dabhi on 08/01/19.
//  Copyright © 2019 Prashant Dabhi. All rights reserved.
//

import UIKit

private let TAB_BAR_DEFAULT_EDGE_INSETS: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
private let TABS_COLLECTIONVIEW_HEIGHT: CGFloat = 60
private let TAB_BAR_BACKGROUND_COLOR: UIColor = .white

protocol MTPLTabBarViewDelegate: class {
    var tabBarViewControllers: [UIViewController]? { get set }
    
    func tabBarViewController(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath, isSelected: Bool) -> UICollectionViewCell
    func tabBarViewController(didPresentControllerAt index: Int)


    func tabBarViewEdgeInsets() -> UIEdgeInsets
    func tabBarBackgroundColor() -> UIColor
}

extension MTPLTabBarViewDelegate {
    func tabBarViewController(didPresentControllerAt index: Int) {}
    
    func tabBarViewEdgeInsets() -> UIEdgeInsets { return TAB_BAR_DEFAULT_EDGE_INSETS }
    func tabBarBackgroundColor() -> UIColor { return TAB_BAR_BACKGROUND_COLOR }
}

class MTPLTabBarView: UIView {
    
    weak var mtplTabBarDelegate: MTPLTabBarViewDelegate?
    
    private let tabsCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.bounces = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = false
        return collectionView
    }()
    
    private let tabsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private var selectedTabIndex: Int?
    
    public var bottmTabViewHeight: CGFloat? {
        didSet {
            self.tabsCollectionView.heightAnchor.constraint(equalToConstant: bottmTabViewHeight ?? TABS_COLLECTIONVIEW_HEIGHT).isActive = true
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupUI()
    }
    
    private func setupUI() {
        self.tabsCollectionView.dataSource = self
        self.tabsCollectionView.delegate = self
    }
    
    open func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.tabsCollectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    open func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        self.tabsCollectionView.register(nib, forCellWithReuseIdentifier: identifier)
    }
    
    
    func setupAndPresentTabBar(selectedTab newIndex: Int?) {
        guard let parentVC = self.mtplTabBarDelegate as? UIViewController,
        let parentView = parentVC.view
        else {
            print("Parent View not initialiazed")
            return
        }
        
        if !parentView.subviews.contains(tabsContainerView) {
            parentView.addSubview(tabsContainerView)
            parentView.addSubview(tabsCollectionView)
            
            if #available(iOS 11, *) {
                let guide = parentView.safeAreaLayoutGuide
                guide.bottomAnchor.constraint(equalTo: self.tabsCollectionView.bottomAnchor).isActive = true
            } else {
                self.tabsCollectionView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor).isActive = true
            }
            
            self.tabsCollectionView.leftAnchor.constraint(equalTo: parentView.leftAnchor).isActive = true
            self.tabsCollectionView.rightAnchor.constraint(equalTo: parentView.rightAnchor).isActive = true
            self.tabsCollectionView.heightAnchor.constraint(equalToConstant: TABS_COLLECTIONVIEW_HEIGHT).isActive = true
            
            if #available(iOS 11, *) {
                let guide = parentView.safeAreaLayoutGuide
                guide.topAnchor.constraint(equalTo: self.tabsContainerView.topAnchor).isActive = true
            } else {
                self.tabsContainerView.topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
            }
            
            self.tabsContainerView.leftAnchor.constraint(equalTo: parentView.leftAnchor).isActive = true
            self.tabsContainerView.rightAnchor.constraint(equalTo: parentView.rightAnchor).isActive = true
            self.tabsContainerView.bottomAnchor.constraint(equalTo: self.tabsCollectionView.topAnchor).isActive = true
        } else {
            print("Parent view has already 2 views")
        }
        
        self.tabsCollectionView.backgroundColor = self.mtplTabBarDelegate?.tabBarBackgroundColor() ?? TAB_BAR_BACKGROUND_COLOR
        parentView.backgroundColor = self.tabsCollectionView.backgroundColor
        
        _ = self.setSelectedTab(newIndex)
    }
    
    func setSelectedTab(_ newIndex: Int?) -> Bool {
        if let currentViewController = self.mtplTabBarDelegate?.tabBarViewControllers?[safe: self.selectedTabIndex] {
            currentViewController.removeAsChild()
        }
        
        if let newVC = self.mtplTabBarDelegate?.tabBarViewControllers?[safe: newIndex],
            let parentVC = self.mtplTabBarDelegate as? UIViewController {
            self.selectedTabIndex = newIndex
            
            parentVC.title = newVC.title
            
            parentVC.add(newVC, containerView: self.tabsContainerView)
            
            return true
        }
        
        return false
    }
}

extension MTPLTabBarView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mtplTabBarDelegate?.tabBarViewControllers?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.mtplTabBarDelegate?.tabBarViewController(collectionView, cellForItemAt: indexPath, isSelected: indexPath.item == self.selectedTabIndex) ?? UICollectionViewCell()
    }
}

extension MTPLTabBarView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
         let height = collectionView.frame.height
        
        return CGSize(width: height, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return self.mtplTabBarDelegate?.tabBarViewEdgeInsets() ?? TAB_BAR_DEFAULT_EDGE_INSETS
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == self.selectedTabIndex {
            return
        }
        
        if self.setSelectedTab(indexPath.item) {
            self.mtplTabBarDelegate?.tabBarViewController(didPresentControllerAt: indexPath.item)
        }
    }
}

extension UIViewController {
    // Parent VC will call
    func add(_ child: UIViewController, containerView: UIView) {
        addChild(child)
        containerView.addSubview(child.view)
        child.didMove(toParent: self)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        
        child.view.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        child.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        child.view.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        child.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    }
    
    
    // Child VC will call
    func removeAsChild() {
        guard parent != nil else {
            return
        }
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }
}
