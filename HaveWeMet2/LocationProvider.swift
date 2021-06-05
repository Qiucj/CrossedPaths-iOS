//
//  LocationProvider.swift
//  SixFeet
//
//  Created by Bobo Qiu on 6/28/20.
//  Copyright © 2020 Bobo Qiu. All rights reserved.
//

import Foundation
import CoreLocation
import CommonCrypto
import UIKit
import UserNotifications

class LocationProvider: NSObject, CLLocationManagerDelegate, ObservableObject{
    private let locationManager = CLLocationManager()
    var location : CLLocation? = nil
    private let updateInterval = 100000 // 100 seconds
    var prevTime = Date().toMillis()!   // last update time in millseconds
    @Published public var isUpdating = false  //prompt UI to enable/disable update/removeUpdate button
    
    let concernedArray = DataArray()
    let confirmedArray = DataArray()
    let surfaceArray   = DataArray()
    var fileService : FileService
    var groupServer : GroupManager
    
    init(groupManager : GroupManager, fileManager : FileService){
        fileService = fileManager
        groupServer = groupManager
        super.init()
        locationManager.delegate = self
        //locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge]){success, error in
            if success {print ("All set")}
            else if let error = error{print(error.localizedDescription)}
        }
    }
    
    func startUpdating(){
        // load today's data into memory. It is necessary to keep today's data sorted
        let today = Date().dayNumberOfWeek()!
        fileService.loadArray(fromFile: CONSTANTS.CONCERNEDLITERAL + "\(today)", toArray: concernedArray)
        fileService.loadArray(fromFile: CONSTANTS.CONFIRMEDLITERAL + "\(today)", toArray: confirmedArray)
        fileService.loadArray(fromFile: CONSTANTS.SURFACELITERAL   + "\(today)", toArray: surfaceArray)
        locationManager.startUpdatingLocation()
        isUpdating = true
        print("Start updating")
    }
    
    func stopUpdating(){
        locationManager.stopUpdatingLocation()
        isUpdating = false
        
        // clear memory to minimize memory usage
        confirmedArray.clear()
        concernedArray.clear()
        surfaceArray.clear()
    }
    
    func clearHistory(){
        fileService.clearFiles()    //delete all data stored in files
        confirmedArray.clear()      //delete all data stored in memory
        surfaceArray.clear()
        concernedArray.clear()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let time = Date()
        let milliSeconds = time.toMillis()!
        //only switch to best accuracy before accurate location needed to save battery
        if(prevTime+updateInterval < milliSeconds + updateInterval/4){ locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation}
        
        if prevTime + updateInterval < milliSeconds, let location = locations.last{
            let today = time.dayNumberOfWeek()!
            
            //start new sorted data every day.
            if today != concernedArray.getDay() {
                concernedArray.clear()
                confirmedArray.clear()
                surfaceArray.clear()
            }
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            var prefix = "0"
            if groupServer.getSelectedGroup().inRange(lati: lat, longi: lon, time: time){
                prefix = String(groupServer.getSelectedGroupChar())
            }
            let hundredSeconds = Int(milliSeconds / 100000 + 23579)             //23579 is for encryption to throw hackers off
            let mLatitude = Int((lat+191.0)*10000)     //only accuracy down to 4th decimal point needed
            let mLongitude = Int((lon+281.0)*10000)   //same as above
            let hashedString = String(today)+hashTimeLocation(timeIn100s: hundredSeconds, modifiedLat: mLatitude, modifiedLong: mLongitude)
            confirmedArray.addData(data: prefix+hashedString)
            concernedArray.addData(data: hashedString)
            for i in 1...9{ //also store data for previous 20 minutes to capture exposure through aerosol, surface contamination
                surfaceArray.addData(data: String(today)+hashTimeLocation(timeIn100s: hundredSeconds-i, modifiedLat: mLatitude, modifiedLong: mLongitude))
            }
            fileService.updateData(concernedArray: concernedArray, confirmedArray: confirmedArray, surface: surfaceArray, today: today)
            
            prevTime = milliSeconds                                             //reset time
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters  //turn to low battery mode
   
            let content = UNMutableNotificationContent()
            content.title = "Digital signature created from location/time. Using battery."
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func hashTimeLocation(timeIn100s time:Int, modifiedLat lati:Int, modifiedLong longi:Int) -> String{
        let lastDigLati = (lati%10)/2
        let lastDigLongi = ((longi)%10)/2
        let latit = (lati/10)*10 + lastDigLati
        let longit = (longi/10)*10 + lastDigLongi
        let code =  String(latit) + String(longit) + String(latit%100000) + String(longit%100000) + String(latit%10000) + String(longit%10000) + String(time) + String(latit%1000) +                String(longit%1000) + String(latit%100)  + String(longit%100) + String(lastDigLati) + String(lastDigLongi)
        return code.sha256();
    }
}

extension Date{
    func toMillis()->Int!{return Int(self.timeIntervalSince1970 * 1000)}
}

extension String{
    func sha256() -> String {
          if let strData = self.data(using: String.Encoding.utf8) {
              /// #define CC_SHA256_DIGEST_LENGTH     32
              /// Creates an array of unsigned 8 bit integers that contains 32 zeros
              var digest = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
       
              /// CC_SHA256 performs digest calculation and places the result in the caller-supplied buffer for digest (md)
              /// Takes the strData referenced value (const unsigned char *d) and hashes it into a reference to the digest parameter.
              strData.withUnsafeBytes {
                  // CommonCrypto
                  // extern unsigned char *CC_SHA256(const void *data, CC_LONG len, unsigned char *md)  -|
                  // OpenSSL                                                                             |
                  // unsigned char *SHA256(const unsigned char *d, size_t n, unsigned char *md)        <-|
                  CC_SHA256($0.baseAddress, UInt32(strData.count), &digest)
              }
       
              var sha256String = ""
              /// Unpack each byte in the digest array and add them to the sha256String
            /*
              for byte in digest {
                  sha256String += String(format:"%02x", UInt8(byte))
              }
             */
            for i in 0..<digest.count/3 {
                let byte: UInt8 = digest[i*3]
                let sixBit = byte >> 2
                sha256String += String(Character(UnicodeScalar(sixBit + 48)))
                let secondByte: UInt8 = digest[i*3 + 1]
                let secondSixBit = (byte << 6) >> 2 | secondByte >> 4
                sha256String += String(Character(UnicodeScalar(secondSixBit + 48)))
                let thirdByte: UInt8 = digest[i*3 + 2]
                let thirdSixBit = (secondByte << 4) >> 2 | thirdByte >> 6
                sha256String += String(Character(UnicodeScalar(thirdSixBit + 48)))
                let fourthSixBit = (thirdByte << 2) >> 2
                sha256String += String(Character(UnicodeScalar(fourthSixBit + 48)))
            }
            let byte: UInt8 = digest[digest.count - 2]
            let secondByte: UInt8 = digest[digest.count - 1]
            let sixBit = byte >> 2
            sha256String += String(Character(UnicodeScalar(sixBit + 48)))
            let secondSixBit = (byte << 6) >> 2 | secondByte >> 4
            sha256String += String(Character(UnicodeScalar(secondSixBit + 48)))
            let thirdSixBit = (secondByte << 4) >> 4
            sha256String += String(Character(UnicodeScalar(thirdSixBit + 48)))
            return sha256String
          }
          return ""
      }
}
