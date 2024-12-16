//
//  PlaylistEditVC.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 06.12.24.
//  Copyright (c) 2024 Maximilian Bauer. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import AmperfyKit
import PromiseKit
import CoreData

enum PlaylistEditMode {
    case reorder
    case delete
}

class PlaylistEditVC: SingleSnapshotFetchedResultsTableViewController<PlaylistItemMO> {

    override var sceneTitle: String? { playlist.name }
    
    private var fetchedResultsController: PlaylistItemsFetchedResultsController!

    var playlist: Playlist!
    var onDoneCB: VoidFunctionCallback?
    
    private var doneButton: UIBarButtonItem!
    private var selectBarButton: UIBarButtonItem!
    private var deleteBarButton: UIBarButtonItem!
    private var addBarButton: UIBarButtonItem!

    var detailOperationsView: GenericDetailTableHeader?
    
    private var selectedItems = [PlaylistItem]()
    private var editMode = PlaylistEditMode.reorder
    
    override func createDiffableDataSource() -> BasicUITableViewDiffableDataSource {
        let source = PlaylistDetailDiffableDataSource(tableView: tableView) { (tableView, indexPath, objectID) -> UITableViewCell? in
            guard let object = try? self.appDelegate.storage.main.context.existingObject(with: objectID),
                  let playlistItemMO = object as? PlaylistItemMO
            else {
                return UITableViewCell()
            }
            let playlistItem = PlaylistItem(library: self.appDelegate.storage.main.library, managedObject: playlistItemMO)
            return self.createCell(tableView, forRowAt: indexPath, playlistItem: playlistItem)
        }
        source.playlist = playlist
        return source
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        fetchedResultsController = PlaylistItemsFetchedResultsController(forPlaylist: playlist, coreDataCompanion: appDelegate.storage.main, isGroupedInAlphabeticSections: false)
        singleFetchedResultsController = fetchedResultsController
        singleFetchedResultsController?.delegate = self
        singleFetchedResultsController?.fetch()
        
        tableView.register(nibName: PlayableTableCell.typeName)
        tableView.rowHeight = PlayableTableCell.rowHeight
        tableView.estimatedRowHeight = PlayableTableCell.rowHeight

        let detailHeaderConfig = DetailHeaderConfiguration(entityContainer: playlist, rootView: self, tableView: tableView, playShuffleInfoConfig: nil)
        detailOperationsView = GenericDetailTableHeader.createTableHeader(configuration: detailHeaderConfig)
        
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = true
        tableView.allowsSelectionDuringEditing = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        detailOperationsView?.startEditing()
        
        navigationController?.setToolbarHidden(false, animated: false)
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        selectBarButton = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectBarButtonPressed))
        deleteBarButton = UIBarButtonItem(image: .trash, style: .plain, target: self, action: #selector(deleteBarButtonPressed))
        addBarButton    = UIBarButtonItem(image: .plus, style: .plain, target: self, action: #selector(addBarButtonPressed))
        self.toolbarItems = [selectBarButton, flexible, addBarButton, flexible, deleteBarButton]
        
        changeEditMode(.reorder)
        refreshBarButtons()
    }
    
    func changeEditMode(_ newMode: PlaylistEditMode) {
        editMode = newMode
        (diffableDataSource as? PlaylistDetailDiffableDataSource)?.isMoveAllowed = (editMode == .reorder)
        (diffableDataSource as? PlaylistDetailDiffableDataSource)?.isEditAllowed = true
        selectedItems.removeAll()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        detailOperationsView?.endEditing()
        onDoneCB?()
    }
    
    @IBAction func doneBarButtonPressed(_ sender: UIBarButtonItem) {
        dismiss()
    }
    
    @IBAction func selectBarButtonPressed(_ sender: Any) {
        changeEditMode((editMode == .reorder) ? .delete : .reorder)
        selectBarButton.title = (editMode == .reorder) ? "Select" : "Reorder"
        refreshDeleteButton()
    }
    
    func refreshDeleteButton() {
        deleteBarButton.isEnabled = !selectedItems.isEmpty
    }
    
    @IBAction func deleteBarButtonPressed(_ sender: Any) {
        let selectedItemsSorted = selectedItems.sorted(by: { $0.order > $1.order })
        var syncPromises = [() -> Promise<Void>]()

        syncPromises = selectedItemsSorted.compactMap { item in
            return { return firstly {
                self.appDelegate.librarySyncer.syncUpload(playlistToDeleteSong: self.playlist, index: item.order)
            }.then {
                self.playlist?.remove(at: item.order)
                return Promise.value
            }}
        }
        firstly {
            syncPromises.resolveSequentially()
        }
        .catch { error in
            self.appDelegate.eventLogger.report(topic: "Playlist Upload Entry Remove", error: error)
        }
        .finally {
            self.detailOperationsView?.refresh()
        }

        selectedItems.removeAll()
        refreshDeleteButton()
    }
    
    @IBAction func addBarButtonPressed(_ sender: Any) {
        let playlistAddVC = PlaylistAddLibraryVC()
        playlistAddVC.addToPlaylistManager.playlist = self.playlist
        playlistAddVC.addToPlaylistManager.onDoneCB = {
            self.detailOperationsView?.refresh()
            self.tableView.reloadData()
        }
        let playlistAddNav = UINavigationController(rootViewController: playlistAddVC)
        self.present(playlistAddNav, animated: true, completion: nil)
    }
    
    private func dismiss() {
        dismiss(animated: true, completion: nil)
    }

    func refreshBarButtons() {
        doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneBarButtonPressed))
        refreshDeleteButton()
        
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItem = doneButton
    }

    func createCell(_ tableView: UITableView, forRowAt indexPath: IndexPath, playlistItem: PlaylistItem) -> UITableViewCell {
        let cell: PlayableTableCell = tableView.dequeueCell(for: tableView, at: indexPath)
        if let playable = playlistItem.playable, let song = playable.asSong {
            cell.display(
                playable: song,
                displayMode: (editMode == .reorder) ? .reorder : .selection,
                playContextCb: { _ in return nil },
                rootView: self,
                isMarked: (selectedItems.firstIndex { $0 == playlistItem } != nil))
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard (editMode == .delete) else { return }
        
        let item = fetchedResultsController.getWrappedEntity(at: indexPath)
        if let cell = tableView.cellForRow(at: indexPath) as? PlayableTableCell {
            let markedIndex = selectedItems.firstIndex { $0 == item }
            if let markedIndex = markedIndex {
                selectedItems.remove(at: markedIndex)
                cell.isMarked = false
            } else {
                selectedItems.append(item)
                cell.isMarked = true
            }
            cell.refresh()
        }
        refreshDeleteButton()
    }

}

extension PlaylistEditVC: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // Create empty DragItem -> we are using tableView(_:moveRowAt:to:) method
        return [UIDragItem]()
    }
    
    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameter = UIDragPreviewParameters()
        parameter.backgroundColor = .clear
        return parameter
    }
}

extension PlaylistEditVC: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        // Local drags with one item go through the existing tableView(_:moveRowAt:to:) method on the data source
        return
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        return
    }
    
    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameter = UIDragPreviewParameters()
        return parameter
    }
}