import UIKit

@Observable
final class RecordDetailViewModel {
    var isEditing = false
    var isDeleting = false
    var showingDeleteConfirm = false
    var showingAddPhotoSource = false
    var showingCamera = false
    var showingPhotoLibrary = false
    var errorMessage: String?
    var didDelete = false

    // Edit form state
    var editArtist = ""
    var editAlbumTitle = ""
    var editYear = ""
    var editLabel = ""
    var editCatalogNumber = ""
    var editCondition: RecordCondition = .veryGoodPlus
    var editNotes = ""

    private let recordManager: IRecordManager

    init(recordManager: IRecordManager) {
        self.recordManager = recordManager
    }

    func beginEditing(record: VinylRecord) {
        editArtist = record.artist
        editAlbumTitle = record.albumTitle
        editYear = record.year.map { String($0) } ?? ""
        editLabel = record.label ?? ""
        editCatalogNumber = record.catalogNumber ?? ""
        editCondition = record.condition
        editNotes = record.notes ?? ""
        isEditing = true
    }

    func saveEdits(record: VinylRecord) async {
        let year = Int(editYear)
        let response = await recordManager.execute(EditRecordRequest(
            recordId: record.id,
            artist: editArtist.isEmpty ? nil : editArtist,
            albumTitle: editAlbumTitle.isEmpty ? nil : editAlbumTitle,
            year: year == nil && !editYear.isEmpty ? nil : .some(year),
            label: editLabel.isEmpty ? .some(nil) : .some(editLabel),
            catalogNumber: editCatalogNumber.isEmpty ? .some(nil) : .some(editCatalogNumber),
            notes: editNotes.isEmpty ? .some(nil) : .some(editNotes),
            condition: editCondition
        ))
        if response.success {
            isEditing = false
        } else {
            errorMessage = response.errorMessage ?? "Failed to save."
        }
    }

    func attachPhoto(_ image: UIImage, to record: VinylRecord) async {
        let response = await recordManager.execute(AttachPhotoRequest(recordId: record.id, image: image))
        if !response.success {
            errorMessage = response.errorMessage ?? "Failed to save photo."
        }
    }

    func deleteRecord(_ record: VinylRecord) async {
        isDeleting = true
        defer { isDeleting = false }
        let response = await recordManager.execute(RemoveRecordRequest(recordId: record.id))
        if response.success {
            didDelete = true
        } else {
            errorMessage = response.errorMessage ?? "Failed to delete."
        }
    }
}
