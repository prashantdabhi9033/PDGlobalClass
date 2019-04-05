//
//  Created by Prashant Dabhi on 08/01/19.
//  Copyright © 2019 Prashant Dabhi. All rights reserved.
//

import UIKit

public typealias APIManagerSuccessHandlerT<T: Codable> = ((Data, T, Int) -> Void)
public typealias APIManagerSuccessHandler = ((Data, Int) -> Void)
public typealias APIManagerDownloadSuccessHandler = ((URL) -> Void)
public typealias APIManagerFailureHandler = ((String, Int?) -> Void)
public typealias APIManagerNoInternetConnectionHandler = (() -> Void)

public typealias APIManagerPropertySet = [APIManagerProperty: Any?]

protocol APIManagerDelegate: class {
    func showProgressHUD(withMessage message: String?, senderVC: UIViewController, shouldShowProgressFlag: Bool)
    func hideProgressHUD(senderVC: UIViewController, shouldShowProgressFlag: Bool)
    func showAlert(message: String, senderVC: UIViewController, shouldShowProgressFlag: Bool)
}

public enum APIManagerProperty {
    case commonParameters
    case headerKey
    case jsonParameterRootKey
    case authorizationValue
    case apiFailureRetryViewParent
    case apiFailureRetryView
    case shouldParformAPIWhenInternetResume
    case defaultContentType
    case shouldShowAPIFailureRetryView
    case shouldShowProgressHUD
    case progressHUDMessage
}

public enum APIManagerRequestContentType {
    case application_json
    case application_x_www_form_urlencoded
    case application_multipart_fordata
}

class APIManager {
    
    //MARK: ---- All ClassObject ----
    static let shared = APIManager()
    weak var apiManagerDelegate: APIManagerDelegate?
    
    public var reachability: Reachability?
    
    public var postApiInProgress: Int = 0
    public var postAttachmentApiInProgress: Int = 0
    
    static var generalServerError: String = ""
    static var generalNoInternetError: String = ""
    
    static var timeoutInterval: Double = 60.0
    
    public var commonAPIRequestParameters: Parameters = Parameters()
    public var headerkey: String = ""
    public var rootKJSONParamsKey: String? = nil
    public var authorizationValue: String? = nil
    public var apiFailureRetryViewParent: UIView? = nil
    public var apiFailureRetryView: BaseAPIFailureRetryView? = nil
    public var shouldParformAPIWhenInternetResume: Bool = false
    public var defaultContentType: APIManagerRequestContentType = .application_x_www_form_urlencoded
    public var shouldShowAPIFailureRetryView: Bool = false
    public var shouldShowProgressHUD: Bool = true
    public var progressHUDMessage: String = "Please try again later."
    
    public let apiFailureRetryViewTag: Int = 121223322
    
    /*
     onSuccessHandler -> Will be called on successful response checking
     onFailureHandler (optional) -> Will be called when an error is occured, it will be directly haldled from api but if an view controller wants seperate implementation
     noInternetAccess (optional) -> to reload tables or make any view active
     */
    
    init() {
        self.setupReachability()
    }
    
    private func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    func apiManagerCommonProperties() -> APIManagerPropertySet {
        return [
            APIManagerProperty.commonParameters: self.commonAPIRequestParameters,
            APIManagerProperty.headerKey : self.headerkey,
            APIManagerProperty.jsonParameterRootKey: self.rootKJSONParamsKey ?? "",
            APIManagerProperty.authorizationValue: self.authorizationValue,
            APIManagerProperty.apiFailureRetryViewParent: self.apiFailureRetryViewParent,
            APIManagerProperty.apiFailureRetryView: self.apiFailureRetryView,
            APIManagerProperty.shouldParformAPIWhenInternetResume: self.shouldParformAPIWhenInternetResume,
            APIManagerProperty.defaultContentType: self.defaultContentType,
            APIManagerProperty.shouldShowAPIFailureRetryView: self.shouldShowAPIFailureRetryView,
            APIManagerProperty.shouldShowProgressHUD: self.shouldShowProgressHUD,
            APIManagerProperty.progressHUDMessage: self.progressHUDMessage
        ]
    }
    
