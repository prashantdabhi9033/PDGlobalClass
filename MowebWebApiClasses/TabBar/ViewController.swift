//
//  ViewController.swift
//  MowebWebApiClasses
//
//  Created by Ankit Patel on 08/01/19.
//  Copyright © 2019 Ankit Patel. All rights reserved.
//

import UIKit
 
class ViewController: UIViewController, MTPLTabBarViewDelegate {
    var tabBarViewControllers: [UIViewController]? = {
       let vc1 = UIViewController()
        vc1.view.backgroundColor = .red
        vc1.title = "View controller 1"
        
        let vc2 = UIViewController()
        vc2.view.backgroundColor = .yellow
        vc2.title = "View controller 2"
        
        let vc3 = UIViewController()
        vc3.view.backgroundColor = .green
        vc3.title = "View controller 3"
        
        let vc4 = UIViewController()
        vc4.view.backgroundColor = .purple
        vc4.title = "View controller 4"
        
        let vc5 = UIViewController()
        vc5.view.backgroundColor = .blue
        vc5.title = "View controller 5"
        
        return [vc1, vc2, vc3, vc4, vc5]
    }()
    
    var tabBarView: MTPLTabBarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tabBarView = MTPLTabBarView()
        tabBarView.mtplTabBarDelegate = self
        tabBarView.register(UINib(nibName: String(describing: TabBarCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: "cell")
         
        tabBarView.setupAndPresentTabBar(selectedTab: nil)
    }
    
    func tabBarViewController(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath, isSelected: Bool) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TabBarCollectionViewCell
        cell.displayLabel.text = "\(indexPath.item)"
        
        return cell
    }
}

