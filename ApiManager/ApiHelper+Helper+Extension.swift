//
//  Created by Prashant Dabhi on 08/01/19.
//  Copyright © 2019 Prashant Dabhi. All rights reserved.
//

import UIKit
import CommonCrypto

public typealias Parameters = [String: Any]
//public typealias SimpleClickHandler = (() -> Void)

public enum HttpMethod : String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}


extension Data {
    mutating func append(string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
    
    func toUTF8String() -> String {
        return String(data: self, encoding: .utf8) ?? ""
    }
    
    func printUTF8() {
        print("----- Data String UTF8 -----")
        print(self.toUTF8String())
    }
    
    func makeSHA256(header key: String) -> String {
        guard let jsonData = try? JSONSerialization.jsonObject(with: self, options: .allowFragments),
            let jsonObject = jsonData as? Parameters else {
                //fatalError("Wrong Json")
                return ""
        }
        
        return jsonObject.makeSHA256(headerKey: key)
    } 
}

extension Data {
    private static let mimeTypeSignatures: [UInt8 : String] = [
        0xFF : "image/jpeg",
        0x89 : "image/png",
        0x47 : "image/gif",
        0x49 : "image/tiff",
        0x4D : "image/tiff",
        0x25 : "application/pdf",
        0xD0 : "application/vnd",
        0x46 : "text/plain",
        ]
    
    var mimeType: String {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return Data.mimeTypeSignatures[c] ?? "application/octet-stream"
    }
}

extension APIManager {
    func mergeCommonParameters(_ param : Parameters, apiManagerProperties: APIManagerPropertySet) -> Parameters {
        var returnValue : Parameters = apiManagerProperties.getProperty(of: APIManagerProperty.commonParameters, parsingType: Parameters.self) ?? Parameters()
        returnValue.merge(dict: param)
        return returnValue
    }
}

extension URLResponse {
    var httpStatusCode: Int? {
        return (self as? HTTPURLResponse)?.statusCode
    }
    
    func printFailureLogs() {
        print("----- Failure Request Logs-----")
        print("Request URL: \(String(describing: self.url))")
        print("Code: \(self.httpStatusCode ?? 0)")
        print("----------")
    }
}

extension String {
    func ccSha256(header key: String) -> String{
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), key, key.count, self, self.count, &digest)
        let data = Data(bytes: digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
    
    func convertBase64WithRandomCharacters() -> String {
        let base64String = find10Character() + self.toBase64() + find10Character()
        return base64String.toBase64()
    }
    
    func parseFromBase64WithRandomCharacters() -> String? {
        let decodedBase64String: String = String(self.base64Decoded()?.dropFirst(10).dropLast(10) ?? "")
        return decodedBase64String.base64Decoded()
        
    }
    
    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    fileprivate func find10Character() -> String {
        let chars1 = "qwe=rtyui=op!lm@n=b#vcxz%=as^dfg&hj=k*lQWE=RTYUIOPL=MNBVCX=ZASDFG=HJKL12=3456=7=89"
        let array = Array(chars1)
        var finalString = String()
        for _ in 0..<10 {
            let randomChar = array.randomElement()
            finalString.append(randomChar!)
        }
        return finalString
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    
    func toParameters() -> Parameters? {
        if let data = self.data(using: .utf8, allowLossyConversion: true),
            let params = try? JSONSerialization.jsonObject(with: data, options: []) as? Parameters {
            return params
        }
        
        return nil
    }
}

extension Dictionary {
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
    
    func toJSONString() -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []),
            let jsonString = String.init(data: jsonData, encoding: .utf8) {
            
            return jsonString
        }
        
        return ""
    }
    
    func makeSHA256(headerKey key: String) -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []),
            let jsonString = String.init(data: jsonData, encoding: .utf8) else {
                //fatalError("Wrong Json")
                return ""
        }
        
        print("----- SHA256 START -----")
        print("----- BODY -----")
        print(jsonString.filter { !"\n\t\r".contains($0) })
        let json256 = jsonString.filter { !"\n\t\r".contains($0) }.ccSha256(header: key)
        print("----- BODY ccSha256 -----")
        print(json256)
        print("----- SHA256 END -----")
        return json256
    }
    
    func getQueryString() -> String {
        var data = [String]()
        for(key, value) in self {
            data.append(String(describing: key) + "=\(String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? "")")
        }
        return data.map { String($0) }.joined(separator: "&")
    }
}

extension Dictionary where Key == APIManagerProperty, Value == Any? {
    
    func getProperty<T>(of propertyKey: APIManagerProperty, parsingType: T.Type) -> T? {
        
        switch propertyKey {
        case .commonParameters:
            return self[propertyKey] as? T
        case .headerKey:
            return self[propertyKey] as? T
        case .jsonParameterRootKey:
            return self[propertyKey] as? T
        case .authorizationValue:
            return self[propertyKey] as? T
        case .apiFailureRetryViewParent:
            return self[propertyKey] as? T
        case .apiFailureRetryView:
            return self[propertyKey] as? T
        case .shouldParformAPIWhenInternetResume:
            return self[propertyKey] as? T
        case .defaultContentType:
            return self[propertyKey] as? T
        case .shouldShowAPIFailureRetryView:
            return self[propertyKey] as? T
        case .shouldShowProgressHUD:
            return self[propertyKey] as? T
        case .progressHUDMessage:
            return self[propertyKey] as? T
        }
    }
    
    func overrideProperties(from newSet: APIManagerPropertySet?) -> APIManagerPropertySet {
        guard let newSet = newSet else {
            return self
        }
        var existingSet = self
        for set in newSet {
            existingSet[set.key] = set.value
        }
        
        return existingSet
    }
}

extension Collection {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index?) -> Element? {
        guard let index = index else { return nil }
        return indices.contains(index) ? self[index] : nil
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)
        
        return allowed
    }()
}


