import Foundation

// MARK: - Pencil Datenmodell
struct NotesPencil: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: String?              // "solid", "linearGradient", "meshGradient"
    let icon: String?
    let pencilColor: [String]
    let category: String
    let categoryIcon: String?
    let categoryIconColor: String?
    let textFieldBackground: TextFieldBackground?
}

struct TextFieldBackground: Codable {
    let type: String
    let colors: [String]
}
// MARK: - Datenlader
enum PencilDataLoader {
    
    /// Lädt Pencil-Daten aus einer JSON-Datei im Bundle.
    static func load(from fileName: String = "pencilData") -> [NotesPencil] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            log("⚠️ Datei \(fileName).json wurde nicht im Bundle gefunden.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let pencils = try JSONDecoder().decode([NotesPencil].self, from: data)
            
            // Optional: nach Titel sortieren für konsistente Anzeige
            return pencils.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        } catch {
            log("❌ Fehler beim Dekodieren von \(fileName).json: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Kurzform für Standarddatei "pencilData.json"
    static func loadAll() -> [NotesPencil] {
        load(from: "pencilData")
    }
    
    // MARK: - Debug Log
    private static func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}
