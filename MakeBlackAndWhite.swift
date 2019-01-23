#!/usr/bin/env ./swiftHelper.sh

import Cocoa
import Foundation
import ImageIO

let sourceDirectory = "Source"
let processedDirectory = "Processed"
var pathToScript = ""


extension NSImage {
    var CGImage: CGImage? {
        get {
            var result: CGImage?
            if let data = self.tiffRepresentation {
                if let imageDataCFData = CFDataCreateWithBytesNoCopy(nil, (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), data.count, kCFAllocatorNull) {
                    let source = CGImageSourceCreateWithData(imageDataCFData, nil)
                    result = CGImageSourceCreateImageAtIndex(source!, 0, nil)!
                }
            }
            return result
        }
    }
    
    func writeToFile(path: String) -> Bool {
        var result = false
        if let cgImage = self.CGImage {
            let imgRep = NSBitmapImageRep(cgImage:cgImage)
            
            if let data = imgRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:]) {
                let url = URL(fileURLWithPath: path)
                do {
                    try data.write(to: url, options: .atomic)
                    result = true
                } catch {
                    return result
                }
            }
            
        }
        return result
    }
}

func convertToGrayScale(image: NSImage) -> NSImage? {

    var result: NSImage?
    let imageRect:CGRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let width = image.size.width
    let height = image.size.height
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
    if let context = CGContext.init(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) {
        if let cgImageRef = image.CGImage {
            context.draw(cgImageRef, in: imageRect)
            let imageRef = context.makeImage()
            result = NSImage(cgImage: imageRef!, size: imageRect.size)
        }
    }
    return result
}

func getPathToScriptForArgument(argument: String) -> String {
    var urlString: String = ""
    if let urlStr = NSURL(fileURLWithPath: argument).absoluteString {
        urlString = urlStr.replacingOccurrences(of: "file://", with: "", options: NSString.CompareOptions.literal, range: nil).replacingOccurrences(of: "MakeBlackAndWhite.swift", with: "", options: NSString.CompareOptions.literal, range: nil)
    }
    return urlString
}

func getFilesInDirectory(directory: String) -> [String] {
    var result = [String]()
    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(atPath: directory)!
    
    
    for element in enumerator {
        result.append(element as! String)
    }
    return result;
}

func getImageAtPath(path: String) -> NSImage? {
    var result: NSImage?
    if let data = NSData(contentsOf: URL(fileURLWithPath:path)) {
        result = NSImage(data:data as Data)
    }
    
    return result
}



for _ in CommandLine.arguments {
    if CommandLine.arguments.count > 0 {
        pathToScript = getPathToScriptForArgument(argument: CommandLine.arguments[0])
    }
}
let fullSourcePath = "\(pathToScript)\(sourceDirectory)"
for file in getFilesInDirectory(directory: fullSourcePath) {
    let imagePath = "\(fullSourcePath)/\(file)"
    print("Getting image: \(file)")
    if let image = getImageAtPath(path: imagePath) {
        if let greyImage = convertToGrayScale(image: image) {
            print("Made image: \(file) Grey.")
            let fullProcessedPath = "\(pathToScript)\(processedDirectory)/Processed_\(file)"
            print("Writing image: \(file) to file.")
            if greyImage.writeToFile(path: fullProcessedPath) {
                print("Saved image: \(file)")
            } else {
                print("Could not save image: \(file)")
            }
            
            
        }
    }
}
