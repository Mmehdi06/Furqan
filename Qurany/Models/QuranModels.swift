import Foundation

enum LineType: String {
    case ayah
    case basmallah
    case surahName = "surah_name"
}

struct QuranWord: Identifiable {
    let id: Int
    let location: String
    let surah: Int
    let ayah: Int
    let wordPosition: Int
    let text: String

    var isVerseNumber: Bool {
        let arabicIndicDigits = CharacterSet(charactersIn: "٠١٢٣٤٥٦٧٨٩")
        return text.unicodeScalars.allSatisfy { arabicIndicDigits.contains($0) }
    }
}

struct QuranLine: Identifiable {
    let id: String
    let lineNumber: Int
    let lineType: LineType
    let isCentered: Bool
    let surahNumber: Int?
    let words: [QuranWord]
}

struct QuranPage: Identifiable {
    let id: Int
    let lines: [QuranLine]
}
