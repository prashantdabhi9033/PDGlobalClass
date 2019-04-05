
//  Created by Prashant Dabhi on 27/03/19.
//  Copyright © 2019 Prashant Dabhi. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
}


// MARK: API Management
extension BaseViewController {
    func login<T: Codable>(type: T.Type, completion: @escaping (T?) -> Void) {
        var paramsToSend = Parameters()
        
        let urlToCall: String = "https://meshtestapi.mesinc.net/Account/login"
        
        paramsToSend["emp_id"] = "amotipara"
        paramsToSend["password"] = "YpBvuU35"
        
        var newProps = APIManagerPropertySet()
        newProps[.authorizationValue] = ""
        newProps[.jsonParameterRootKey] = ""
        newProps[.defaultContentType] = APIManagerRequestContentType.application_json
        
        APIManager.shared.post(urlToCall, requestBody: paramsToSend, apiManagerProperties: newProps, fromViewController: self, type: type, onSuccessHandler: { (data, responseModel, statusCode) in
             completion(responseModel)
            print(String(data: data, encoding: .utf8)!)
        }, onFailureHandler: { (error, code) in
            completion(nil)
        }) {
            completion(nil)
        }
    }
    
    func getCountries<T: Codable>(type: T.Type, mesAuth: String, mesUserID: String, completion: @escaping (T?) -> Void) {
        var paramsToSend = Parameters()
        
        let urlToCall: String = "https://meshtestapi.mesinc.net/admin/QAAppApi/fetch_country_list"
        
        paramsToSend["app_user_id"] = mesUserID
        
        
        var newProps = APIManagerPropertySet()
        newProps[.authorizationValue] = mesAuth
        newProps[.jsonParameterRootKey] = ""
        newProps[.defaultContentType] = APIManagerRequestContentType.application_json
        
        APIManager.shared.get(urlToCall, requestParameters: paramsToSend, apiManagerProperties: newProps, fromViewController: self, type: type ,onSuccessHandler: { (data, responseModel, statusCode) in
            print(String(data: data, encoding: .utf8)!)
            completion(responseModel)
        }, onFailureHandler: { (errorMessage, statusCode) in
            print(errorMessage)
            completion(nil)
        }) {
            completion(nil)
        }
    }
}
