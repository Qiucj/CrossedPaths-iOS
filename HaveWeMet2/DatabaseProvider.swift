//
//  DatabaseProvider.swift
//  PrivateTrac
//
//  Created by Bobo Qiu on 7/13/20.
//  Copyright © 2020 Bobo Qiu. All rights reserved.
//

import Foundation

class DatabaseProvider: NSObject, ObservableObject{
    // Confirmed patients hashed timestamped location are stored online using 7 files.
    // Their https address are captured in LINKS[1...7]. The file in LINKS[0] is a
    // short message to be displayed on user's phone when it checks with database.
    // When allfiles are downloaded and checked with user's hased timestamped location
    // "allDaysChecked" are set to true to prompt UI to display the result
    
    @Published public var allDaysChecked = false
    @Published public var downloading = false
    private var daysChecked = 0;
    public var numOverlapped = 0;
    public var numSurfaceOverlapped = 0;
    public var message = "";
    private var localMessage = "";
    
    public func reset(){
        allDaysChecked = false;
        downloading = false;
        message = "";
    }
    
    public func downLoadFile(links: [String]){
        downloading = true
        allDaysChecked = false;
        daysChecked = 0;
        numOverlapped = 0;
        numSurfaceOverlapped = 0;
        let fileService = FileService()
        for i in 0...7{
            let url = URL(string: links[i])!
            let thisLoopNum = i;
            let task = URLSession.shared.dataTask(with: url){data, response, error in
                if let error = error {
                    self.message = "URL error \(error). \n Try turn off wifi and use data instead"
                    self.downloading = false
                    self.allDaysChecked = true
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode)else{
                    self.message = "http error \n Use https\\ please."
                    self.downloading = false
                    self.allDaysChecked = true
                    return
                }
                if let data = data,
                    let string = String(data: data, encoding: .utf8){
                    DispatchQueue.main.async {
                        self.daysChecked += 1
                        if(thisLoopNum == 0) {self.localMessage = string;}//display message from database  // I am assuming local message is the send.txt file as a string
                        else{
                            let dayString = fileService.getText(fromFile: CONSTANTS.CONCERNEDLITERAL + "\(thisLoopNum)")
                            self.checkResults(string, with: dayString, surface: false)
                            let surfaceStr = fileService.getText(fromFile: CONSTANTS.SURFACELITERAL + "\(thisLoopNum)")
                            self.checkResults(string, with: surfaceStr, surface: true)
                        }
                        if(self.daysChecked == 8) {
                            if (self.numOverlapped != 0 || self.numSurfaceOverlapped != 0){
                                self.message += "⚠️ \(self.numOverlapped) Potential overlaps.\n"
                                self.message += "\(self.numSurfaceOverlapped) Potential touching common surfaces"
                            }else {
                                self.message += "😄 No Suspected Overlaps.\n"
                            }
                            let groupStrs = self.localMessage.split(whereSeparator: \.isNewline)//new
                            if Int(groupStrs[0]) ?? 0 <= self.numOverlapped {//
                                for c in 1..<groupStrs.count {//
                                    self.message = self.message + "" + groupStrs[c]//
                                }//
                            }//
                            self.message += "\n\n" + "(Tap to dismiss)"
                            self.allDaysChecked = true
                            self.downloading = false
                        }
                    }
                }
            }
            task.resume()
        }
    }
        
    // Compare two sorted strings, increase numOverlapped by 1 each time matching string is found
    private func checkResults(_ str1 : String, with str2:String, surface:Bool){
        let strs1 = str1.split(whereSeparator: \.isNewline)
        let strs2 = str2.split(whereSeparator: \.isNewline)
        let strs1Count = strs1.count
        let strs2Count = strs2.count
        if(strs1Count > 0 && strs2Count > 0 && strs1[0] == strs2[0]/*first enttry is date, required to match*/){
            var index1 = 1
            var index2 = 1
            while(index1 < strs1Count && index2 < strs2Count){
                if(strs1[index1] == strs2[index2]){
                    if surface { numSurfaceOverlapped += 1}
                    else {numOverlapped += 1}
                    index1 += 1
                    index2 += 1
                }else if (strs1[index1] < strs2[index2]){index1 += 1}
                else{index2 += 1}
            }
            if(index1 < strs1Count){
                let line2 = strs2[index2-1]
                for i in index1 ..< strs1Count {
                    if(strs1[i] == line2){
                        if surface {self.numSurfaceOverlapped += 1}
                        else {self.numOverlapped += 1}
                    }else if(strs1[i] > line2){break}
                }
            }else if(index2 < strs2Count){
                let line1 = strs1[index1-1]
                for i in index2 ..< strs2Count {
                    if(line1 == strs2[i]){
                        if surface {self.numSurfaceOverlapped += 1}
                        else {self.numOverlapped += 1}
                    }else if(strs2[i] > line1){break}
                }
            }
        }
    }
}

