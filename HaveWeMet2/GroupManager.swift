//
//  GroupManager.swift
//  HaveWeMet
//
//  Created by Bobo Qiu on 7/23/20.
//  Copyright © 2020 Caleb Qiu. All rights reserved.
//

import Foundation

class GroupManager: ObservableObject{
    var file : FileService
    private let fileName = "Group"
    public var downloadStr = ""
    private var downloadOK = false
    @Published public var groupChanged = false
    @Published public var downloading = false
    @Published public var groupSelectionChanged = false
    private var groupSelected = 0
    public var groupArr : [GroupItem]=[]
    public var groupNum = 0
    public var message = ""
    private let defaultStr = "0NAon Earth \n0EMhavewemetapp@gmail.com\n0LKhttps://drive.google.com/uc?id=1ICW6_uRRfLDw-04LM5Ode0RSRNKrLR6g&export=download\n0LKhttps://drive.google.com/uc?id=1No0ApuDL9njzxefPNKguH9kp7OHmibV6&export=download\n0LKhttps://drive.google.com/uc?id=1xE7yEZAOkABnRNQhSek25EQoFZp_v2f_&export=download\n0LKhttps://drive.google.com/uc?id=1NYNo5nD9e0suubkSCa7d61Yvz_cBLSF2&export=download\n0LKhttps://drive.google.com/uc?id=1tgWgIKD_jP3dtyAjpbEmb-ANiI6ZqXCu&export=download\n0LKhttps://drive.google.com/uc?id=1xhPMgVWhMMlU7gL4Oy7WCkl7fzEu2cmq&export=download\n0LKhttps://drive.google.com/uc?id=1LeqsHl6P5jqpHI0UyHlKQz5bHAxOmF0s&export=download\n0LKhttps://drive.google.com/uc?id=1uLFMlbKLO3-eZPla6BDkhV-B4woxYeLj&export=download\n0LI 0, 0, 25000000\n0LX 0, 0, 0\n0TI 0, 0, 0, 23, 59, 59 \n0PPhttps://drive.google.com/file/d/1L7fi7zBiGUO2YhqpHYJeP3I6KEYOQes7/view?usp=sharing\n"
    
    func setSelectedGroup(numSelected : Int){
        if (numSelected < groupArr.count){
            groupSelected = numSelected
        }else {
            groupSelected = 0
        }
        self.groupSelectionChanged = !self.groupSelectionChanged
    }
    
    func getSelectedGroup() -> GroupItem{
        return groupArr[groupSelected]
    }
    
    func getSelectedGroupChar() -> Character{
        return intIntoChar(int: groupSelected)
    }
    
    func getSelectedGroupNum() -> Int {
        return self.groupSelected
    }
    
    public func reset(){
        downloading = false;
        message = "";
    }
    
    func writeGroup(){
        if(downloadOK){
            file.saveFile(to: fileName, using: defaultStr+downloadStr)
        }else{
            file.saveFile(to: fileName, using: defaultStr)
        }
    }
    
    init(fileManager : FileService){
        file = fileManager
        let fileStr = file.getText(fromFile: fileName)
        if fileStr == "" {
            writeGroup()
            readGroup()
        }else{
            readGroup()
        }
    }
    
    private func intIntoChar(int value : Int) -> Character{
        let u = UnicodeScalar(value+48)
        return Character(u!)
    }
    
