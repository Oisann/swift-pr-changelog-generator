import Foundation

class Change {
    public var hash: String = ""
    public var author: String = ""
    public var email: String = ""
    public var date: String = ""
    public var title: String = ""
    public var message: String = ""
    
    init() {
        
    }
}

extension String {
    func replace(_ target: String, _ withString: String) -> String {
        return self.replacingOccurrences(of: target, with: withString, options: .literal, range: nil)
    }
}

func getEnvironmentVar(_ name: String) -> String? {
    guard let rawValue = getenv(name) else { return nil }
    return String(utf8String: rawValue)
}

guard let REPO = getEnvironmentVar("REPO") else {
    print("No REPO path found in the environment.")
    exit(0)
}

guard let BRANCH = getEnvironmentVar("BRANCH") else {
    print("No BRANCH found in the environment.")
    exit(0)
}

guard let BRANCH_MASTER = getEnvironmentVar("BRANCH_MASTER") else {
    print("No BRANCH found in the environment.")
    exit(0)
}


func matches(for regex: String, in text: String, options: NSRegularExpression.Options = NSRegularExpression.Options.useUnixLineSeparators) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex, options: options)
        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

func shell(launchPath: String, arguments: [String]) -> String {
    let process = Process()
    process.launchPath = launchPath
    process.arguments = arguments
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    
    let output_from_command = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8)!
    
    if output_from_command.count > 0 {
        let lastIndex = output_from_command.index(before: output_from_command.endIndex)
        return String(output_from_command[output_from_command.startIndex ..< lastIndex])
    }
    return output_from_command
}

let output = shell(launchPath: "/usr/bin/git", arguments: [ "-C", REPO, "log", "\(BRANCH_MASTER)..\(BRANCH)" ])
let matched = matches(for: ".*", in: output)

var changes: [Change] = []
var current: Change?

for match in matched {
    if match.count > 0 {
        if match.hasPrefix("commit") {
            if let current = current {
                changes.append(current)
            }
            current = Change()
            current!.hash = match.replace("commit ", "")
        } else if match.hasPrefix("Author: ") {
            var author = match.replace("Author: ", "")
            let m = matches(for: "<(.*?)@(.*?)>", in: author)[0]
            author = author.replace(" \(m)", "")
            let email = m.replace("<", "").replace(">", "")
            
            current!.author = author
            current!.email = email
        } else if match.hasPrefix("Date: ") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE MMM d HH:mm:ss yyyy ZZ"
            
            guard let date_gmt = dateFormatter.date(from: match.replace("Date: ", "")) else {
                fatalError("ERROR: Date conversion failed due to mismatched format.")
            }
            var date = dateFormatter.string(from: date_gmt)
            if let timeZone = TimeZone(abbreviation: "CEST") {
                dateFormatter.timeZone = timeZone
                date = dateFormatter.string(from: date_gmt)
            }
            current!.date = date
        } else if match.hasPrefix("    ") {
            if current!.title.count > 0 {
                current!.message += match.replace("    ", "")
                current!.message += "\n"
            } else {
                current!.title = match.replace("    ", "")
            }
        }
    }
}


var file_output: String = ""

for (_, change) in changes.enumerated() {
    let title = matches(for: " (close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) #\\d+", in: change.title, options: .caseInsensitive)
    var titleText = ""
    if title.count > 0 {
        titleText = title[0]
    }
    
    let changeText = change.message.count > 0 ? change.message : (titleText.count > 0 ? change.title.replace(titleText, "") : "")
    if !changeText.hasPrefix("--") && changeText.count > 0 {
        file_output += "- \(changeText)\n"
    }
}

let file = "/repo/CHANGELOG"

let dir =  URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fileURL = dir.appendingPathComponent(file)

do {
    try file_output.write(to: fileURL, atomically: false, encoding: .utf8)
} catch let error {
    print("Unable to save CHANGELOG to a file. Error: \(error.localizedDescription)")
}