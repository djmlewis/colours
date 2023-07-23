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



typealias ColoursDoubleDict = [String : [Double]]
typealias ArrayColourNamesArrays = [[String]]
struct DictDictArrays: Codable {
    var coloursDoubleDict: ColoursDoubleDict
    var arrayColourNamesArrays: ArrayColourNamesArrays
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
                        
                        var arrayNamesArrays = ArrayColourNamesArrays()
                        arrayNamesArrays.append(arrayCrayonNames)
                        
                        var dictHSB = ColoursDoubleDict()
                        
                        for colourName in arrayCrayonNames {
                            var hue        : CGFloat = 0
                            var saturation : CGFloat = 0
                            var brightness : CGFloat = 0
                            var alpha      : CGFloat = 0
                            if let colour = UIColor(named: colourName),
                            true == colour.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
                                dictHSB[colourName] = [hue, saturation, brightness]
                            } else { debugPrint("no match arrayCrayonNames", colourName) }
                        }
                        // now append the full colour spectrum colours. the order added must match the enum ColourPalette
                        var arrayColourNamesHSB = [String]()
                        for hue: Int in stride(from: 0, through: 100, by: 2) {
                            let key = String(format: "%03i100100", hue)
                            arrayColourNamesHSB.append(key)
                            dictHSB[key] = [Double(hue) / 100.0,1.0,1.0]
                        }
                        // now append the greyscale
                        for bright: Int in stride(from: 0, through: 100, by: 10) {
                            let key = String(format: "000000%03i", bright)
                            arrayColourNamesHSB.append(key)
                            dictHSB[key] = [0.0,0.0,Double(bright) / 100.0]
                        }
                        arrayNamesArrays.append(arrayColourNamesHSB)
                        // now append the dark full colour spectrum colours. the order added must match the enum ColourPalette
                        var arrayColourNamesHSBdark = [String]()
                        for hue: Int in stride(from: 0, through: 100, by: 2) {
                            let key = String(format: "%03i100050dark", hue)
                            arrayColourNamesHSBdark.append(key)
                            dictHSB[key] = [Double(hue) / 100.0,1.0,0.4]
                        }
                        arrayNamesArrays.append(arrayColourNamesHSBdark)

                        
                        
                        let dictDictArrays = DictDictArrays(coloursDoubleDict: dictHSB, arrayColourNamesArrays: arrayNamesArrays)
                        
                        if let propertyListData = try? JSONEncoder().encode(dictDictArrays) {
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
                      defaultFilename: "coloursDictArrays") { result in
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
