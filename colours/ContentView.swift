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
    //static var writableContentTypes = [UTType.json]
    
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



typealias ColoursDict = [String : [NSNumber]]


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
            if let plistPath = Bundle.main.url(forResource: "textColourNames", withExtension: "plist") {
                do {
                    let data = try Data(contentsOf: plistPath)
                    if let array = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] {
                        //var arrayHSB = [[NSNumber]]()
                        var dictHSB = ColoursDict()
                        for colourName in array {
                            var hue        : CGFloat = 0
                            var saturation : CGFloat = 0
                            var brightness : CGFloat = 0
                            var alpha      : CGFloat = 0
                            if let colour = UIColor(named: colourName),
                            true == colour.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
                                //arrayHSB.append(
                                dictHSB[colourName] =
                                    [
                                        NSNumber(floatLiteral: hue),
                                        NSNumber(floatLiteral: saturation),
                                        NSNumber(floatLiteral: brightness)
                                    ]
                                //)
                            }
                        }
                        if let propertyListData = //try? JSONSerialization.data(withJSONObject: arrayHSB) {
                            try? PropertyListSerialization.data(fromPropertyList: dictHSB, format: .xml, options: 0) {
                            exportFileDocument = ExportFileDocument(exportArrayData: propertyListData)
                            docType = UTType.xmlPropertyList
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
                      defaultFilename: "coloursDict") { result in
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