    private func readGroup(){
        groupArr.removeAll()
        let fileStr = file.getText(fromFile: fileName)
        let groupStrs = fileStr.split(whereSeparator: \.isNewline)
        var nameFound = false
        var name = ""
        var emailFound = false
        var email = ""
        var links : [String] = []
        var centerLat : [Double] = []
        var centerLon : [Double] = []
        var radius :[Double] = []
        var exLat : [Double] = []
        var exLon : [Double] = []
        var exRadius :[Double] = []
        var timeStart :[Int] = []
        var timeEnd :[Int] = []
        var policyFound = false
        var policy = ""
        var groupsFound = 0
        var wrongFormat = false
        
        for i in 1..<groupStrs.count {
            let thisLine = groupStrs[i]
            if thisLine[thisLine.startIndex] == intIntoChar(int: groupsFound) {
                let startIndex = thisLine.index(thisLine.startIndex, offsetBy:1)
                let endIndex = thisLine.index(thisLine.startIndex, offsetBy:3)
                let indicator = thisLine[startIndex..<endIndex]
                switch indicator {
                case "PP":
                    policyFound = true
                    policy = String(thisLine[endIndex..<thisLine.endIndex])
                case "NA" :
                    nameFound = true
                    name = String(thisLine[endIndex..<thisLine.endIndex])
                case "EM" :
                    emailFound = true
                    email = String(thisLine[endIndex..<thisLine.endIndex])
                case "LK" :
                    links.append(String(thisLine[endIndex..<thisLine.endIndex]))
                case "LI":
                    let numberLine = String(thisLine[endIndex..<thisLine.endIndex])
                    let numStrs = numberLine.components(separatedBy: ",")
                    if numStrs.count == 3 {
                        centerLat.append((numStrs[0] as NSString).doubleValue)
                        centerLon.append((numStrs[1] as NSString).doubleValue)
                        radius.append(   (numStrs[2] as NSString).doubleValue)
                    }else{
                        wrongFormat = true
                        break
                    }
                case "LX":
                    let numberLine = String(thisLine[endIndex..<thisLine.endIndex])
                    let numStrs = numberLine.components(separatedBy: ",")
                    if numStrs.count == 3 {
                        exLat.append(   (numStrs[0] as NSString).doubleValue)
                        exLon.append(   (numStrs[1] as NSString).doubleValue)
                        exRadius.append((numStrs[2] as NSString).doubleValue)
                    }else{
                        wrongFormat = true
                        break
                    }
                case "TI":
                    let numberLine = String(thisLine[endIndex..<thisLine.endIndex])
                    let numStrs = numberLine.components(separatedBy: ",")
                    if numStrs.count == 6 {
                        var seconds = 3600 * Int((numStrs[0] as NSString).intValue)
                        seconds += 60 * Int((numStrs[1] as NSString).intValue)
                        seconds += Int((numStrs[2] as NSString).intValue)
                        timeStart.append(seconds)
                        seconds = 3600 * Int((numStrs[3] as NSString).intValue)
                        seconds += 60 * Int((numStrs[4] as NSString).intValue)
                        seconds += Int((numStrs[5] as NSString).intValue)
                        timeEnd.append(seconds)
                    }else{
                        wrongFormat = true
                        break
                    }
                default :
                    wrongFormat = true
                    break
                }
            }else{
                if !wrongFormat && nameFound && emailFound && links.count == 8  && centerLat.count > 0 && timeStart.count > 0 && policyFound {
                    groupArr.append(GroupItem(name: name, email: email, links: links, centerLat: centerLat, centerLon: centerLon, radius: radius, exCenterLat: exLat, exCenterLon: exLon, exRadius: exRadius, startSecs: timeStart, endSecs: timeEnd, policy: policy, id: groupArr.count))
                    groupsFound += 1
                    nameFound = false
                    emailFound = false
                    policyFound = false
                    links = []
                    centerLat = []
                    centerLon = []
                    radius = []
                    exLat = []
                    exLon = []
                    exRadius = []
                    timeStart = []
                    timeEnd = []
                }else{
                    wrongFormat = true
                }
            }
            if (wrongFormat){
                groupArr = []
                break
            }
        }
        if !wrongFormat && nameFound && emailFound && links.count == 8  && centerLat.count > 0 && timeStart.count > 0 && policyFound {
            groupArr.append(GroupItem(name: name, email: email, links: links, centerLat: centerLat, centerLon: centerLon, radius: radius, exCenterLat: exLat, exCenterLon: exLon, exRadius: exRadius, startSecs: timeStart, endSecs: timeEnd, policy: policy, id: groupArr.count))
        }
        groupArr.append(GroupItem(name: "other...", email: "", links: CONSTANTS.LINKS, centerLat: [0.0], centerLon: [0.0], radius: [0.0], exCenterLat: [0.0], exCenterLon: [0.0], exRadius: [0.0], startSecs: [0], endSecs:[1], policy: "", id: groupArr.count))
        
        groupSelected = 0
        groupChanged = true
    }
        
    
    func inDistanceRange(lat: Double, lon: Double, range: Double, lats: [Double], lons: [Double]) -> Bool {
        var test1 = false
        var test2 = false
        for point in lats {
            if lat > point - range && lat < point + range {
                test1 = true
            }
        }
        if test1 {
            for point in lons {
                if lon > point - range && lon < point + range {
                    test2 = true
                }
            }
        }
        return test1&&test2
    }
    
