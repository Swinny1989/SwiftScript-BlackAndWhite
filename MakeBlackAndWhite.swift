#!/usr/bin/env ./swiftHelper.sh

import Cocoa
import Foundation
import ImageIO

let sourceDirectory = "Source"
let processedDirectory = "Processed"
var pathToScript = ""


extension NSImage {
    var CGImage: CGImageRef? {
        get {
            var result: CGImageRef?
            let imageData = self.TIFFRepresentation
            if let imageDataCFData = imageData {
                let source = CGImageSourceCreateWithData(imageDataCFData, nil)
                result = CGImageSourceCreateImageAtIndex(source!, 0, nil)!
            }
            return result
        }
    }
    
    func writeToFile(path: String) -> Bool {
        var result = false
        if let cgImage = self.CGImage {
            let imgRep = NSBitmapImageRep(CGImage:cgImage)
            
            if let data = imgRep.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: [:])
            {
                result = data.writeToFile(path, atomically: false)
            }
            
        }
        return result
    }
}

func convertToGrayScale(image: NSImage) -> NSImage? {

    var result: NSImage?
    let imageRect:CGRect = CGRectMake(0, 0, image.size.width, image.size.height)
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let width = image.size.width
    let height = image.size.height
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.None.rawValue)
    let context = CGBitmapContextCreate(nil, Int(width), Int(height), 8, 0, colorSpace, bitmapInfo.rawValue)
    if let cgImageRef = image.CGImage {
        CGContextDrawImage(context, imageRect, cgImageRef)
        let imageRef = CGBitmapContextCreateImage(context)
        result = NSImage(CGImage: imageRef!, size: imageRect.size)
    }
    return result
}

func getPathToScriptForArgument(argument: String) -> String {
    var urlString: String = ""
    
    urlString = NSURL(fileURLWithPath: argument).absoluteString.stringByReplacingOccurrencesOfString("file://", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString("MakeBlackAndWhite.swift", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
    
    return urlString
}

func getFilesInDirectory(directory: String) -> [String] {
    var result = [String]()
    let fileManager = NSFileManager.defaultManager()
    let enumerator:NSDirectoryEnumerator = fileManager.enumeratorAtPath(directory)!
    
    
    for element in enumerator {
        result.append(element as! String)
    }
    return result;
}

func getImageAtPath(path: String) -> NSImage? {
    var result: NSImage?
    if let data = NSData(contentsOfURL: NSURL(fileURLWithPath:path)) {
        result = NSImage(data:data)
    }
    
    return result
}



for argument in Process.arguments {
    if Process.arguments.count > 0 {
        pathToScript = getPathToScriptForArgument(Process.arguments[0])
    }
}
let fullSourcePath = "\(pathToScript)\(sourceDirectory)"
for file in getFilesInDirectory(fullSourcePath) {
    let imagePath = "\(fullSourcePath)/\(file)"
    print("Getting image: \(file)")
    if let image = getImageAtPath(imagePath) {
        if let greyImage = convertToGrayScale(image) {
            print("Made image: \(file) Grey.")
            let fullProcessedPath = "\(pathToScript)\(processedDirectory)/Processed_\(file)"
            print("Writing image: \(file) to file.")
            if greyImage.writeToFile(fullProcessedPath) {
                print("Saved image: \(file)")
            } else {
                print("Could not save image: \(file)")
            }
            
            
        }
    }
}



