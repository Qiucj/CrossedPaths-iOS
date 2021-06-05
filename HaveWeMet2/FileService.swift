//
//  FileService.swift
//  SixFeet
//
//  Created by Bobo Qiu on 6/28/20.
//  Copyright © 2020 Bobo Qiu. All rights reserved.
//

import Foundation

struct FileService {
    private let sendFileName = "sent"
    private let fileDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    
    func prepareShareURL (global : Bool, selectChar : Character) ->URL{
        var combinedText = ""
        for i in 1...7 {
            if global || selectChar.asciiValue == 48 {
                combinedText += getTextNot1stChar(from: CONSTANTS.CONFIRMEDLITERAL + "\(i)")
            }else {
                combinedText += getSelectTextNot1stChar(from: CONSTANTS.CONFIRMEDLITERAL + "\(i)", selectChar: selectChar)
            }
        }
        saveFile(to: sendFileName, using: combinedText)
        return fileDirURL.appendingPathComponent(sendFileName).appendingPathExtension("txt")
    }
    
    func getSelectTextNot1stChar(from name: String, selectChar : Character) -> String{
        let fileURL = fileDirURL.appendingPathComponent(name).appendingPathExtension("txt")
        var returnStr = ""
        do{
            let content = try String(contentsOf:fileURL, encoding: String.Encoding.utf8)
            let lines = content.split(whereSeparator: \.isNewline)
            returnStr = lines[0] + "\n"
            for i in 1..<lines.count {
                var thisLine = lines[i]
                if thisLine[thisLine.startIndex] == selectChar {
                    thisLine.remove(at: thisLine.startIndex)
                    returnStr += String(thisLine) + "\n"
                }
            }
        }catch{print("File did not load")}
        return returnStr
    }
    
    func getTextNot1stChar(from name: String) -> String{
        let fileURL = fileDirURL.appendingPathComponent(name).appendingPathExtension("txt")
        let sortArr = DataArray()
        do{
            let content = try String(contentsOf:fileURL, encoding: String.Encoding.utf8)
            let lines = content.split(whereSeparator: \.isNewline)
            for i in 1..<lines.count {
                var thisLine = lines[i]
                thisLine.remove(at: thisLine.startIndex)
                sortArr.addData(data: String(thisLine))
            }
            return lines[0] + "\n" + sortArr.translate()
        }catch{
            print("File did not load")
            return ""
        }
    }
    
    func updateData(concernedArray concerned: DataArray, confirmedArray confirmed: DataArray, surface: DataArray, today day: Int){
        saveFile(to: CONSTANTS.CONCERNEDLITERAL + "\(day)", using: concerned.translate())
        saveFile(to: CONSTANTS.SURFACELITERAL + "\(day)", using: surface.translate())
        saveFile(to: CONSTANTS.CONFIRMEDLITERAL + "\(day)", using: confirmed.translate())
    }
    
    func clearFiles(){
        for i in 1...7 {
            saveFile(to: CONSTANTS.CONCERNEDLITERAL + "\(i)", using: "")
            saveFile(to: CONSTANTS.CONFIRMEDLITERAL + "\(i)", using: "")
            saveFile(to: CONSTANTS.SURFACELITERAL + "\(i)", using: "")
            saveFile(to: sendFileName, using: "")
        }
    }
    
    func saveFile(to name: String, using text: String){
        let fileURL = fileDirURL.appendingPathComponent(name).appendingPathExtension("txt")
        let writeString = Date().formattedDate() + "\n" + text  //first line is today's date
        do{
            try writeString.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        }catch let error as NSError{
            print("Failed to write url " + name)
            print(error)
        }
    }
    
    func loadArray(fromFile name: String, toArray myArray: DataArray){
        let fileURL = fileDirURL.appendingPathComponent(name).appendingPathExtension("txt")
        do{
            let content = try String(contentsOf:fileURL, encoding: String.Encoding.utf8)
            let lines = content.split(whereSeparator: \.isNewline)
            if String(lines[0]) == Date().formattedDate(){  //only load if data in file is from today
                for i in 1..<lines.count {
                    myArray.addData(data: String(lines[i]))
                }
            }
        }catch{print("File did not load")}
    }
    
    func getText(fromFile name:String)->String{
        let fileURL = fileDirURL.appendingPathComponent(name).appendingPathExtension("txt")
        do{
            let readString = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
            return readString
        }catch{
            print("Failed to open file " + name)
            return ""
        }
    }
}
