//
//  ContentView.swift
//  HaveWeMet
//
//  Created by Caleb Qiu on 7/23/20.
//  Copyright © 2020 Caleb Qiu. All rights reserved.
//

import SwiftUI
import MessageUI
//Show on animated spinner
struct Loader: View {
    @State var animate = false
    
    var body : some View {
        VStack{
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(AngularGradient(gradient: .init(colors: [.red, .orange]), center: .center), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 35, height: 35)
                .rotationEffect(.init(degrees: self.animate ? 360 : 0))
                .animation(Animation.linear(duration: 0.7).repeatForever(autoreverses: false))
            
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(15)
        .onAppear{self.animate.toggle()}
    }
}

struct HaveWeMetView: View {
    @ObservedObject var group : GroupManager
    @ObservedObject var locMonitor: LocationProvider
    @ObservedObject var dataServer: DatabaseProvider = DatabaseProvider()
    
    @State private var showAbout = false
    @State private var showPolicy = false
    @State private var showExplain = false
    @State private var showSheet = false
    @State private var showInfoSheet = false
    @State private var groupPicked = 0
    @State private var showWithPassword = false
    @State private var showSendNormal = false
    @State private var emailSixFeet = false
    @State private var isShowingMailView = false
    @State private var emailGovernor = false
    @State private var alertNoMail = false
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State private var password: String = ""
    @State var showTerms   :Bool
    @State private var showGroupPassword = false
    @State var correctGroupPassword: Bool
    @State private var groupPassword: String = "" //What happens when the user presses the back arrow????
    @State private var showGroupPasswordButton = false

    var clearSheet: PopSheet{
        PopSheet(
            title: Text("Do you really want to clear all history?"),
            message: Text("History cleared is gone forever"),
            buttons: [
                .destructive(Text("Go ahead")){self.locMonitor.clearHistory()},
                .cancel()
            ]
        )
    }
    
    var infoSheet: PopSheet{
        PopSheet(
            title: Text("Select what you want to know."),
            buttons: [
                .default(Text("About"), action: {self.showAbout = true}),
                .default(Text("Privacy Policy"), action: {self.showPolicy = true}),
                .default(Text("Data Privacy Explanation"), action: {self.showExplain = true}),
                .cancel()
            ]
        )
    }

