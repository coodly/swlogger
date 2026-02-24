/*
 * Copyright 2015 Coodly LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import ConcurrencyExtras
import Foundation

public final class FileOutput: Sendable {
  public enum Keep: Equatable, Sendable {
    case forever
    case days(Int)
    case number(Int)
  }

  public enum FileTime: Sendable {
    case minuteBased
    case dateBased
  }

  private let fileHandle: LockIsolated<FileHandle?> = LockIsolated(nil)
  private let logFileURL: URL
  public let logsFolder: URL
  private let newLine = "\n".data(using: .utf8)!
  private let noDataMessage = "<- No UTF8 data ->".data(using: .utf8)!

  public convenience init(
    appGroup: String,
    identifier: String = Bundle.main.bundleIdentifier!,
    name: String? = nil,
    fileTime: FileTime = .minuteBased,
    keep: Keep = .forever
  ) {
    self.init(appGroup: appGroup, directory: .documentDirectory, identifier: identifier, name: name, fileTime: fileTime, keep: keep)
  }

  public convenience init(
    saveInDirectory: FileManager.SearchPathDirectory = .documentDirectory,
    identifier: String = Bundle.main.bundleIdentifier!,
    name: String? = nil,
    fileTime: FileTime = .minuteBased,
    keep: Keep = .forever
  ) {
    self.init(appGroup: nil, directory: saveInDirectory, identifier: identifier, name: name, fileTime: fileTime, keep: keep)
  }

  private init(
    appGroup: String?,
    directory: FileManager.SearchPathDirectory,
    identifier: String,
    name: String?,
    fileTime: FileTime,
    keep: Keep
  ) {
    let baseFolder: URL
    if let appGroup, let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
      baseFolder = container
    } else {
      baseFolder = FileManager.default.urls(for: directory, in: .userDomainMask).last!
    }

    let folder = baseFolder.appendingPathComponent(identifier + ".logs")
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    logsFolder = folder

    let fileName: String
    if let name {
      fileName = name
    } else {
      let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
      let prefix = (displayName ?? bundleName).map { $0.isEmpty ? "" : "\($0)-" } ?? ""
      let formatter = DateFormatter()
      formatter.dateFormat = fileTime == .dateBased ? "yyyy-MM-dd" : "yyyy-MM-dd-HH-mm"
      fileName = "\(prefix)\(formatter.string(from: Date())).txt"
    }

    logFileURL = folder.appendingPathComponent(fileName)

    cleanOld(in: folder, with: keep)
  }

  public var output: LogOutput {
    LogOutput { [self] message in
      fileHandle.withValue { handle in
        let resolved: FileHandle
        if let handle {
          resolved = handle
        } else {
          if !FileManager.default.fileExists(atPath: logFileURL.path) {
            try? Data().write(to: logFileURL, options: .atomic)
          }
          guard let opened = try? FileHandle(forWritingTo: logFileURL) else { return }
          opened.seekToEndOfFile()
          handle = opened
          resolved = opened
        }
        if let data = message.data(using: .utf8) {
          resolved.write(data)
        } else {
          resolved.write(noDataMessage)
        }
        resolved.write(newLine)
      }
    }
  }

  public func trimmed(to lines: Int) {
    guard let data = try? Data(contentsOf: logFileURL) else { return }
    let trimmed = data.tail(lines: lines)
    try? trimmed.write(to: logFileURL)
  }

  public func listLogFiles() -> [LogFile] {
    guard let paths = try? FileManager.default.contentsOfDirectory(at: logsFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
      return []
    }
    return paths.compactMap { url -> LogFile? in
      guard let attr = try? FileManager.default.attributesOfItem(atPath: url.path),
            let date = attr[.creationDate] as? Date
      else { return nil }
      return LogFile(file: url, creationDate: date)
    }
    .sorted { $0.creationDate! > $1.creationDate! }
  }

  public func tail(lines: Int) -> Data? {
    guard let data = try? Data(contentsOf: logFileURL) else { return nil }
    return data.tail(lines: lines)
  }

  private func cleanOld(in folder: URL, with keep: Keep) {
    guard keep != .forever else { return }
    let files = listLogFiles()
    switch keep {
    case .forever:
      break
    case .days(let days):
      guard let after = Calendar(identifier: .gregorian).date(byAdding: .day, value: -days, to: Date()) else { return }
      remove(files: files.filter { $0.creationDate! < after })
    case .number(let number):
      guard files.count > number else { return }
      remove(files: Array(files.suffix(from: number)))
    }
  }

  private func remove(files: [LogFile]) {
    for file in files {
      Task.detached(priority: .utility) {
        try? FileManager.default.removeItem(at: file.file)
      }
    }
  }
}

public struct LogFile: Sendable {
  public let name: String
  public let file: URL
  let creationDate: Date?
}

extension LogFile {
  internal init(file: URL, creationDate: Date) {
    name = file.lastPathComponent
    self.file = file
    self.creationDate = creationDate
  }

  internal init(name: String, path: URL) {
    self.name = name
    self.file = path
    creationDate = nil
  }
}