    func register(defaultProperty: Any?, for propertyType: APIManagerProperty) {
        switch propertyType {
        case .commonParameters:
            self.commonAPIRequestParameters = defaultProperty as? Parameters ?? Parameters()
            break
        case .headerKey:
            self.headerkey = defaultProperty as? String ?? self.headerkey
            break
        case .jsonParameterRootKey:
            self.rootKJSONParamsKey = defaultProperty as? String ?? self.rootKJSONParamsKey
            break
        case .authorizationValue:
            self.authorizationValue = defaultProperty as? String ?? self.authorizationValue
            break
        case .apiFailureRetryViewParent:
            self.apiFailureRetryViewParent = defaultProperty as? UIView ?? self.apiFailureRetryViewParent
            break
        case .apiFailureRetryView:
            self.apiFailureRetryView = defaultProperty as? BaseAPIFailureRetryView ?? self.apiFailureRetryView
            break
        case .shouldParformAPIWhenInternetResume:
            self.shouldParformAPIWhenInternetResume = defaultProperty as? Bool ?? self.shouldParformAPIWhenInternetResume
        case .defaultContentType:
            self.defaultContentType = defaultProperty as? APIManagerRequestContentType ?? self.defaultContentType
        case .shouldShowAPIFailureRetryView:
            self.shouldShowAPIFailureRetryView = defaultProperty as? Bool ?? self.shouldShowAPIFailureRetryView
        case .shouldShowProgressHUD:
            self.shouldShowAPIFailureRetryView = defaultProperty as? Bool ?? self.shouldShowAPIFailureRetryView
        case .progressHUDMessage:
            self.progressHUDMessage = defaultProperty as? String ?? self.progressHUDMessage
        }
    }
    
