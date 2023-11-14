//
//  ContentView.swift
//  colours
//
//  Created by David JM Lewis on 27/03/2023.
//

import SwiftUI
import UniformTypeIdentifiers


struct ExportFileDocument: FileDocument {
    static var readableContentTypes = [UTType.json, UTType.xmlPropertyList]
    
    var exportArrayData: Data?
    
    // a simple initializer that creates new, empty documents
        
    init(exportArrayData: Data) {
        self.exportArrayData = exportArrayData
    }


    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
        if let _ = configuration.file.regularFileContents {

        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: exportArrayData ?? Data())
    }
}



let kColourNameAddedPrefix = "#"

typealias HexColourString = String
typealias HexStringColoursDict = [String : HexColourString]
typealias ArrayColourNamesArrays = [[String]]
struct DictHexStringColoursDictColourNamesArrays: Codable {
    var coloursDoubleDict: HexStringColoursDict
    var arrayColourNamesArrays: ArrayColourNamesArrays
}


func uiColorFromHexString(_ hex: String) -> UIColor? {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "") // repeats below but things may change
    hexSanitized = hexSanitized.replacingOccurrences(of: kColourNameAddedPrefix, with: "")

    var rgb: UInt64 = 0

    var r: CGFloat = 0.0
    var g: CGFloat = 0.0
    var b: CGFloat = 0.0
    var a: CGFloat = 1.0

    let length = hexSanitized.count

    guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

    if length == 6 {
        r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        b = CGFloat(rgb & 0x0000FF) / 255.0
    } else if length == 8 {
        r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
        g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
        b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
        a = CGFloat(rgb & 0x000000FF) / 255.0
    } else { return nil }

    return UIColor(red: r, green: g, blue: b, alpha: a)
}

func hexStringFromUIColor(_ uicolor: UIColor?, alpha: Bool = false) -> String? {
    guard let components = uicolor?.cgColor.components, components.count >= 3 else {
        return nil
    }

    let r = Float(components[0])
    let g = Float(components[1])
    let b = Float(components[2])
    var a = Float(1.0)

    if components.count >= 4 {
        a = Float(components[3])
    }

    if alpha {
        return kColourNameAddedPrefix + String(format: "%02lX%02lX%02lX%02lX", lroundf(floor(r * 255)), lroundf(floor(g * 255)), lroundf(floor(b * 255)), lroundf(floor(a * 255)))
    } else {
        return kColourNameAddedPrefix + String(format: "%02lX%02lX%02lX", lroundf(floor(r * 255)), lroundf(floor(g * 255)), lroundf(floor(b * 255)))
    }
}



struct ContentView: View {
    @State var exportFileDocument: ExportFileDocument?
    @State var fileSaverShown: Bool = false
    @State var docType = UTType.xmlPropertyList
    
    var body: some View {
        VStack {
            Button("Save") {
                fileSaverShown = true
            }
       }
        .padding()
        .onAppear {
            if let plistPath = Bundle.main.url(forResource: "crayonsColourNames", withExtension: "plist") {
                do {
                    let data = try Data(contentsOf: plistPath)
                    if let arrayCrayonNames = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] {
                        var dictColourNamesHexStrings = HexStringColoursDict()
                        
                        for colourName in arrayCrayonNames {
                            if let colour = UIColor(named: colourName),
                               let hexStr = hexStringFromUIColor(colour)
                            {
                                let col2 = uiColorFromHexString(hexStr)
                                print(colourName,hexStr, hexStringFromUIColor(col2) == hexStr)
                                dictColourNamesHexStrings[colourName] = hexStr//[hue, saturation, brightness]
                            } else { debugPrint("no match arrayCrayonNames", colourName) }
                        }
                        
                        if let propertyListData = try? JSONEncoder().encode(dictColourNamesHexStrings) {
                            exportFileDocument = ExportFileDocument(exportArrayData: propertyListData)
                            docType = UTType.json
                        }
                        
                    }
                } catch {
                    debugPrint(error)
                }
            }

        }
        .fileExporter(isPresented: $fileSaverShown,
                      document: exportFileDocument,
                      contentType: docType,
                      defaultFilename: "crayonsHexStringColoursDict") { result in
            switch result {
            case .success:
                break
            case .failure:
                break
            }
        } /* fileExporter */

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