    var body: some View {
        ZStack{
            if !showTerms {
            NavigationView{
                GeometryReader { geometry in
                    NavigationLink(destination: self.aboutView, isActive: self.$showAbout){EmptyView()}
                    NavigationLink(destination: self.policyView, isActive: self.$showPolicy){EmptyView()}
                    NavigationLink(destination: self.explainView, isActive: self.$showExplain){EmptyView()}
                    NavigationLink(destination: self.sendNormalView, isActive: self.$showSendNormal){EmptyView()}
                    NavigationLink(destination: self.sendWithCodeView, isActive: self.$showWithPassword){EmptyView()}
                    NavigationLink(destination: self.groupPassWordView, isActive: self.$showGroupPassword){EmptyView()}
               
                    VStack{
                        if !self.group.downloading{
                            Form{
                                Picker(selection: self.$groupPicked, label: Text("@").font(.largeTitle)) {
                                    ForEach(0 ..< self.group.groupArr.count) {
                                        Text(self.group.groupArr[$0].name).font(.largeTitle)
                                    }
                                }.onReceive([self.groupPicked].publisher.first()) { value in
                                    if self.groupPicked != self.group.getSelectedGroupNum() {
                                        if self.groupPicked == 3 && !self.correctGroupPassword{
                                            self.groupPicked = 0
                                            self.showGroupPasswordButton = true
                                        }
                                        self.group.setSelectedGroup(numSelected: value)
                                    }
                                }
                            }
                        } else {
                            Loader()
                        }
                        
                        if self.showGroupPasswordButton {
                            Button(action: {
                                self.showGroupPassword = true
                            }){
                                Text("Your selected group is password protected. Press to enter your password").font(.title).padding(.bottom, 16)
                            }.onAppear(){
                                DispatchQueue.main.asyncAfter(deadline: .now() + 10){
                                    self.showGroupPasswordButton = false
                                }
                            }
                        }
                    
                        if self.group.getSelectedGroup().name == "other..." {
                            Button(action: {
                                self.group.downLoadGroup()
                                self.groupPicked = 0
                                self.group.setSelectedGroup(numSelected: self.groupPicked)
                            }){
                                Text("You picked other groups, please download").font(.title).padding(.bottom, 16)
                            }
                        }
                        
                        /*
                        if self.group.getSelectedGroup().name == "CompanyA" {
                            SecureField(" Enter " + self.group.getSelectedGroup().name + " Code", text: self.$password)
                                .background(Color(red: 150/255, green: 150/255, blue: 150/255))
                                .cornerRadius (29)
                                .frame (height: 70)
                                .font(.system(size: 30))
                                .foregroundColor(Color.white)
                            Spacer()
                        }
                         */
                    
                        Spacer()
    
                        if !self.group.downloading  && self.group.message != ""{
                            ScrollView{
                                Text(self.group.message).font(.title).lineLimit(nil).background(Rectangle().fill(self.dataServer.numOverlapped>0 ? Color.red : Color.green )).cornerRadius(10).padding()
                                    .onTapGesture {
                                        self.group.reset()
                                }
                            }.frame(minWidth: geometry.size.width, maxWidth: .infinity, minHeight: geometry.size.height/4)
                        }else{EmptyView()}
                    
                        Spacer()

                        //Title should be vertically followed by a Warning text that is only displayed when all files are downloaded from an    online database and compared to data stored on the device.
                        //This condition is satisfied when "allDaysChecked" is the dataServer var is set to true.
                        if self.dataServer.allDaysChecked  {
                            ScrollView{
                                Text(self.dataServer.message).font(.title).lineLimit(nil).background(Rectangle().fill(self.dataServer.numOverlapped>0 ? Color.red : Color.green )).cornerRadius(10).padding()
                                    .onTapGesture {
                                        self.dataServer.reset()
                                }
                            }.frame(minWidth: geometry.size.width, maxWidth: .infinity, minHeight: geometry.size.height/4)
                        }else{EmptyView()}
                

                        //Vertically followed by a button that start updating locations
                        Button(action:{self.locMonitor.startUpdating()}){
                            Text("Update Location for "+self.group.getSelectedGroup().name).padding()
                                .frame(minWidth: geometry.size.width, maxWidth: .infinity, minHeight: geometry.size.height/6)
                                .background(Rectangle().fill(Color.green))
                        }.disabled(self.locMonitor.isUpdating)
                    
                        //Vertically followed by a button that stops updating locations which should be the bottom of the screen
                        Button(action:{self.locMonitor.stopUpdating()}){
                            Text("Stop Updates").padding().frame(minWidth: geometry.size.width, maxWidth: .infinity, minHeight: geometry.size.height/6).background(Rectangle().fill(Color.yellow))
                        }.disabled(!self.locMonitor.isUpdating)
                    
                    } // end of VStack
                    .popSheet(isPresented: self.$showSheet, content: {self.showInfoSheet ? self.infoSheet : self.clearSheet})
                    .alert(isPresented: self.$alertNoMail){Alert(title: Text("NO MAIL SETUP"))}
                    .sheet(isPresented: self.$isShowingMailView){
                      MailView(result: self.$result,inputURL: self.locMonitor.fileService.prepareShareURL(global: false, selectChar: self.group.getSelectedGroupChar()),emailGovernor: self.emailGovernor, contactSixFeet: self.emailSixFeet, emailAdr: self.group.getSelectedGroup().email)
                    }
                }//end of Geometery reader
                .navigationBarTitle("CrossedPaths")
                .navigationBarItems(leading: controlView, trailing: iconView)
            }// end of NavigationView
            .navigationViewStyle(StackNavigationViewStyle())
            }else{
            ZStack{
                HStack{
                    Spacer()
                    VStack(alignment: .leading){
                        HStack{
                            Text("Terms and Conditions").font(.largeTitle).foregroundColor(.white)
                                .padding(.top, UIApplication.shared.windows.filter{$0 .isKeyWindow}.first?.safeAreaInsets.top).padding(10)
                            Spacer()
                        }
                        Spacer()
                        ScrollView {
                            Text(CONSTANTS.terms).foregroundColor(.white)//.system(size: 32, weight: .bold
                        }.padding(10)
                        HStack {
                            Spacer()
                            Button(action: {
                                self.showTerms = false
                                self.locMonitor.fileService.saveFile(to: "Agreement", using: "signed")
                            }){
                                Text("I Agree").foregroundColor(.yellow).font(.title)
                            }.padding(.top, UIApplication.shared.windows.filter{$0 .isKeyWindow}.first?.safeAreaInsets.top)
                            Spacer()
                        }.padding(.bottom)
                    }.padding(2)
                    Spacer()
                }
            }// end of ZStack
            .background(Color.blue).edgesIgnoringSafeArea(.all)
                .offset(x:0, y: self.showTerms ? 0 : UIApplication.shared.windows.filter{$0 .isKeyWindow}.first?.frame.height ?? 0)}
        }// end of ZStack in body
    }// end of body
    
