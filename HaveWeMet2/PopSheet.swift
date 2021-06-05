//
//  PopSheet.swift
//  PrivateTrac
//
//  Created by Bobo Qiu on 7/22/20.
//  Copyright © 2020 Caleb Qiu. All rights reserved.
//

//
//  PopSheet.swift
//
//  Adapted from:
//  https://stackoverflow.com/questions/56910941/present-actionsheet-in-swiftui-on-ipad and Stephen Lang
//
import SwiftUI

extension View {
    func popSheet(isPresented: Binding<Bool>, arrowEdge: Edge = .bottom, content: @escaping () -> PopSheet) -> some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                popover(isPresented: isPresented, attachmentAnchor: .point(.bottom), arrowEdge: arrowEdge, content: { content().popover(isPresented: isPresented) })
            } else {
                actionSheet(isPresented: isPresented, content: { content().actionSheet() })
            }
        }
    }
}

struct PopSheet {
    let title: Text
    let message: Text?
    let buttons: [PopSheet.Button]
    
    public init(title: Text, message: Text? = nil, buttons: [PopSheet.Button] = [.cancel()]) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }
    
    func actionSheet() -> ActionSheet {
        ActionSheet(title: title, message: message, buttons: buttons.map({ popButton in
            switch popButton.kind {
            case .default: return .default(popButton.label, action: popButton.action)
            case .cancel: return .cancel(popButton.label, action: popButton.action)
            case .destructive: return .destructive(popButton.label, action: popButton.action)
            }
        }))
    }
    
    func popover(isPresented: Binding<Bool>) -> some View {
        let width = UIScreen.main.bounds.width / 2
        let maxHeight = UIScreen.main.bounds.height * 0.75
        var height = CGFloat(buttons.count * 40) + 140 // buttons + title
        
        if message != nil {
            height += 45
        }
        
        if height > maxHeight {
            height = maxHeight
        }
        
        return VStack() {
            title.font(.title)
            
            if message != nil {
                message.font(.body).padding()
            }
            
            Divider()
            
            List {
                ForEach(buttons) { button in
                    SwiftUI.Button(action: {
                        // hide the popover whenever an action is performed
                        isPresented.wrappedValue = false
                        // another bug: if the action shows a sheet or popover, it will fail unless this one has already been dismissed
                        DispatchQueue.main.async {
                            button.action?()
                        }
                    }, label: {
                        button.label
                    })
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .frame(width: width, height: height)
    }
    
    public struct Button: Identifiable {
        let id = UUID().uuidString
        let kind: Kind
        let label: Text
        let action: (() -> Void)?
        enum Kind { case `default`, cancel, destructive }
        
        /// Creates a `Button` with the default style.
        public static func `default`(_ label: Text, action: (() -> Void)? = {}) -> Self {
            Self(kind: .default, label: label, action: action)
        }
        
        /// Creates a `Button` that indicates cancellation of some operation.
        public static func cancel(_ label: Text, action: (() -> Void)? = {}) -> Self {
            Self(kind: .cancel, label: label, action: action)
        }
        
        /// Creates an `Alert.Button` that indicates cancellation of some operation.
        public static func cancel(_ action: (() -> Void)? = {}) -> Self {
            Self(kind: .cancel, label: Text("Cancel"), action: action)
        }
        
        /// Creates an `Alert.Button` with a style indicating destruction of some data.
        public static func destructive(_ label: Text, action: (() -> Void)? = {}) -> Self {
            Self(kind: .destructive, label: label, action: action)
        }
    }
}
