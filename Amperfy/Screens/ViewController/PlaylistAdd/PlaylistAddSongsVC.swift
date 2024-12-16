//
//  PlaylistAddSongsVC.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 15.12.24.
//  Copyright (c) 2019 Maximilian Bauer. All rights reserved.
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
import CoreData
import AmperfyKit
import PromiseKit

class PlaylistAddSongsVC: SingleFetchedResultsTableViewController<SongMO>, PlaylistVCAddable {
    
    override var sceneTitle: String? {
        switch (self.displayFilter) {
        case .all, .newest, .recent: "Songs"
        case .favorites: "Favorite Songs"
        }
    }

    private var fetchedResultsController: SongsFetchedResultsController!
    private var sortType: SongElementSortType = .name
    private var doneButton: UIBarButtonItem!
    
    public var displayFilter: DisplayCategoryFilter = .all
    public var addToPlaylistManager = AddToPlaylistManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        doneButton = addToPlaylistManager.createDoneButton()
        navigationItem.rightBarButtonItems = [doneButton]

        applyFilter()
        configureSearchController(placeholder: "Search in \"\(self.sceneTitle ?? "Songs")\"", scopeButtonTitles: ["All", "Cached"], showSearchBarAtEnter: true)
        tableView.register(nibName: PlayableTableCell.typeName)
        tableView.rowHeight = PlayableTableCell.rowHeight
        tableView.estimatedRowHeight = PlayableTableCell.rowHeight
        tableView.sectionHeaderHeight = 0.0
        tableView.estimatedSectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        tableView.estimatedSectionFooterHeight = 0.0
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        updateTitle()
        updateFromRemote()
    }
    
    func updateFromRemote() {
        guard self.appDelegate.storage.settings.isOnlineMode else { return }
        switch displayFilter {
        case .all:
            break
        case .newest, .recent:
            break
        case .favorites:
            firstly {
                self.appDelegate.librarySyncer.syncFavoriteLibraryElements()
            }.catch { error in
                self.appDelegate.eventLogger.report(topic: "Favorite Songs Sync", error: error)
            }.finally {
                self.updateSearchResults(for: self.searchController)
            }
        }
    }
    

    func applyFilter() {
        switch displayFilter {
        case .all:
            self.isIndexTitelsHidden = false
            change(sortType: appDelegate.storage.settings.songsSortSetting)
        case .newest, .recent:
            break
        case .favorites:
            self.isIndexTitelsHidden = false
            if appDelegate.backendApi.selectedApi != .ampache {
                change(sortType: appDelegate.storage.settings.favoriteSongSortSetting)
            } else {
                change(sortType: appDelegate.storage.settings.songsSortSetting)
            }
        }
    }
    
    func updateTitle() {
        setNavBarTitle(title: addToPlaylistManager.title)
    }
    
    func change(sortType: SongElementSortType) {
        self.sortType = sortType
        singleFetchedResultsController?.clearResults()
        tableView.reloadData()
        fetchedResultsController = SongsFetchedResultsController(coreDataCompanion: appDelegate.storage.main, sortType: sortType, isGroupedInAlphabeticSections: sortType.hasSectionTitles)
        fetchedResultsController.fetchResultsController.sectionIndexType = sortType.asSectionIndexType
        singleFetchedResultsController = fetchedResultsController
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PlayableTableCell = dequeueCell(for: tableView, at: indexPath)
        let song = fetchedResultsController.getWrappedEntity(at: indexPath)
        cell.display(playable: song,
                     displayMode: .add,
                     playContextCb: { _ in return nil },
                     rootView: self,
                     isMarked: addToPlaylistManager.contains(playable: song))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let item = fetchedResultsController.getWrappedEntity(at: indexPath)
        if let cell = tableView.cellForRow(at: indexPath) as? PlayableTableCell {
            cell.isMarked = addToPlaylistManager.toggleSelection(playable: item)
            cell.refresh()
            updateTitle()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sortType {
        case .name:
            return 0.0
        case .rating:
            return CommonScreenOperations.tableSectionHeightLarge
        case .duration:
            return 0.0
        case .starredDate:
            return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sortType {
        case .name:
            return super.tableView(tableView, titleForHeaderInSection: section)
        case .rating:
            if let sectionNameInitial = super.tableView(tableView, titleForHeaderInSection: section), sectionNameInitial != SectionIndexType.noRatingIndexSymbol {
                return "\(sectionNameInitial) Star\(sectionNameInitial != "1" ? "s" : "")"
            } else {
                return "Not rated"
            }
        case .duration:
            return nil
        case .starredDate:
            return nil
        }
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        if searchText.count > 0, searchController.searchBar.selectedScopeButtonIndex == 0 {
            firstly {
                self.appDelegate.librarySyncer.searchSongs(searchText: searchText)
            }.catch { error in
                self.appDelegate.eventLogger.report(topic: "Songs Search", error: error)
            }
            fetchedResultsController.search(searchText: searchText, onlyCachedSongs: false, displayFilter: displayFilter)
        } else if searchController.searchBar.selectedScopeButtonIndex == 1 {
            fetchedResultsController.search(searchText: searchText, onlyCachedSongs: true, displayFilter: displayFilter)
        } else if displayFilter != .all {
            fetchedResultsController.search(searchText: searchText, onlyCachedSongs: searchController.searchBar.selectedScopeButtonIndex == 1, displayFilter: displayFilter)
        } else {
            fetchedResultsController.showAllResults()
        }
        tableView.reloadData()
    }
    
}