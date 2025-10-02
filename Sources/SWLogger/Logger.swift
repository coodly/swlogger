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

import Foundation
import ConcurrencyExtras

internal final class Logger: Sendable {
  internal static let sharedInstance = Logger()
  private let outputs: LockIsolated<[LogOutput]> = LockIsolated([])
  private let cleaned: LockIsolated<Dictionary<String, String>> = LockIsolated(Dictionary())
        
  private let queue = DispatchQueue(label: "com.coodly.logging.queue")
    
  internal func add(output: LogOutput) {
    outputs.setValue(outputs.value + [output])
  }
    
  internal func log<T>(message: Message<T>) {
    queue.sync {
      guard message.level.rawValue >= Log.level.rawValue else {
        return
      }

      let time = timeFormatter.string(from: message.time)
      let levelString = levelToString(message.level)
      let cleanedFile = cleaned(path: message.file)
      let message = "\(time) - \(message.logger) - \(levelString) - \(cleanedFile).\(message.function):\(message.line) - \(message.object)"

      for output in outputs.value {
        output.printMessage(message)
      }
    }
  }
        
  private func levelToString(_ level: Log.Level) -> String {
    switch(level) {
    case .error:
      return "E"
    case .info:
      return "I"
    case .debug:
      return "D"
    case .verbose:
      return "V"
    default:
      return ""
    }
  }
    
  private func cleaned(path: String) -> String {
    if let existing = self.cleaned.value[path] {
      return existing
    }
        
    let fileURL = URL(fileURLWithPath: path, isDirectory: false)
    let cleanedFile = fileURL.lastPathComponent
    self.cleaned.setValue(cleaned.value.adding(key: path, value: cleanedFile))
    return cleanedFile
  }
    
  private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()
}

extension Dictionary where Key == String, Value == String {
  func adding(key: String, value: String) -> Self {
    var modified = self
    modified[key] = value
    return modified
  }
}
