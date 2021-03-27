//
//  ContentView.swift
//  BrewBar
//
//  Created by Thomas on 16/02/2021.
//

import SwiftUI
import ActivityIndicatorView

struct ContentView: View {
    @EnvironmentObject var outdatedApps: ListOfOutdatedApps
    //@State var isLoaded: Bool
    @State var boolTrue: Bool = true
    
    var body: some View {
        VStack {
            Text("BrewBar")
                .font(.largeTitle)
                .padding()
            
            
            if (outdatedApps.isLoaded) {

                
                
                List(outdatedApps.list, id:\.id) { data in
                    ScrollView {
                        HStack {
                            Text(data.appName)
                                .font(.title)
                            Text(data.oldVersion)
                            Text(data.newVersion)
                        }
                    }
                }
                
                Button(action: outdatedApps.upgradeApps) {
                    Text("Upgrade applications")
                }
                
                
                
            } else {
                ActivityIndicatorView(isVisible: self.$boolTrue, type: .default)
                    .frame(width: 20.0, height: 20.0)
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static let outdatedApps: ListOfOutdatedApps = ListOfOutdatedApps()
    
    static var previews: some View {
        ContentView().environmentObject(outdatedApps)
    }
}
