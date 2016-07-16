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

#if os(iOS)
import UIKit

struct LogFile {
    let name: String
    let path: NSURL
}

private extension Selector {
    static let dismiss = #selector(LogsViewController.dismiss)
}

class LogsViewController: UITableViewController {
    private var files = [LogFile]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: .dismiss)
    }
    
    @objc private func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        listFiles()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseIdentifier = "reuseIdentifier"
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) ?? UITableViewCell(style: .Default, reuseIdentifier: reuseIdentifier)
        let file = files[indexPath.row]
        cell.textLabel?.text = file.name
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let file = files[indexPath.row]
        
        let activityController = UIActivityViewController(activityItems: [file.path], applicationActivities: nil)
        presentViewController(activityController, animated: true, completion: nil)
    }
}

private extension LogsViewController {
    func listFiles() {
        var folder: NSURL?
        for output in Logger.sharedInstance.outputs {
            guard let fileOutput = output as? FileOutput else {
                continue
            }
            
            folder = fileOutput.logsFolder
            break
        }
        
        guard let logsFolder = folder else {
            Log.debug("Logs folder not found. Is file logging enabled?")
            return
        }
        
        do {
            let files = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(logsFolder, includingPropertiesForKeys: nil, options: [.SkipsHiddenFiles, .SkipsPackageDescendants, .SkipsSubdirectoryDescendants]).reverse()
            
            for file in files {
                let logFile = LogFile(name: file.lastPathComponent!, path: file)
                self.files.append(logFile)
            }
            
        } catch let error as NSError {
            Log.error(error)
        }
    }
}
#endif
