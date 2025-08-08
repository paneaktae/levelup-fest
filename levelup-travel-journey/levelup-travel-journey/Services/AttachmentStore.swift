//  AttachmentStore.swift
//  My Travel
//
//  Save and load attachment images in Documents/Attachments.

import UIKit

enum AttachmentStore {
    static var attachmentsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Attachments", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    @discardableResult
    static func saveImage(_ image: UIImage, preferredName: String? = nil) throws -> String {
        let name = preferredName ?? UUID().uuidString + ".jpg"
        let url = attachmentsDirectory.appendingPathComponent(name)
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "AttachmentStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode image"])
        }
        try data.write(to: url, options: .atomic)
        return url.path
    }

    static func loadImage(at path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }

    static func deleteFile(at path: String?) {
        guard let path, FileManager.default.fileExists(atPath: path) else { return }
        try? FileManager.default.removeItem(atPath: path)
    }
}
