import SwiftUI

struct BookmarksView: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    let onSelect: (Int, Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.readingTheme) private var theme
    @State private var noteTarget: SavedAyah?
    @State private var selectedFilter: SavedAyahFilter = .notes
    private var palette: NativeGlassPalette { theme.nativeGlassPalette }

    private var notes: [SavedAyah] {
        bookmarkManager.notes
    }

    private var savedAyahs: [SavedAyah] {
        bookmarkManager.ayahsWithoutNotes
    }

    var body: some View {
        NavigationStack {
            Group {
                if bookmarkManager.savedAyahs.isEmpty {
                    ContentUnavailableView(
                        "No Saved Ayahs",
                        systemImage: "bookmark",
                        description: Text("Long press any ayah to save it or add a private note.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(24)
                    .adaptiveGlass(
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous),
                        tint: .orange.opacity(0.16),
                        fallbackFill: palette.cardFill,
                        fallbackStroke: palette.stroke
                    )
                    .padding(20)
                } else {
                    VStack(spacing: 0) {
                        Picker("Saved Ayah Filter", selection: $selectedFilter) {
                            ForEach(SavedAyahFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 6)

                        List {
                            switch selectedFilter {
                            case .notes:
                                if notes.isEmpty {
                                    emptyFilterRow(
                                        title: "No Notes Yet",
                                        description: "Add a note to any saved ayah to keep it here.",
                                        systemImage: "note.text"
                                    )
                                } else {
                                    savedSection(title: "Notes", subtitle: "Ayahs with private notes", items: notes)
                                }

                            case .savedAyahs:
                                if savedAyahs.isEmpty {
                                    emptyFilterRow(
                                        title: "No Saved Ayahs",
                                        description: "Saved ayahs without notes appear here.",
                                        systemImage: "bookmark"
                                    )
                                } else {
                                    savedSection(title: "Saved Ayahs", subtitle: "Verses saved for later", items: savedAyahs)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .background(theme.pageBackground)
                        .accessibilityIdentifier("savedAyahsList")
                    }
                    .background(theme.pageBackground)
                }
            }
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle("Saved Ayahs")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(item: $noteTarget) { savedAyah in
            SavedAyahNoteEditor(savedAyah: savedAyah, bookmarkManager: bookmarkManager)
                .presentationDetents([.medium, .large])
        }
    }

    private func savedSection(title: String, subtitle: String, items: [SavedAyah]) -> some View {
        Section {
            ForEach(items) { savedAyah in
                savedAyahRow(savedAyah)
                .onTapGesture {
                    onSelect(savedAyah.pageNumber, savedAyah.surah, savedAyah.ayah)
                    dismiss()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        bookmarkManager.removeSavedAyah(surah: savedAyah.surah, ayah: savedAyah.ayah)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }

                    Button {
                        noteTarget = savedAyah
                    } label: {
                        Label(savedAyah.hasNote ? "Edit Note" : "Add Note", systemImage: "note.text")
                    }
                    .tint(.blue)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(Color.clear)
            }
            .onDelete { offsets in
                for index in offsets {
                    let savedAyah = items[index]
                    bookmarkManager.removeSavedAyah(surah: savedAyah.surah, ayah: savedAyah.ayah)
                }
            }
        } header: {
            sectionHeader(title: title, subtitle: subtitle)
        }
    }

    private func savedAyahRow(_ savedAyah: SavedAyah) -> some View {
        rowCard(tint: savedAyah.hasNote ? .blue : .orange) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: savedAyah.hasNote ? "note.text" : "bookmark.fill")
                        .foregroundStyle(savedAyah.hasNote ? .blue : .orange)
                        .font(.title3)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(savedAyah.surahName) (\(savedAyah.reference))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.textColor)
                        Text("Page \(savedAyah.pageNumber)")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }

                    Spacer()

                    Text(savedAyah.dateUpdated, style: .date)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(theme.tertiaryTextColor)
                }

                if !savedAyah.arabicText.isEmpty {
                    Text(savedAyah.arabicText)
                        .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 20))
                        .foregroundStyle(theme.textColor)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .lineLimit(2)
                }

                if savedAyah.hasNote {
                    Text(savedAyah.note)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryTextColor)
                        .lineLimit(3)
                } else {
                    Button {
                        noteTarget = savedAyah
                    } label: {
                        Label("Add Note", systemImage: "note.text")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(
                        NativeGlassRoundedButtonStyle(
                            cornerRadius: 14,
                            tint: .blue.opacity(0.08),
                            elevated: false
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .contextMenu {
            Button {
                noteTarget = savedAyah
            } label: {
                Label(savedAyah.hasNote ? "Edit Note" : "Add Note", systemImage: "note.text")
            }

            Button(role: .destructive) {
                bookmarkManager.removeSavedAyah(surah: savedAyah.surah, ayah: savedAyah.ayah)
            } label: {
                Label("Remove Saved Ayah", systemImage: "bookmark.slash.fill")
            }
        }
    }

    private func emptyFilterRow(title: String, description: String, systemImage: String) -> some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textColor)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()
            }
            .padding(16)
            .adaptiveGlass(
                in: RoundedRectangle(cornerRadius: 20, style: .continuous),
                tint: .blue.opacity(0.08),
                fallbackFill: palette.elevatedFill,
                fallbackStroke: palette.stroke
            )
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            .listRowBackground(Color.clear)
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textColor)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .textCase(nil)
        .padding(.top, 8)
    }

    private func rowCard<Content: View>(tint: Color, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .adaptiveGlass(
            in: RoundedRectangle(cornerRadius: 22, style: .continuous),
            tint: tint.opacity(0.08),
            fallbackFill: palette.elevatedFill,
            fallbackStroke: palette.stroke
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private enum SavedAyahFilter: String, CaseIterable, Identifiable {
    case notes
    case savedAyahs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notes:
            return "Notes"
        case .savedAyahs:
            return "Saved Ayahs"
        }
    }
}

struct SavedAyahNoteEditor: View {
    let savedAyah: SavedAyah
    @ObservedObject var bookmarkManager: BookmarkManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.readingTheme) private var theme
    @State private var note: String

    init(savedAyah: SavedAyah, bookmarkManager: BookmarkManager) {
        self.savedAyah = savedAyah
        self.bookmarkManager = bookmarkManager
        _note = State(initialValue: savedAyah.note)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(savedAyah.surahName) \(savedAyah.reference)")
                        .font(.headline)
                        .foregroundStyle(theme.textColor)

                    if !savedAyah.arabicText.isEmpty {
                        Text(savedAyah.arabicText)
                            .font(.custom("KFGQPCHAFSUthmanicScript-Regula", size: 22))
                            .foregroundStyle(theme.textColor)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                TextEditor(text: $note)
                    .font(.body)
                    .foregroundStyle(theme.textColor)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 180)
                    .adaptiveGlass(
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous),
                        tint: .blue.opacity(0.08),
                        fallbackFill: theme.nativeGlassPalette.elevatedFill,
                        fallbackStroke: theme.nativeGlassPalette.stroke
                    )

                Spacer()
            }
            .padding(24)
            .background(theme.pageBackground.ignoresSafeArea())
            .navigationTitle(savedAyah.hasNote ? "Edit Note" : "Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        bookmarkManager.updateNote(
                            surah: savedAyah.surah,
                            ayah: savedAyah.ayah,
                            page: savedAyah.pageNumber,
                            surahName: savedAyah.surahName,
                            note: note
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
