//
//  DataArray.swift
//  SixFeet
//
//  Created by Bobo Qiu on 6/28/20.
//  Copyright © 2020 Bobo Qiu. All rights reserved.
//

import Foundation

class DataArray: NSObject {
    
    private var locationData = [String]()
    
    func addData(data: String){  //data is kept sorted by a binary sort/insert algorithm
        var max = locationData.count
        var min = 0
        var done = false
        while !done{
            if min + 1 >= max {
                if max != 0 && data > locationData[min]{min += 1}
                locationData.insert(data, at: min)
                done = true
            }else{
                let middle = (max + min) / 2
                let middleString = locationData[middle]
                if data == middleString{done = true}
                if data > middleString{min = middle}
                else{max = middle}
            }
        }
    }

    func translate() -> String{
        var sub = ""
        for n in locationData{sub = sub + n + "\n"}
        return sub
    }
    
    func clear(){
        locationData.removeAll()
    }
    
    func getDay() -> Int{ //this assumes the first character of data is the day
        if locationData.count > 0 {
            return Int(String((locationData[0].first!)))!
        }else{return 0}
    }
    
    func getLength() -> Int{
        return locationData.count
    }
    
    func get(index: Int) -> String{
        return locationData[index]
    }
}

extension Date {
    func dayNumberOfWeek() -> Int! {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }
    
    func formattedDate() -> String!{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "#"+formatter.string(from: self)
    }
}