    var iconView: some View {
        HStack(spacing: 10){
            // Button 4 image should be an "i" in the center of a circle
            Button(action: {
                self.showSheet=true
                self.showInfoSheet = true
            }){
                ZStack {
                    Circle().stroke(Color.blue)
                    Text("i").font(.title).frame(width: 30)
                }.frame(maxWidth: 30, maxHeight: 30).padding(.top,5)
            }// end of Button 4
                                                  
            Button(action: {
                if MFMailComposeViewController.canSendMail() {
                    self.emailGovernor = false
                    self.emailSixFeet = true
                    self.isShowingMailView.toggle()
                }else{self.alertNoMail.toggle()}
            }){
                Text("✉").font(.largeTitle)
            }
        }
    }
    
    var controlView: some View {
        HStack(spacing: 10){
            //Button 1 should be
            Button(action:{
                self.showSheet=true
                self.showInfoSheet = false
            }){
                Text("CLEAR\nHISTORY").frame(width: 75)
            }// end of Button 1

            if !self.dataServer.downloading {
                Button(action: {
                    self.dataServer.downLoadFile(links: self.group.getSelectedGroup().links)
                }){
                    Text("CHECK\nDATABASE").frame(width:85)
                }
            }else{
                Loader()
            }
            
            Button(action: {
                if self.group.getSelectedGroupChar().asciiValue == 48 {
                    self.showWithPassword = true
                }else{
                    self.showSendNormal = true
                }
                }) {
                    Text("SEND\nDATA").frame(width: 50)
                }// end of Button 3
        }.multilineTextAlignment(.center)
    }

    var aboutView: some View{
        HStack{ //HStack is a trick to center the displayed element
            Spacer()
            VStack{
                ScrollView{
                    Text(CONSTANTS.info).foregroundColor(.white).font(.title).lineLimit(nil)
                    Text(CONSTANTS.info_1).foregroundColor(.white).font(.title).lineLimit(nil)
                    Text(CONSTANTS.info_2).foregroundColor(.white).font(.title).lineLimit(nil)
                }
                        
                Spacer() //trick to force the display to start from top of the screen
                        
            }.padding(5)// end of VStack
            Spacer()
        }.background(Color.blue)
    }
    
    var explainView: some View{
        HStack{ //HStack is a trick to center the displayed element
            Spacer()
            VStack{
                ScrollView{
                    Text(CONSTANTS.infoPage2).foregroundColor(.white).lineLimit(nil).padding(5)
                }.background(Color(red: 0.0, green: 0.55, blue: 1.0))
                                       
                Text(CONSTANTS.inforPage2_2).font(.system(size: 16, weight: .bold)).foregroundColor(.yellow)
                                       
                //The bottome of the page should be a Email icon that when pressed setup showing screen for composing email to the governor.
                HStack{
                    Spacer()
                    Button(action:{
                        if MFMailComposeViewController.canSendMail(){
                            self.showExplain = false
                            self.emailGovernor = true
                            self.emailSixFeet = false
                            self.isShowingMailView.toggle()
                        }else{
                            self.showExplain = false
                            self.alertNoMail.toggle()
                        }
                    }){
                        Text("\nEmail Governor ✉️").font(.system(size: 16, weight: .bold)).foregroundColor(.yellow)
                    }
                    Spacer()
                }.padding(.bottom, 20)
            }.padding(5)// end of VStack
            Spacer()
        }.background(Color.blue)
    }
    
    var policyView: some View {
        HStack{ //HStack is a trick to center the displayed element
            Spacer()
            VStack{
                ScrollView{
                    Text(CONSTANTS.privacyPolicy).foregroundColor(.white).lineLimit(nil).frame(maxWidth: .infinity).padding(5)
                }.background(Color(red: 0.0, green: 0.6, blue: 1.0))
                Spacer()
            }.padding(2)// end of VStack
            Spacer()
        }.background(Color.blue)
    }
    
    var groupPassWordView: some View {
        VStack {
            SecureField(" Enter Group Code", text: self.$groupPassword)
            .background(Color(red: 150/255, green: 150/255, blue: 150/255))
            .cornerRadius (29)
            .frame (height: 70)
            .font(.system(size: 30))
            .foregroundColor(Color.white)
            Button(action: {
                if self.groupPassword == "shiawassee" {
                    self.groupPicked = 3
                    self.group.setSelectedGroup(numSelected: 3)
                    self.correctGroupPassword = true
                    self.locMonitor.fileService.saveFile(to: "GroupPassword", using: "correct")
                }
                else {
                    self.groupPicked = 0
                }
                self.showGroupPasswordButton = false
                self.showGroupPassword = false
            }){ Text("Enter") }
        }
    }
    
