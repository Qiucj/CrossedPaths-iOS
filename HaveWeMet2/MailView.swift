//
//  MailView.swift
//  SixFeet
//
//  Created by Bobo Qiu on 6/28/20.
//  Copyright © 2020 Bobo Qiu. All rights reserved.
//

import SwiftUI
import UIKit
import MessageUI

struct MailView: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentation
    @Binding var result: Result<MFMailComposeResult, Error>?
    var inputURL : URL
    var emailGovernor : Bool
    var contactSixFeet : Bool
    var emailAdr : String
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate{
        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?
        
        init(presentation: Binding<PresentationMode>,
             result: Binding<Result<MFMailComposeResult, Error>?>){
            _presentation = presentation
            _result = result
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {$presentation.wrappedValue.dismiss()}
            guard error == nil else{
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation, result: $result)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController{
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        if (emailGovernor){
            vc.setToRecipients(["governorsoffice@michigan.gov"])
            vc.setSubject(CONSTANTS.subject)
            vc.setMessageBody(CONSTANTS.letter, isHTML: false)
        }else if let myData = NSData(contentsOf: inputURL){
            if !self.contactSixFeet { vc.addAttachmentData(myData as Data, mimeType: "data/txt", fileName: "send.txt") }
            vc.setToRecipients([emailAdr])
            if !self.contactSixFeet { vc.setSubject("Confirmed") }
            else { vc.setSubject("Contact Us") }
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {
    }
}