    func download(from destinationURL: String,
                  fromViewController: UIViewController,
                  apiManagerProperties: APIManagerPropertySet?,
                  onSuccessHandler: @escaping APIManagerDownloadSuccessHandler,
                  onFailureHandler: @escaping APIManagerFailureHandler ,
                  noInternetAccess: APIManagerNoInternetConnectionHandler?) -> Void {
        
        let apiManagerProperties: APIManagerPropertySet = self.apiManagerCommonProperties().overrideProperties(from: apiManagerProperties)
        
        let attachmentURL = URL(string: destinationURL)!
        
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        
        let targetURL = tempDirectoryURL.appendingPathComponent(attachmentURL.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: targetURL.path) {
            onSuccessHandler(targetURL)
            return
        }
        
        if reachability?.isInternetReachable ?? false {
            apiManagerDelegate?.showProgressHUD(withMessage: apiManagerProperties.getProperty(of: APIManagerProperty.progressHUDMessage,
                                                                                              parsingType: String.self) ?? self.progressHUDMessage,
                                                senderVC: fromViewController,
                                                shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                         parsingType: Bool.self) ?? self.shouldShowProgressHUD)
            
            let session = URLSession(configuration: URLSessionConfiguration.default,
                                     delegate: nil,
                                     delegateQueue: nil)
            
            var request = URLRequest(url: attachmentURL)
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.httpMethod = HttpMethod.get.rawValue
            
            
            let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                DispatchQueue.main.async(execute: {
                    self.apiManagerDelegate?.hideProgressHUD(senderVC: fromViewController,
                                                             shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                                      parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                    
                    if let error = error {
                        onFailureHandler(error.localizedDescription, response?.httpStatusCode)
                        print("error \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                        return
                    }
                    
                    if let response = response as? HTTPURLResponse,
                        response.statusCode == 200,
                        let data = data,
                        let _ = try? data.write(to: targetURL, options: Data.WritingOptions.atomic) {
                        
                        onSuccessHandler(targetURL)
                    } else {
                        if let response = response as? HTTPURLResponse {
                            response.printFailureLogs()
                        }
                        
                        onFailureHandler(APIManager.generalServerError, response?.httpStatusCode)
                    }
                    return
                })
            }
            task.resume()
        } else {
            DispatchQueue.main.async(execute: {
                self.apiManagerDelegate?.hideProgressHUD(senderVC: fromViewController,
                                                         shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                                  parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                self.apiManagerDelegate?.showAlert(message: APIManager.generalNoInternetError,
                                                   senderVC: fromViewController,
                                                   shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                            parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                noInternetAccess?()
                return
            })
        }
    }
    
    func get<T: Codable>(_ urlString: String,
                         requestParameters: Parameters,
                         apiManagerProperties: APIManagerPropertySet?,
                         fromViewController: UIViewController,
                         type: T.Type,
                         onSuccessHandler: @escaping APIManagerSuccessHandlerT<T>,
                         onFailureHandler: @escaping APIManagerFailureHandler,
                         noInternetAccess: APIManagerNoInternetConnectionHandler?) {
        
        let apiManagerProperties: APIManagerPropertySet = self.apiManagerCommonProperties().overrideProperties(from: apiManagerProperties)
        
        self.get(urlString,
                 requestParameters: requestParameters,
                 apiManagerProperties: apiManagerProperties,
                 fromViewController: fromViewController,
                 onSuccessHandler: { (data, statusCode) in
            if let responseModel = try? JSONDecoder().decode(type, from: data) {
                onSuccessHandler(data, responseModel, statusCode)
            } else {
                onFailureHandler(APIManager.generalServerError, statusCode)
            }
        }, onFailureHandler: onFailureHandler, noInternetAccess: noInternetAccess)
    }
    
    func get(_ urlString: String,
             requestParameters: Parameters,
             apiManagerProperties: APIManagerPropertySet?,
             fromViewController: UIViewController,
             onSuccessHandler: @escaping APIManagerSuccessHandler,
             onFailureHandler: @escaping APIManagerFailureHandler,
             noInternetAccess: APIManagerNoInternetConnectionHandler?) {
        let apiManagerProperties: APIManagerPropertySet = self.apiManagerCommonProperties().overrideProperties(from: apiManagerProperties)
        
        let finalURLString: String = urlString.appending("?\(requestParameters.getQueryString())")
        
        let finalURL = URL(string: finalURLString)!
        
 
        //making request
        var request: URLRequest = URLRequest(url: finalURL)
//        request.setValue(paramsToSend.makeSHA256(headerKey: apiManagerProperties.getProperty(of: APIManagerProperty.headerKey,
//                                                                                             parsingType: String.self) ?? ""),
//                         forHTTPHeaderField: "X-Hash")
        
        
        
        request.addValue("close", forHTTPHeaderField: "Connection")
        
        if let authValue = apiManagerProperties.getProperty(of: APIManagerProperty.authorizationValue, parsingType: String.self) {
            request.addValue(authValue, forHTTPHeaderField: "Authorization")
        }
        
        request.httpMethod = HttpMethod.get.rawValue
        request.timeoutInterval = APIManager.timeoutInterval
        request.cachePolicy = .reloadIgnoringCacheData
        
        if reachability?.isInternetReachable ?? false {
            postApiInProgress += 1
            apiManagerDelegate?.showProgressHUD(withMessage: apiManagerProperties.getProperty(of: APIManagerProperty.progressHUDMessage,
                                                                                              parsingType: String.self) ?? self.progressHUDMessage,
                                                senderVC: fromViewController,
                                                shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                         parsingType: Bool.self) ?? self.shouldShowProgressHUD)
            
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                DispatchQueue.main.async(execute: {
                    
                    self.postApiInProgress -= 1
                    
                    if self.postApiInProgress <= 0 {
                        self.apiManagerDelegate?.hideProgressHUD(senderVC: fromViewController,
                                                                 shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                                          parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                    }
                    
                    if let error = error {
                        if apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowAPIFailureRetryView, parsingType: Bool.self) ?? self.shouldShowAPIFailureRetryView {
                            let result = self.addAPIFailureRetryView(apiManagerProperties: apiManagerProperties, onRetryTapped: {
                                self.get(urlString, requestParameters: requestParameters, apiManagerProperties: apiManagerProperties, fromViewController: fromViewController, onSuccessHandler: onSuccessHandler, onFailureHandler: onFailureHandler, noInternetAccess: noInternetAccess)
                            })
                            
                            if !result {
                                onFailureHandler(error.localizedDescription, response?.httpStatusCode)
                                return
                            }
                        } else {
                            onFailureHandler(error.localizedDescription, response?.httpStatusCode)
                            return
                        }
                    }
                    
                    if let response = response as? HTTPURLResponse,
                        response.statusCode == 200,
                        let data = data {
                        
                        if let jsonKey = apiManagerProperties.getProperty(of: APIManagerProperty.jsonParameterRootKey, parsingType: String.self),
                            jsonKey.count > 0,
                            let decodedString = data.toUTF8String().parseFromBase64WithRandomCharacters(),
                            let decodedData = decodedString.data(using: .utf8, allowLossyConversion: true) {
                            onSuccessHandler(decodedData, response.statusCode)
                        } else {
                            onSuccessHandler(data, response.statusCode)
                        }
                        
                        self.removeAPIFailureRetryView(apiManagerProperties: apiManagerProperties)
                    } else {
                        if let response = response as? HTTPURLResponse {
                            response.printFailureLogs()
                        }
                        
                        if apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowAPIFailureRetryView, parsingType: Bool.self) ?? self.shouldShowAPIFailureRetryView {
                            let result = self.addAPIFailureRetryView(apiManagerProperties: apiManagerProperties, onRetryTapped: {
                                self.get(urlString, requestParameters: requestParameters, apiManagerProperties: apiManagerProperties, fromViewController: fromViewController, onSuccessHandler: onSuccessHandler, onFailureHandler: onFailureHandler, noInternetAccess: noInternetAccess)
                            })
                            
                            if !result {
                                onFailureHandler(APIManager.generalServerError, response?.httpStatusCode)
                            }
                        } else {
                            onFailureHandler(APIManager.generalServerError, response?.httpStatusCode)
                        }
                    }
                    return
                })
            }
            task.resume()
        } else {
            DispatchQueue.main.async(execute: {
                self.apiManagerDelegate?.hideProgressHUD(senderVC: fromViewController,
                                                         shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                                  parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                if apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowAPIFailureRetryView,
                                                    parsingType: Bool.self) ?? self.shouldShowAPIFailureRetryView {
                    let result = self.addAPIFailureRetryView(apiManagerProperties: apiManagerProperties, onRetryTapped: {
                        self.get(urlString, requestParameters: requestParameters, apiManagerProperties: apiManagerProperties, fromViewController: fromViewController, onSuccessHandler: onSuccessHandler, onFailureHandler: onFailureHandler, noInternetAccess: noInternetAccess)
                    })
                    
                    if !result {
                        self.apiManagerDelegate?.showAlert(message: APIManager.generalNoInternetError, senderVC: fromViewController, shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD, parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                        noInternetAccess?()
                    }
                } else {
                    self.apiManagerDelegate?.showAlert(message: APIManager.generalNoInternetError, senderVC: fromViewController, shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD, parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                    noInternetAccess?()
                }
                return
            })
        }
    }
    
    func post<T: Codable>(_ urlString: String,
                          requestBody: Parameters,
                          apiManagerProperties: APIManagerPropertySet?,
                          fromViewController: UIViewController,
                          type: T.Type,
                          onSuccessHandler: @escaping APIManagerSuccessHandlerT<T>,
                          onFailureHandler: @escaping APIManagerFailureHandler,
                          noInternetAccess: APIManagerNoInternetConnectionHandler?) -> Void {
        
        let apiManagerProperties: APIManagerPropertySet = self.apiManagerCommonProperties().overrideProperties(from: apiManagerProperties)
        
        self.post(urlString,
                  requestBody: requestBody,
                  apiManagerProperties: apiManagerProperties,
                  fromViewController: fromViewController,
                  onSuccessHandler: { (data, statusCode) in
                    if let responseModel = try? JSONDecoder().decode(type, from: data) {
                        onSuccessHandler(data, responseModel, statusCode)
                    } else {
                        onFailureHandler(APIManager.generalServerError, statusCode)
                    }
        },  onFailureHandler: onFailureHandler,
            noInternetAccess: noInternetAccess)
    }
    
    func post(_ urlString: String,
              requestBody: Parameters,
              apiManagerProperties: APIManagerPropertySet?,
              fromViewController: UIViewController,
              onSuccessHandler: @escaping APIManagerSuccessHandler,
              onFailureHandler: @escaping APIManagerFailureHandler,
              noInternetAccess: APIManagerNoInternetConnectionHandler?) -> Void {
        
        let apiManagerProperties: APIManagerPropertySet = self.apiManagerCommonProperties().overrideProperties(from: apiManagerProperties)
        
        let finalURL = URL(string: urlString)
        
        let paramsToSend = mergeCommonParameters(requestBody, apiManagerProperties: apiManagerProperties)
        
        //making request
        var request: URLRequest = URLRequest(url: finalURL!)
        request.setValue(paramsToSend.makeSHA256(headerKey: apiManagerProperties.getProperty(of: APIManagerProperty.headerKey,
                                                                                             parsingType: String.self) ?? ""),
                         forHTTPHeaderField: "X-Hash")
        
        let contentType = apiManagerProperties.getProperty(of: APIManagerProperty.defaultContentType,
                                                           parsingType: APIManagerRequestContentType.self) ?? self.defaultContentType
        switch contentType {
            
        case .application_json:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = paramsToSend.toJSONString().data(using: .utf8)
            
            break
        case .application_x_www_form_urlencoded:
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            if let jsonKey = apiManagerProperties.getProperty(of: APIManagerProperty.jsonParameterRootKey, parsingType: String.self), jsonKey.count > 0 {
                request.httpBody = ([jsonKey: paramsToSend.toJSONString().convertBase64WithRandomCharacters()]).getQueryString().data(using: .utf8)
            } else {
                request.httpBody = paramsToSend.getQueryString().data(using: .utf8)
            }
            
            break
            
        case .application_multipart_fordata:
            let boundary = generateBoundary()
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let lineBreak = "\r\n"
            var body = Data()
            
            if let rootJSONKey = rootKJSONParamsKey, rootJSONKey.count > 0 {
                body.append(string:"--\(boundary + lineBreak)")
                body.append(string:"Content-Disposition: form-data; name=\"\(rootJSONKey)\"\(lineBreak + lineBreak)")
                body.append(string:"\(requestBody.toJSONString().convertBase64WithRandomCharacters() + lineBreak)")
            } else {
                for (key, value) in requestBody {
                    body.append(string:"--\(boundary + lineBreak)")
                    body.append(string:"Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                    body.append(string:"\(String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? "" + lineBreak)")
                }
            }
            
            request.httpBody = body
            
            break
        }
        
        request.addValue("close", forHTTPHeaderField: "Connection")
        
        if let authValue = apiManagerProperties.getProperty(of: APIManagerProperty.authorizationValue, parsingType: String.self) {
            request.addValue(authValue, forHTTPHeaderField: "Authorization")
        }
        
        request.httpMethod = HttpMethod.post.rawValue
        request.timeoutInterval = APIManager.timeoutInterval
        request.cachePolicy = .reloadIgnoringCacheData
        
        if reachability?.isInternetReachable ?? false {
            postApiInProgress += 1
            apiManagerDelegate?.showProgressHUD(withMessage: apiManagerProperties.getProperty(of: APIManagerProperty.progressHUDMessage,
                                                                                              parsingType: String.self) ?? self.progressHUDMessage,
                                                senderVC: fromViewController,
                                                shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                         parsingType: Bool.self) ?? self.shouldShowProgressHUD)
            
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                DispatchQueue.main.async(execute: {
                    
                    self.postApiInProgress -= 1
                    
                    if self.postApiInProgress <= 0 {
                        self.apiManagerDelegate?.hideProgressHUD(senderVC: fromViewController,
                                                                 shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                                          parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                    }
                    
                    if let error = error {
                        if apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowAPIFailureRetryView, parsingType: Bool.self) ?? self.shouldShowAPIFailureRetryView {
                            let result = self.addAPIFailureRetryView(apiManagerProperties: apiManagerProperties, onRetryTapped: {
                                self.post(urlString, requestBody: requestBody, apiManagerProperties: apiManagerProperties, fromViewController: fromViewController, onSuccessHandler: onSuccessHandler, onFailureHandler: onFailureHandler, noInternetAccess: noInternetAccess)
                            })
                            
                            if !result {
                                onFailureHandler(error.localizedDescription, response?.httpStatusCode)
                                return
                            }
                        } else {
                            onFailureHandler(error.localizedDescription, response?.httpStatusCode)
                            return
                        }
                    }
                    
                    if let response = response as? HTTPURLResponse,
                        response.statusCode == 200,
                        let data = data {
                        
                        if let jsonKey = apiManagerProperties.getProperty(of: APIManagerProperty.jsonParameterRootKey, parsingType: String.self),
                            jsonKey.count > 0,
                            let decodedString = data.toUTF8String().parseFromBase64WithRandomCharacters() ,
                            let decodedData = decodedString.data(using: .utf8, allowLossyConversion: true) {
                            onSuccessHandler(decodedData, response.statusCode)
                        } else {
                            onSuccessHandler(data, response.statusCode)
                        }
                        
                        self.removeAPIFailureRetryView(apiManagerProperties: apiManagerProperties)
                    } else {
                        if let response = response as? HTTPURLResponse {
                            response.printFailureLogs()
                        }
                        
                        if apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowAPIFailureRetryView, parsingType: Bool.self) ?? self.shouldShowAPIFailureRetryView {
                            let result = self.addAPIFailureRetryView(apiManagerProperties: apiManagerProperties, onRetryTapped: {
                                self.post(urlString, requestBody: requestBody, apiManagerProperties: apiManagerProperties, fromViewController: fromViewController, onSuccessHandler: onSuccessHandler, onFailureHandler: onFailureHandler, noInternetAccess: noInternetAccess)
                            })
                            
                            if !result {
                                onFailureHandler(APIManager.generalServerError, response?.httpStatusCode)
                            }
                        } else {
                            onFailureHandler(APIManager.generalServerError, response?.httpStatusCode)
                        }
                    }
                    return
                })
            }
            task.resume()
        } else {
            DispatchQueue.main.async(execute: {
                self.apiManagerDelegate?.hideProgressHUD(senderVC: fromViewController,
                                                         shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                                  parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                if apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowAPIFailureRetryView,
                                                    parsingType: Bool.self) ?? self.shouldShowAPIFailureRetryView {
                    let result = self.addAPIFailureRetryView(apiManagerProperties: apiManagerProperties, onRetryTapped: {
                        self.post(urlString, requestBody: requestBody, apiManagerProperties: apiManagerProperties, fromViewController: fromViewController, onSuccessHandler: onSuccessHandler, onFailureHandler: onFailureHandler, noInternetAccess: noInternetAccess)
                    })
                    
                    if !result {
                        self.apiManagerDelegate?.showAlert(message: APIManager.generalNoInternetError, senderVC: fromViewController, shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD, parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                        noInternetAccess?()
                    }
                } else {
                    self.apiManagerDelegate?.showAlert(message: APIManager.generalNoInternetError, senderVC: fromViewController, shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD, parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                    noInternetAccess?()
                }
                return
            })
        }
    }
    
    func post<T: Codable>(_ urlString: String,
                          requestBody: Parameters,
                          mediaFiles: [APIManagerMediaFile],
                          apiManagerProperties: APIManagerPropertySet?,
                          fromViewController: UIViewController,
                          type: T.Type,
                          onSuccessHandler: @escaping APIManagerSuccessHandlerT<T>,
                          onFailureHandler: @escaping APIManagerFailureHandler,
                          noInternetAccess: APIManagerNoInternetConnectionHandler?) -> Void {
        
        let apiManagerProperties: APIManagerPropertySet = self.apiManagerCommonProperties().overrideProperties(from: apiManagerProperties)
        
        self.post(urlString, requestBody: requestBody, mediaFiles: mediaFiles, apiManagerProperties: apiManagerProperties, fromViewController: fromViewController, onSuccessHandler: { (data, statusCode) in
            if let responseModel = try? JSONDecoder().decode(type, from: data) {
                onSuccessHandler(data, responseModel, statusCode)
            } else {
                onFailureHandler(APIManager.generalServerError, statusCode)
            }
        }, onFailureHandler: onFailureHandler, noInternetAccess: noInternetAccess)
    }
    
    func post(_ urlString: String,
              requestBody: Parameters,
              mediaFiles: [APIManagerMediaFile],
              apiManagerProperties: APIManagerPropertySet?,
              fromViewController: UIViewController,
              onSuccessHandler: @escaping APIManagerSuccessHandler,
              onFailureHandler: @escaping APIManagerFailureHandler,
              noInternetAccess: APIManagerNoInternetConnectionHandler?) -> Void {
        
        let apiManagerProperties: APIManagerPropertySet = self.apiManagerCommonProperties().overrideProperties(from: apiManagerProperties)
        
        let paramsToSend = mergeCommonParameters(requestBody, apiManagerProperties: apiManagerProperties)
        
        let multiPartURLRequest = APIManagerMultiPartFileRequest(urlString,
                                                                 paramters: paramsToSend,
                                                                 mediaFiles: mediaFiles,
                                                                 header: apiManagerProperties.getProperty(of: APIManagerProperty.headerKey,
                                                                                                          parsingType: String.self) ?? "",
                                                                 authorizationValue: apiManagerProperties.getProperty(of: APIManagerProperty.authorizationValue,
                                                                                                                      parsingType: String.self) ?? "",
                                                                 rootKJSONParamsKey: apiManagerProperties.getProperty(of: APIManagerProperty.jsonParameterRootKey,
                                                                                                                      parsingType: String.self) ?? "")
        
        if reachability?.isInternetReachable ?? false {
            apiManagerDelegate?.showProgressHUD(withMessage: apiManagerProperties.getProperty(of: APIManagerProperty.progressHUDMessage,
                                                                                              parsingType: String.self) ?? self.progressHUDMessage,
                                                senderVC: fromViewController,
                                                shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                         parsingType: Bool.self) ?? self.shouldShowProgressHUD)
            postAttachmentApiInProgress += 1
            
            let task = URLSession.shared.dataTask(with: multiPartURLRequest.request!) {
                (data: Data?, response: URLResponse?, error: Error?) -> Void in
                DispatchQueue.main.async(execute: {
                    
                    self.postAttachmentApiInProgress -= 1
                    
                    if self.postAttachmentApiInProgress <= 0 {
                        self.apiManagerDelegate?.hideProgressHUD(senderVC: fromViewController,
                                                                 shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                                          parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                    }
                    
                    if let error = error {
                        onFailureHandler(error.localizedDescription, response?.httpStatusCode)
                        print("error \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                        return
                    }
                    
                    if let response = response as? HTTPURLResponse,
                        response.statusCode == 200,
                        let data = data {
                        data.printUTF8()
                        
                        if let jsonKey = apiManagerProperties.getProperty(of: APIManagerProperty.jsonParameterRootKey, parsingType: String.self),
                            jsonKey.count > 0,
                            let decodedString = data.toUTF8String().parseFromBase64WithRandomCharacters() ,
                            let decodedData = decodedString.data(using: .utf8, allowLossyConversion: true) {
                            onSuccessHandler(decodedData, response.statusCode)
                        } else {
                            onSuccessHandler(data, response.statusCode)
                        }
                    } else {
                        if let response = response as? HTTPURLResponse {
                            response.printFailureLogs()
                        }
                        onFailureHandler(APIManager.generalServerError, response?.httpStatusCode)
                    }
                    return
                })
            }
            task.resume()
        } else {
            DispatchQueue.main.async(execute: {
                self.apiManagerDelegate?.hideProgressHUD(senderVC: fromViewController,
                                                         shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                                  parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                self.apiManagerDelegate?.showAlert(message: APIManager.generalNoInternetError,
                                                   senderVC: fromViewController,
                                                   shouldShowProgressFlag: apiManagerProperties.getProperty(of: APIManagerProperty.shouldShowProgressHUD,
                                                                                                            parsingType: Bool.self) ?? self.shouldShowProgressHUD)
                noInternetAccess?()
                return
            })
        }
    }
    
    func upload(_ urlString: String,
                requestBody: Parameters,
                mediaFileURLString: String,
                apiManagerProperties: APIManagerPropertySet?,
                fromViewController: UIViewController,
                onSuccessHandler: @escaping APIManagerSuccessHandler,
                onFailureHandler: @escaping APIManagerFailureHandler,
                noInternetAccess: APIManagerNoInternetConnectionHandler?) {
        
        let apiManagerProperties: APIManagerPropertySet = self.apiManagerCommonProperties().overrideProperties(from: apiManagerProperties)
        
        
        let finalURL = URL(string: urlString)
        
        let paramsToSend = mergeCommonParameters(requestBody, apiManagerProperties: apiManagerProperties)
        
        //making request
        var request: URLRequest = URLRequest(url: finalURL!)
        request.setValue(paramsToSend.makeSHA256(headerKey: apiManagerProperties.getProperty(of: APIManagerProperty.headerKey,
                                                                                             parsingType: String.self) ?? ""),
                         forHTTPHeaderField: "X-Hash")
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("close", forHTTPHeaderField: "Connection")
        request.httpBody = paramsToSend.getQueryString().data(using: .utf8)
        request.httpMethod = HttpMethod.post.rawValue
        request.timeoutInterval = APIManager.timeoutInterval
        request.cachePolicy = .reloadIgnoringCacheData
    }
    
    private func setupReachability() {
        reachability = Reachability()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged(_:)),
                                               name: .reachabilityChanged, object:reachability)
        do {
            try reachability?.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
    }
    
    @objc func reachabilityChanged(_ note: Notification) {
        let _ = note.object as! Reachability
    }
}

extension APIManager {
    func addAPIFailureRetryView(apiManagerProperties: APIManagerPropertySet, onRetryTapped: @escaping APIFailureRetryTapHandler) -> Bool {
        
        guard let parentView = apiManagerProperties.getProperty(of: APIManagerProperty.apiFailureRetryViewParent,
                                                                parsingType: UIView.self),
            let apiRetryView = apiManagerProperties.getProperty(of: APIManagerProperty.apiFailureRetryView,
                                                                parsingType: BaseAPIFailureRetryView.self)
            else {
                return false
        }
        
        if let existingRetryView = parentView.viewWithTag(apiFailureRetryViewTag) as? BaseAPIFailureRetryView {
            existingRetryView.retryAPITapped = onRetryTapped
            print("Updating APIFailureRetryView with tag: \(apiFailureRetryViewTag)")
            existingRetryView.removeAllObserver()
            
            if let reachability = reachability, !reachability.isInternetReachable,
                let shouldAutoReload = apiManagerProperties.getProperty(of: APIManagerProperty.shouldParformAPIWhenInternetResume, parsingType: Bool.self), shouldAutoReload {
                existingRetryView.setupAutoCallMode()
            }
            
        } else {
            apiRetryView.tag = apiFailureRetryViewTag
            apiRetryView.retryAPITapped = onRetryTapped
            apiRetryView.addToParentView(parentView: parentView, newTag: apiFailureRetryViewTag)
            if let reachability = reachability, !reachability.isInternetReachable,
                let shouldAutoReload = apiManagerProperties.getProperty(of: APIManagerProperty.shouldParformAPIWhenInternetResume, parsingType: Bool.self), shouldAutoReload
            {
                apiRetryView.setupAutoCallMode()
            }
            print("Adding APIFailureRetryView with tag: \(apiFailureRetryViewTag)")
        }
        
        return true
    }
    
    func removeAPIFailureRetryView(apiManagerProperties: APIManagerPropertySet) {
        guard let parentView = apiManagerProperties.getProperty(of: APIManagerProperty.apiFailureRetryViewParent, parsingType: UIView.self) else {
            return
        }
        
        if let existingRetryView = parentView.viewWithTag(apiFailureRetryViewTag) as? BaseAPIFailureRetryView {
            existingRetryView.removeAllObserver()
            existingRetryView.removeFromSuperview()
        }
    }
}

struct APIManagerMediaFile {
    let fileApiParamKey: String?
    let fileName: String?
    var fileData: Data?
    let fileMimeType: String?
    
    init(fileApiParamKey: String, fileName: String, fileData: Data) {
        self.init(fileApiParamKey: fileApiParamKey, fileName: fileName, fileData: fileData, fileMimeType: fileData.mimeType)
    }
    
    init(fileApiParamKey: String, fileName: String, fileData: Data, fileMimeType: String) {
        self.fileApiParamKey = fileApiParamKey
        self.fileName = fileName
        self.fileData = fileData
        self.fileMimeType = fileMimeType
    }
}


class APIManagerMultiPartFileRequest {
    
    public var request : URLRequest!
    public var hashBody: Data?
    
    init(_ requestURLString: String,
                paramters: Parameters,
                mediaFiles: [APIManagerMediaFile],
                header: String,
                authorizationValue: String?,
                rootKJSONParamsKey: String?
        ) {
        
        guard let finalURL = URL(string: requestURLString) else { return }
        request = URLRequest(url: finalURL)
        request.httpMethod = HttpMethod.post.rawValue
        let boundary = generateBoundary()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request?.httpBody = createMultipartDataBody(withParameters: paramters, mediaFiles: mediaFiles, boundary: boundary, rootKJSONParamsKey: rootKJSONParamsKey)
        
        request.setValue(paramters.makeSHA256(headerKey: header), forHTTPHeaderField: "X-Hash")
        request.addValue("close", forHTTPHeaderField: "Connection")
        if let authValue = authorizationValue {
            request.addValue(authValue, forHTTPHeaderField: "Authorization")
        }
    }
    
    private func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    private func createMultipartDataBody(withParameters params: Parameters?, mediaFiles: [APIManagerMediaFile], boundary: String, rootKJSONParamsKey: String? ) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        
        if let rootJSONKey = rootKJSONParamsKey, rootJSONKey.count > 0 {
            if let parameters = params {
                body.append(string:"--\(boundary + lineBreak)")
                body.append(string:"Content-Disposition: form-data; name=\"\(rootJSONKey)\"\(lineBreak + lineBreak)")
                body.append(string:"\(parameters.toJSONString().convertBase64WithRandomCharacters() + lineBreak)")
            }
        } else {
            if let parameters = params {
                for (key, value) in parameters {
                    body.append(string:"--\(boundary + lineBreak)")
                    body.append(string:"Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                    body.append(string:"\(String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? "" + lineBreak)")
                }
            }
        }
        
        hashBody = body
        
        for fileDetail in mediaFiles {
            if let parameterKey = fileDetail.fileApiParamKey, let fileName = fileDetail.fileName, let fileData = fileDetail.fileData, let fileMimeType = fileDetail.fileMimeType, fileData.count > 0 {
                body.append(string:"--\(boundary + lineBreak)")
                body.append(string:"Content-Disposition: form-data; name=\"\(parameterKey)\"; filename=\"\(fileName)\"\(lineBreak)")
                body.append(string:"Content-Type: \(fileMimeType + lineBreak + lineBreak)")
                body.append(fileData)
                body.append(string:lineBreak)
            }
        }
        
        body.append(string:"--\(boundary)--\(lineBreak)")
        
        return body
    }
}
