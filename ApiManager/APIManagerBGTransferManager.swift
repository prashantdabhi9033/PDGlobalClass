//
//  Created by Prashant Dabhi on 08/01/19.
//  Copyright © 2019 Prashant Dabhi. All rights reserved.
//

import Foundation

class APIManagerBGVideoUpload {
    class func upload() {
        //APIManagerBGTransferManager.shared.urlSession.upload
    }
}

class APIManagerBGTransferManager {
    static let shared: APIManagerBGTransferManager = APIManagerBGTransferManager()
    
    public var urlSession: URLSession!
    
    private init() {
        
        self.urlSession = URLSession(configuration: createURLSessionConfiguration())
    }
}

extension APIManagerBGTransferManager {
    func createURLSessionConfiguration(withTimeOutIntervalInSeconds seconds: Int = 30) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.something.backgroundUploadTask")
        configuration.timeoutIntervalForRequest = TimeInterval(seconds)
        configuration.timeoutIntervalForResource = TimeInterval(seconds * 2)
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return configuration
    }
}