    var sendNormalView: some View {
        HStack{
            Spacer()
            VStack(alignment: .leading){
                HStack{
                    Text("What You Send").font(.largeTitle).foregroundColor(.white)
                        .padding(.top, UIApplication.shared.windows.filter{$0 .isKeyWindow}.first?.safeAreaInsets.top).padding(10)
                }
                
                Spacer()
                
                ScrollView {
                    Text(CONSTANTS.infoPage4_4).font(.title).foregroundColor(.yellow)//.system(size: 32, weight: .bold
                }.padding(10)
                
                Button(action:{
                    if let url = URL(string: self.group.getSelectedGroup().policy){
                        UIApplication.shared.open(url)
                    }
                }){
                    HStack{
                        Spacer()
                        Text("Privacy Policy").foregroundColor(.white).font(.largeTitle)
                        Image(systemName: "link.circle.fill").foregroundColor(.white).font(.largeTitle)
                        Spacer()
                    }.padding(.bottom, 6)
                    }
                //The bottome of the page should be a Email icon that when pressed setup showing screen for composing email to the governor.
                HStack{
                    //Spacer()
                    Button(action:{
                        if MFMailComposeViewController.canSendMail(){
                            self.showSendNormal = false
                            self.emailGovernor = false
                            self.emailSixFeet = false
                            self.isShowingMailView.toggle()
                        }else{
                            self.showSendNormal = false
                            self.alertNoMail.toggle()
                        }
                    }){
                        Text("Email ✉️").font(.title).foregroundColor(.white).padding(.leading, 10)
                    }
                    Spacer()
                    Button(action:{
                        self.showSendNormal = false
                        self.shareFile()
                    }){
                        HStack {
                            Text("Use other app").font(.title).foregroundColor(.white)
                            Image(systemName: "square.and.arrow.up").foregroundColor(.white).font(.title)
                        }.padding(.trailing, 10)
                    }
                    //Spacer()
                }.padding(.bottom, 20)
                Spacer()

            }.padding(2)
            Spacer()
        }.background(Color.blue)
    }
    
    var sendWithCodeView: some View {
        HStack{
            Spacer()
            VStack(alignment: .leading){
                HStack{
                    Text("Need Code to Send").font(.largeTitle).foregroundColor(.white)
                        .padding(.top, UIApplication.shared.windows.filter{$0 .isKeyWindow}.first?.safeAreaInsets.top).padding(10)
                    Spacer()
                }
                Spacer()
                ScrollView {
                    Text(CONSTANTS.noGroup).font(.title).foregroundColor(.white)//.system(size: 32, weight: .bold
                }.padding(10)
                HStack{
                    Spacer()
                    Text("Enter Code Below").foregroundColor(.white)
                    Spacer()
                }
                SecureField(" Code", text: self.$password)
                    .background(Color(red: 130/255, green: 200/255, blue: 200/255))
                    .cornerRadius (29)
                    .frame (height: 70)
                    .font(.system(size: 35))
                    .foregroundColor(Color.white)
                Spacer()
                if self.password == "1234" {
                    Button(action: {
                        if MFMailComposeViewController.canSendMail(){ //Is email stuff correct. Need to change alert
                            self.emailGovernor = false
                            self.emailSixFeet = false
                            self.isShowingMailView.toggle()
                        }else{self.alertNoMail.toggle()}
                    }){
                        HStack{
                            Spacer()
                            Text("Send").font(.largeTitle).padding(.trailing,10).foregroundColor(.yellow)
                            Image(systemName: "arrowshape.turn.up.right.fill")
                            Spacer()
                        }.foregroundColor(.white)
                    }
                }
                Button(action:{
                    if let url = URL(string: self.group.getSelectedGroup().policy){
                        UIApplication.shared.open(url)
                    }
                }){
                    HStack{
                        Spacer()
                        Text("Privacy Policy").foregroundColor(.white).font(.largeTitle)
                        Image(systemName: "link.circle.fill").foregroundColor(.white).font(.largeTitle)
                        Spacer()
                    }.padding(.bottom, 6)
                }.padding(.bottom, 6)
                //The bottome of the page should be a Email icon that when pressed setup showing screen for composing email to the governor.
                
            }.padding(2)
            Spacer()
        }.background(Color.blue)
    }
    
    func shareFile(){
        let activityView = UIActivityViewController(activityItems: ["send",self.locMonitor.fileService.prepareShareURL(global: false, selectChar: group.getSelectedGroupChar())], applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad{
            activityView.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
            activityView.popoverPresentationController?.sourceRect = CGRect(
                x: UIScreen.main.bounds.width/2.1,
                y: UIScreen.main.bounds.height/2.3, width: 200, height: 200)
        }
            UIApplication.shared.windows.first?.rootViewController?.present(activityView, animated: true, completion: nil)
    }
}

/*struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HaveWeMetView(group: GroupManager(), locMonitor: LocationProvider(groupManager: GroupManager()), showTerms: true)
    }
}*/