    func downLoadGroup() {
        downloading = true
        let url = URL(string: "https://drive.google.com/uc?id=1gVxmvR2NipnzwRHszJVU5yq_eD4Xa21Q&export=download")
        let task = URLSession.shared.dataTask(with: url!){ data, response, error in
            if let error = error {
                self.message = " DOWNLOAD UNSUCCESSFUL \(error)" + " (Tap do Dismiss) "
                self.downloading = false
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode)else{
                self.message = " DOWNLOAD UNSUCCESSFUL" + "http error (Tap to Dismiss) "
                self.downloading = false
                return
            }
            if let data = data, let string = String(data: data, encoding: .utf8){
                DispatchQueue.main.async {
                    self.groupChanged = false
                    self.message = " DOWNLOAD SUCCESSFUL (Tap to Dismiss) "
                    self.downloadStr = string
                    self.downloadOK = true
                    self.downloading = false
                    self.writeGroup()
                    self.readGroup()
                }
            }
        }
        task.resume()
    }
    
    struct GroupItem: Identifiable{
        let name: String
        let email: String
        let links : [String]
        let centerLat : [Double]
        let centerLon : [Double]
        let radius : [Double]
        let exCenterLat : [Double]
        let exCenterLon : [Double]
        let exRadius: [Double]
        let startSecs : [Int]
        let endSecs:[Int]
        let policy : String
        
        var id: Int
        
        private func dBetween(latiA: Double, longiA: Double, latiB: Double, longiB: Double) ->Double {
            let r = 6371000.0
            let fi1 = latiA * Double.pi / 180.0
            let fi2 = latiB * Double.pi / 180.0
            let deltaFi = fi2-fi1
            let deltaLd = (longiB - longiA) * Double.pi / 180
            let a = sin(deltaFi/2) * sin(deltaFi/2) + cos(fi1) * cos(fi2) * sin(deltaLd/2) * sin(deltaLd/2)
            let c = 2 * atan2(sqrt(a), sqrt(1-a))
            return r * c
        }
        
        public func inRange(lati: Double, longi: Double, time : Date) -> Bool {
            let hour = Calendar.current.component(.hour, from: time)
            let minute = Calendar.current.component(.minute, from: time)
            let second = Calendar.current.component(.second, from: time)
            let secondsInDay = 3600*hour + 60*minute + second
            var timeInRange = false
            for c in 0..<startSecs.count {
                if secondsInDay > startSecs[c] && secondsInDay < endSecs[c] {
                    timeInRange = true
                    break
                }
            }
           
            if timeInRange {
                var locInRange = false
                for c in 0..<centerLat.count {
                    if radius[c] > dBetween(latiA: lati, longiA: longi, latiB: centerLat[c], longiB: centerLon[c]) {
                        locInRange = true
                        break
                    }
                }
                if(locInRange){
                    for c in 0..<exCenterLat.count {
                        if exRadius[c] > dBetween(latiA: lati, longiA: longi, latiB: exCenterLat[c], longiB: exCenterLon[c]) {
                            locInRange = false
                            break
                        }
                    }
                }
                return locInRange
            }
            return false
        }
    }
}
