//
//  SheetBridge.swift
//  misaka
//
//  Created by straight-tamago☆ on 2023/09/30.
//

import Foundation
import SwiftUI
import AlertToast
import LocationPicker
import UIKit

struct MainSheetBridge: View {
    @ObservedObject var MemorySingleton = Memory.shared
    @ObservedObject var SM = SettingsManager.shared
    @ObservedObject private var krwExploit = KRWExploitManager.shared
    @State var isLoading: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @State var FirstBoot = true
    var body: some View {
        ZStack {
            if Memory.shared.ShowViewF0 {
                Color.clear
                    .frame(width: 0, height: 0)
                    .onAppear {
                        if FirstBoot == true {
                            BackgroundApply()
                            DispatchQueue.global(qos: .background).async {
                                CacheServices.shared.BuildRepositoryCache()
                            }
                            
                            CommandReceiver()
                            
                            iconRestore()
                            
                            FirstBoot = false
                        }
                    }
            }
            ZStack {
                if Memory.shared.ShowViewF0 && Memory.shared.ShowViewF1 {
                    if isLoading {
                        ZStack {
                            if colorScheme == .dark {
                                Color.black
                                ImageLoader("https://raw.githubusercontent.com/shimajiron/Misaka_Network/main/Server/LogoDark.gif")
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: UIScreen.main.bounds.width)
                            }else {
                                Color.white
                                ImageLoader("https://raw.githubusercontent.com/shimajiron/Misaka_Network/main/Server/LogoLight.gif")
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: UIScreen.main.bounds.width)
                            }
                        }
                        .ignoresSafeArea(.all)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                withAnimation(.interpolatingSpring(stiffness: 500, damping: 500)) {
                                    isLoading = false
                                }
                            }
                        }
                    } else {
                        SheetBridge()
                    }
                }else{
                    VStack {
                        if !Memory.shared.ShowViewF0 {
                            exploitBootLogView
                        } else {
                            VStack {
                                Text("Power-Saving")
                                    .bold()
                                    .foregroundColor(.primary)
                                Image(systemName: "battery.75")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
//            if SM.LogStream {
//                LogStreamView()
//            }
        }
        .applyAppearenceSetting(DarkModeSetting(rawValue: ColorManager.shared.appearanceMode) ?? .followSystem)
//        .onAppear{
//            // 初期設定
//            ApplyDefaultSettings()
//            // 対応チェックとExploit実行
//            RunExploit(MemorySingleton: MemorySingleton)
//            
//            FileManager.default.createFile(atPath: "\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path)/SendCommand", contents: nil, attributes: nil)
//            
//        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                Wakeup()
                Memory.shared.ShowViewFB = true
                Memory.shared.ShowViewF1 = true
            case .inactive:
                withAnimation(.linear(duration: 3)) {
                    Memory.shared.ShowViewFB = false
                }
                print("inactive")
            case .background:
                withAnimation(.linear(duration: 3)) {
                    Memory.shared.ShowViewFB = false
                }
                print("background")
            @unknown default:
                print("@unknown")
            }
        }
    }

    /// krwtest-style live log while `KRWExploitManager` / KFS init runs before `ShowViewF0`.
    private var exploitBootLogView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ProgressView()
                Text("Exploiting kernel…")
                    .font(.headline)
                    .bold()
            }
            ScrollViewReader { proxy in
                ScrollView {
                    Text(krwExploit.log.isEmpty ? "Starting…" : krwExploit.log)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(10)
                        .id("exploitBootLogBottom")
                }
                .frame(maxHeight: min(280, UIScreen.main.bounds.height * 0.38))
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onChange(of: krwExploit.log) { _ in
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo("exploitBootLogBottom", anchor: .bottom)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
func iconRestore() {}

struct SheetBridge: View {
    @ObservedObject var MemorySingleton = Memory.shared
    @ObservedObject var ToastControllerSingleton = ToastController.shared
    @ObservedObject var LocationSingleton = Location.shared
    @ObservedObject var CM = ColorManager.shared
    @Environment(\.colorScheme) var colorScheme
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    @State var url: URL?
    var body: some View {
        ZStack {
            ZStack {
                ZStack {
                    ZStack {
                        ContentView()
                            .sheet(isPresented: $MemorySingleton.AppIconSelecter_IsActive) {
                                NavigationView {
                                    AppIconSelecter()
                                        .navigationTitle("App Icons")
                                }
                            }
                    }
                    .sheet(isPresented: $MemorySingleton.Welcome_IsActive) {
                        Welcome()
                    }
                    .onAppear {
                        if MemorySingleton.CurrentVersion == "" || MemorySingleton.CurrentVersion != version {
                            MemorySingleton.Welcome_IsActive = true
                        }else{
                            if UserDefaults.standard.bool(forKey: "Terms_of_Service") == false {
                                MemorySingleton.TermsOfService_IsActive = true
                            }
                        }
                    }
                }
                .sheet(isPresented: $LocationSingleton.showSheet) {
                    NavigationView {
                        LocationPicker(instructions: "Tap somewhere to select your coordinates", coordinates: $LocationSingleton.coordinates)
                            .navigationTitle("Location Picker")
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarItems(leading: Button(action: {
                                LocationSingleton.showSheet.toggle()
                            }, label: {
                                Text("Close").foregroundColor(.red)
                            }))
                    }
                }
            }
            .sheet(isPresented: $MemorySingleton.TermsOfService_IsActive) {
                NavigationView {
                    TermsOfService()
                }
            }
            .onChange(of: MemorySingleton.Welcome_IsActive, perform: { newvalue in
                if newvalue == false {
                    MemorySingleton.CurrentVersion = version
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if UserDefaults.standard.bool(forKey: "Terms_of_Service") == false {
                            MemorySingleton.TermsOfService_IsActive = true
                        }
                    }
                }
            })
        }
        .sheet(isPresented: $MemorySingleton.SettingsView_IsActive) {
            SettingsView()
        }
        .alert(isPresented: $MemorySingleton.RespringConfirm) {
            Alert(
                title: Text(MILocalizedString("Are you sure you want to Restart SpringBoard")),
                primaryButton: .destructive(Text(MILocalizedString("Restart")), action: {
                    Respring()
                }),
                secondaryButton: .default(Text(MILocalizedString("Cancel")))
            )
        }
        .overlay(
            AppLoadingView()
        )
        .toast(isPresenting: $ToastControllerSingleton.Show_HudLoading){
            ToastControllerSingleton.Toast_HudLoading ?? AlertToast(displayMode: .hud, type: .loading, title: "")
        }
        .toast(isPresenting: $ToastControllerSingleton.Show_Hud){
            ToastControllerSingleton.Toast_Hud ?? AlertToast(displayMode: .hud, type: .regular, title: "")
        }
        .toast(isPresenting: $ToastControllerSingleton.Show_Alert){
            ToastControllerSingleton.Toast_Alert ?? AlertToast(displayMode: .alert, type: .regular, title: "")
        }
        .toast(isPresenting: $ToastControllerSingleton.Show_bannerPop){
            ToastControllerSingleton.Toast_bannerPop ?? AlertToast(displayMode: .banner(.pop), type: .regular, title: "")
        }
        .toast(isPresenting: $ToastControllerSingleton.Show_bannerSlide){
            ToastControllerSingleton.Toast_bannerSlide ?? AlertToast(displayMode: .banner(.slide), type: .regular, title: "")
        }
        .toast(isPresenting: $ToastControllerSingleton.Show_complete){
            ToastControllerSingleton.Toast_complete ?? AlertToast(type: .complete(.green), title: "", subTitle: "")
        }
        .toast(isPresenting: $ToastControllerSingleton.Show_error){
            ToastControllerSingleton.Toast_error ?? AlertToast(type: .error(.red), title: "", subTitle: "")
        }
        .accentColor(colorScheme == .dark ? CM.D_AccentColor : CM.W_AccentColor)
        .onOpenURL { (urli) in
            self.url = urli
            if let url = url {
                if String(url.absoluteString) == "misaka://allapply" {
                    ViewMemory.shared.AppLoading = true
                    DispatchQueue.global().async { // バックグラウンドスレッドで実行する
                        ApplyAll(Keep: false)
                        DispatchQueue.main.async {
                            ViewMemory.shared.AppLoading = false
                            UIApplication.shared.alert(title: "", body: MILocalizedString("All Applied"))
                        }
                    }
                    return
                }else if String(url.absoluteString) == "misaka://allapply_respring" {
                    ViewMemory.shared.AppLoading = true
                    DispatchQueue.global().async {
                        ApplyAll(Keep: false)
                        DispatchQueue.main.async {
                            ViewMemory.shared.AppLoading = false
                            UIApplication.shared.alert(title: "", body: MILocalizedString("All Applied"))
                            Respring()
                        }
                    }
                    return
                } else if String(url.absoluteString).prefix(17) == "misaka://addrepo="  {
                    MemorySingleton.RepositoriesURL.append(url.absoluteString.replacingOccurrences(of: "misaka://addrepo=", with: "").replacingOccurrences(of: "http//", with: "http://").replacingOccurrences(of: "https//", with: "https://"))
                    MemorySingleton.TabSelection = 2
                    UIApplication.shared.alert(title: "", body: MILocalizedString("Added Repo ..."))
                    return
                }else if String(url.absoluteString).prefix(19) == "misaka://opentweak="  {
                    let payload = url.absoluteString.replacingOccurrences(of: "misaka://opentweak=", with: "")
                    let parts = payload.split(separator: "&", maxSplits: 1, omittingEmptySubsequences: false)
                    guard parts.count == 2 else {
                        UIApplication.shared.alert(title: "Open Tweak", body: "Invalid tweak link")
                        return
                    }

                    let repositoryURL = String(parts[0])
                        .replacingOccurrences(of: "http//", with: "http://")
                        .replacingOccurrences(of: "https//", with: "https://")
                    let packageID = String(parts[1])

                    guard !repositoryURL.isEmpty, !packageID.isEmpty else {
                        UIApplication.shared.alert(title: "Open Tweak", body: "Invalid tweak link")
                        return
                    }

                    CacheServices.shared.BuildRepositoryCache()
                    MemorySingleton.TabSelection = 2
                    RepositoryContentSimpleTypeDirectOpen(
                        RepositoryContentSimpleType(RepositoryURL: repositoryURL, PackageID: packageID)
                    ) { repositoryContentPack in
                        if let repositoryContentPack = repositoryContentPack {
                            DispatchQueue.main.async {
                                MemorySingleton.AddonPage_RepositoryContentPack = repositoryContentPack
                                MemorySingleton.AddonPage_isActive = true
                            }
                        }
                    }
                    return
                }
                DispatchQueue.global().async {
                    if AddonImport(url, nil) == "Installed" {
                        ToastController.shared.Toast_complete = AlertToast(type: .complete(.green), title: "Imported", subTitle: "")
                        ToastController.shared.Show_complete = true
                    }else {
                        ToastController.shared.Toast_error = AlertToast(type: .error(.red), title: "Error", subTitle: "")
                        ToastController.shared.Show_error = true
                    }
                }
            }
        }
        .onAppear {
            setupNavigationBarTintColor()
        }
    }
    
    private func setupNavigationBarTintColor() {
        // 黒色のChevronLeftImageを作成
        let blackChevronLeftImage = UIImage(systemName: "chevron.backward")!.withTintColor(UIColor(colorScheme == .dark ? CM.D_AccentColor : CM.W_AccentColor), renderingMode: .alwaysOriginal)

        // 黒に設定したUIImageをbackIndicatorImageに渡す
        UINavigationBar.appearance().backIndicatorImage = blackChevronLeftImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = blackChevronLeftImage

        // UIBarButtonItemのタイトルテキストのforegroundColorを黒に設定
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor(colorScheme == .dark ? CM.D_AccentColor : CM.W_AccentColor)], for: .normal)
    }
}
