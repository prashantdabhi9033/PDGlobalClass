//
//  Created by Prashant Dabhi on 08/01/19.
//  Copyright © 2019 Prashant Dabhi. All rights reserved.
//

import UIKit

public typealias APIFailureRetryTapHandler = (() -> Void)

class BaseAPIFailureRetryView: UIView {
    var retryAPITapped: APIFailureRetryTapHandler?
    
    var reachability: Reachability?
    
    func addToParentView(parentView: UIView, newTag: Int) {
        
        if let selfExisting = parentView.subviews.filter( { $0 == self }).first {
            selfExisting.removeFromSuperview()
        }
         
        self.tag = newTag
        self.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(self)
        self.leftAnchor.constraint(equalTo: parentView.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: parentView.rightAnchor).isActive = true
        self.topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: parentView.bottomAnchor).isActive = true
    }
    
    @IBAction func retryEventTapped(_ sender: Any) {
        self.retryAPITapped?()
    }
    
    func removeAllObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupAutoCallMode() {
        if reachability == nil {
            reachability = Reachability()
        }
        
        self.removeAllObserver()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged(_:)),
                                               name: .reachabilityChanged, object:reachability)
        do {
            try reachability?.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
    }
    
    @objc private func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        
        if reachability.isInternetReachable {
            print("\(BaseAPIFailureRetryView.self) has autocall enabled and calling it")
            self.retryAPITapped?()
            self.removeAllObserver()
        }
    }
}
