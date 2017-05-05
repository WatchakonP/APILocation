//
//  ViewController.swift
//  APIlocation
//
//  Created by Watcha Pon on 4/29/17.
//  Copyright © 2017 Indie Co. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON
import FBSDKCoreKit
import FBSDKLoginKit
import FacebookLogin
import FacebookCore

class ViewController: UIViewController {
    
    @IBOutlet weak var textBox: UITextField!
    @IBOutlet weak var greetLabel: UILabel!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var hideLabel: UILabel!
    @IBOutlet weak var hostLabel: UILabel!
    @IBOutlet weak var ipLabel: UILabel!
    
    @IBAction func buttonPressed(_ sender: Any) {
        var input = ""
        if (textBox.text != nil) {
            input = textBox.text!
        }else { return }

        self.hideLabel.text = ""
        getJSON(ipString: input)
    }
    func getJSON(ipString : String){
        //    let urlPrefix = "http://geo.groupkt.com/ip/"
        //    let urlSuffix = "/json"
        let urlPrefix = "https://tools.keycdn.com/geo.json?host="
        let conString = urlPrefix + ipString
        let url = NSURL(string: conString)
        URLSession.shared.dataTask(with: (url as? URL)!, completionHandler: {(data, response, error) -> Void in
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
                print(jsonObject!)
                let json = JSON(jsonObject!)
                if let status = json["status"].string{
                    print(status)
                    if(status == "success"){
                        self.updateMapView(jsonData: json)
                    }
                    else{ //show error here
                        self.hideLabel.text = "Invalid URL or IP. Try Again!"
                    }
                }
            }
        }).resume()
    }
    
    func checkIsIP(passString : String) -> Bool{
        let digits = CharacterSet.decimalDigits
        var digitCount = 0
        for uni in passString.unicodeScalars {
            if digits.contains(uni){
                digitCount += 1
            }
        }
        print("DigitCount : ",digitCount)
        if(digitCount > 3){ //ip has at least 4 number
            return true
        }
        else {return false}
    }
    
    func returnIP(passString : String){
        let host = CFHostCreateWithName(nil, passString as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
            let theAddress = addresses.firstObject as? NSData {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let numAddress = String(cString: hostname)
                print(numAddress)
                getJSON(ipString: numAddress)
            }
        } else{ print("Check your URL/IP again!")}
    }
    
    func updateMapView(jsonData : JSON){
        var lat : Double = 0.0
        var lon : Double = 0.0
        if let json = jsonData["data"]["geo"]["host"].string{
            hostLabel.text = "Host: " + json
        }
        if let json = jsonData["data"]["geo"]["ip"].string{
            ipLabel.text = "IP: " + json
        }
        if let json = jsonData["data"]["geo"]["latitude"].string{
            lat = Double(json)!
        }
        if let json = jsonData["data"]["geo"]["longitude"].string{
            lon = Double(json)!
        }
        let location = CLLocationCoordinate2DMake(lat,lon)
        print(location)
        let span = MKCoordinateSpanMake(0.3,0.3)
        let region = MKCoordinateRegion(center: location, span: span)
        map.setRegion(region, animated: true)
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = location
        if let json = jsonData["data"]["geo"]["country_name"].string{
            dropPin.title = json
        }
        if let json = jsonData["data"]["geo"]["city"].string{
            dropPin.subtitle = json
        }
        map.addAnnotation(dropPin)
    }
    
    func facebookLogin(){
        let myLoginButton = UIButton(type: .custom)
        myLoginButton.backgroundColor = UIColor.darkGray
        myLoginButton.frame = CGRect(x: 0, y: 0, width: 180, height: 40)
        myLoginButton.center = view.center
//        myLoginButton.addTarget(self, action: @selector(self.loginButtonClicked), for: UIControlEvents.to)
        view.addSubview(myLoginButton)
    }
    @objc func loginButtonClicked(){
        let loginManager = LoginManager()
        loginManager.logIn([.publicProfile],viewController: self) { loginResult in
            switch loginResult{
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(grantedPermissions: _, declinedPermissions: _, token: _):
                print("Logged in!")
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
