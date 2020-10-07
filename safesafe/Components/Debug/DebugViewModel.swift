//
//  DebugViewModel.swift
//  safesafe
//
//  Created by Lukasz szyszkowski on 18/08/2020.
//

import Foundation
import ZIPFoundation

enum DebugAction {
    case none
    case uploadedPayloadsShare
    case uploadedPayloadsPreview
    case logsShare
    case dumpLocalstorage
}

protocol DebugViewModelDelegate: class {
    func sharePayloads(fileURL: URL)
    func shareLogs(fileURL: URL)
    func showTextPreview(text: String)
    func showLocalStorageFiles(list: [String])
}

final class DebugViewModel: ViewModelType {
    weak var delegate: DebugViewModelDelegate?
    private lazy var sqliteManager = SQLiteManager()
    
    enum Texts {
        static let title = "Debug"
        static let previewTitle = "Preview"
        static let noUploadedPayloadsTitle = "No Uploaded Payloads Yet"
        static let shareUploadedPayloadsTitle = "Share Uploaded Payloads"
        static let noLogsTitle = "Nothing logged yet"
        static let shareLogsTitle = "Share Logs"
        static let dumpLocalStorageTitl = "Dump Local Storage"
    }
    
    var numberOfPayloads: Int {
        do {
            let dirContent = try FileManager.default.contentsOfDirectory(atPath: try Directory.uploadedPayloads().path)
            return dirContent.count
        } catch {
            console(error, type: .error)
        }
        return .zero
    }
    
    var logExists: Bool {
        do {
            let dirContent = try FileManager.default.contentsOfDirectory(atPath: try Directory.logs().path)
            return dirContent.count != .zero
        } catch {
            console(error, type: .error)
        }
        return false
    }
    
    func manage(debugAction: DebugAction) {
        switch debugAction {
        case .uploadedPayloadsShare:
            guard let url = try? File.uploadedPayloadsZIP() else { return }
            delegate?.sharePayloads(fileURL: url)
        case .logsShare:
            guard let url = try? File.logFileURL() else { return }
            delegate?.shareLogs(fileURL: url)
        case .dumpLocalstorage:
            let list = localStorageFiles()
            guard !list.isEmpty else { return }
            
            delegate?.showLocalStorageFiles(list: list)
        default: ()
        }
    }
    
    func openLocalStorage(with name: String) {
        delegate?.showTextPreview(text: sqliteManager.read(fileName: name))
    }
    
    private func localStorageFiles() -> [String] {
        do {
            let dirURL = try Directory.webkitLocalStorage()
            let dirContent = try FileManager.default.contentsOfDirectory(atPath: dirURL.path).filter({ $0.hasSuffix("localstorage")})
            
            return dirContent
            
        } catch { console(error, type: .error) }
        
        return []
    }
}
