//
//  Created by Prashant Dabhi on 08/01/19.
//  Copyright © 2019 Prashant Dabhi. All rights reserved.
//

import UIKit

class APITestViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func callAPI(_ sender: Any) {
        var paramsToSend = Parameters()
        
        let urlToCall: String = "https://pehoy.com/selcombankhttz/API/V_1/login"
        
        paramsToSend["mobileNumber"] = "987456120"
        paramsToSend["pin"] = "1234"
        
//        let urlToCall: String = "http://159.65.144.93/foms/API/V_1/Login"
//
//        paramsToSend["email"] = "d@d.com"
//        paramsToSend["password"] = "123"
       
        APIManager.shared.post(urlToCall,
                               requestBody: paramsToSend,
                               apiManagerProperties: [APIManagerProperty.shouldShowProgressHUD: false],
                               fromViewController: self,
                               onSuccessHandler: { (data, statusCode) in
                                print(data.toUTF8String())
        }, onFailureHandler: { (errorMessage, statusCode) in
            print(errorMessage)
        }) {
            print("_")
        }
    }
    
    @IBAction func callAPIMES_Login_GET(_ sender: Any) {
        self.login(type: LoginModel.self) { (responseModel) in
            if let responseModel = responseModel {
                self.mesAuth = responseModel.Result!.token_type! + " " + responseModel.Result!.access_token!
                self.mesUserID = responseModel.Result!.data!.app_user_id!
                print(responseModel.Result?.message ?? "")
            }
        }
    }
    
    var mesAuth: String = ""
    var mesUserID: String = ""
    
    @IBAction func callAPIMES_CountryList_GET(_ sender: Any) {
        self.getCountries(type: CountryModel.self,
                          mesAuth: self.mesAuth,
                          mesUserID: self.mesUserID) { (countryResponse) in
                            if let countryResponse = countryResponse {
                                print("Total received countries: \(countryResponse.data?.count ?? 0)")
                            } else {
                                print("Failed in parsing response")
                            }
        }
    }
}

class BaseModel: Codable {
    let status: String?
}

class LoginModel: Codable {
    let StatusCode : Int?
    let ErrorText:String?
    let PageInfo:String?
    let ErrorObject:String?
    let Category:String?
    let SuccessMessage:String?
    let Result : Result?
}

class Result: Codable {
    let status : String?
    let message : String?
    let access_token : String?
    let token_type : String?
    let data : CustomData?
}

class CustomData: Codable {
    let app_user_id :String?
    let Inspector_ID : String?
    let InspectorFname : String?
    let InspectorLName : String?
    let DisplayName : String?
    let Email : String?
    let Phone : String?
}


class CountryModel: Codable {
    let status : String?
    let message : String?
    let data_id : String?
    let data : [CountryList]?
}

class CountryList : Codable {
    let country_id : Int?
    let country_code : String?
    let country : String?
}
