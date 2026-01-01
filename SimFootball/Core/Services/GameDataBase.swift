//
//  GameDatabase.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import Foundation
import SwiftUI
import Combine

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - 1. STRUCTURES DE SAUVEGARDE

// MARK: - 1. STRUCTURES DE SAUVEGARDE

struct SaveData: Codable {
    var id: String = UUID().uuidString
    var saveName: String = "Save 1"
    var gameVersion: String = "0.1.0"
    var currentDate: Date = Date()
    var currentSeasonId: String = "S_2025_26"
    
    var selectedCountries: [Country] = []
    
    var savedMatches: [Match] = []
    var savedLeagueTables: [LeagueTableEntry] = []
    var savedCompetitionSeasons: [CompetitionSeason] = []
    var savedCalendarEvents: [SeasonCalendarEvent] = []
    var savedMatchDays: [MatchDay] = []
    
    var competitionHistory: [CompetitionHistoryEntry] = []
    var savedTeamHistories: [TeamSeasonHistory] = []
    var currentCycleYear: Int = 3
    
    init() {}
    
    // 🛡️ INIT DE DÉCODAGE ULTRA-SÉCURISÉ
    // Chaque champ est tenté individuellement. Si l'un échoue, les autres survivent.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        saveName = (try? container.decode(String.self, forKey: .saveName)) ?? "Save Récupérée"
        gameVersion = (try? container.decode(String.self, forKey: .gameVersion)) ?? "0.1.0"
        currentDate = (try? container.decode(Date.self, forKey: .currentDate)) ?? Date()
        currentSeasonId = (try? container.decode(String.self, forKey: .currentSeasonId)) ?? "S_2025_26"
        
        // --- LE TEST CRITIQUE ---
        do {
            selectedCountries = try container.decode([Country].self, forKey: .selectedCountries)
        } catch {
            print("❌ ERREUR DECODAGE PAYS : \(error)") // Ceci apparaîtra si ça plante ici
            selectedCountries = []
        }
        // ------------------------
        
        savedMatches = (try? container.decode([Match].self, forKey: .savedMatches)) ?? []
        savedLeagueTables = (try? container.decode([LeagueTableEntry].self, forKey: .savedLeagueTables)) ?? []
        savedCompetitionSeasons = (try? container.decode([CompetitionSeason].self, forKey: .savedCompetitionSeasons)) ?? []
        savedCalendarEvents = (try? container.decode([SeasonCalendarEvent].self, forKey: .savedCalendarEvents)) ?? []
        savedMatchDays = (try? container.decode([MatchDay].self, forKey: .savedMatchDays)) ?? []
        competitionHistory = (try? container.decode([CompetitionHistoryEntry].self, forKey: .competitionHistory)) ?? []
        
        // Gestion de la clé manquante sans faire planter tout le fichier
        savedTeamHistories = (try? container.decode([TeamSeasonHistory].self, forKey: .savedTeamHistories)) ?? []
        
        currentCycleYear = (try? container.decode(Int.self, forKey: .currentCycleYear)) ?? 3
    }
}

// MARK: - 2. GAME DATABASE (SINGLETON)

class GameDatabase: ObservableObject {
    
    static let shared = GameDatabase()
    
    // Données Statiques
    @Published var confederations: [Confederation] = []
    @Published var countries: [Country] = []
    @Published var cities: [City] = []
    @Published var stadiums: [Stadium] = []
    @Published var clubs: [Club] = []
    @Published var competitions: [Competition] = []
    @Published var seasons: [Season] = []
    
    // Données de Sauvegarde
    @Published var currentSave: SaveData? = nil
    
    // Raccourcis Dynamiques
    @Published var matches: [Match] = []
    @Published var matchDays: [MatchDay] = []
    @Published var leagueTables: [LeagueTableEntry] = []
    @Published var calendarEvents: [SeasonCalendarEvent] = []
    @Published var competitionSeasons: [CompetitionSeason] = []
    @Published var teamHistories: [TeamSeasonHistory] = []
    
    @Published var calendarDays: [SeasonCalendarDay] = []
    
    private let saveFileName = "save_1.json"
    
    private init() {
        print("📂 [GameDatabase] Initialisation...")
        loadAllData()
    }
    
    func loadAllData() {
        print("⏳ Chargement des données...")
        
        self.confederations = DataLoader.load("Confederations.json")
        self.countries = DataLoader.load("Countries.json")
        self.cities = DataLoader.load("Cities.json")
        self.stadiums = DataLoader.load("Stadiums.json")
        self.clubs = DataLoader.load("Clubs.json")
        self.competitions = DataLoader.load("Competitions.json")
        self.seasons = DataLoader.load("Seasons.json")
        
        loadSimulationData()
        
        print("✅ Base de données chargée.")
    }
    
    // MARK: - CHARGEMENT SAUVEGARDE (ROBUSTE)
    func loadSimulationData() {
            let url = getFileURL(forName: saveFileName)
            
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    
                    // ✅ INDISPENSABLE
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let decodedSave = try decoder.decode(SaveData.self, from: data)
                    
                    print("💿 Sauvegarde chargée !")
                    print("✅ PAYS RECUPERÉS : \(decodedSave.selectedCountries.count)") // Doit afficher 1
                    
                    applySaveData(decodedSave)
                    
                } catch {
                    print("❌ Erreur FATALE SaveData : \(error)")
                    startNewGame()
                }
            } else {
                startNewGame()
            }
    }
    
    func startNewGame() {
        print("🚀 Initialisation d'une nouvelle partie...")
        var newSave = SaveData()
        let currentSeasonId = "S_2025_26"
        
        // Chargement des templates
        if let templateMatches: [Match] = loadSafeTemplate("Matches.json") { newSave.savedMatches = templateMatches }
        if let templateDays: [MatchDay] = loadSafeTemplate("MatchDays.json") { newSave.savedMatchDays = templateDays }
        if let templateCompSeasons: [CompetitionSeason] = loadSafeTemplate("CompetitionSeasons.json") { newSave.savedCompetitionSeasons = templateCompSeasons }
        
        if let templateEvents: [SeasonCalendarEvent] = loadSafeTemplate("SeasonCalendarEvents.json") {
            newSave.savedCalendarEvents = templateEvents
            print("📅 Calendrier initialisé.")
        }
        
        if var templateTables: [LeagueTableEntry] = loadSafeTemplate("Tables.json") {
            for i in 0..<templateTables.count {
                if templateTables[i].seasonId == "TEMPLATE" {
                    templateTables[i].seasonId = currentSeasonId
                    if templateTables[i].competitionId == "COMP-MAR-BP1" {
                        templateTables[i].competitionSeasonId = "COMP-MAR-BP1_S_2025_26"
                    }
                }
            }
            newSave.savedLeagueTables = templateTables
            print("📊 Classement initialisé.")
        }
        
        // Import Historique
        let staticHistory = self.competitions.flatMap { $0.history ?? [] }
        newSave.competitionHistory = staticHistory
        print("🏆 Historique importé.")
        
        // ⚠️ Si on démarre une nouvelle partie, selectedCountries est vide par défaut
        // C'est peut-être là qu'il faut en ajouter un par défaut si besoin
        // newSave.selectedCountries = [self.countries.first(where: { $0.id == "MAR" })].compactMap { $0 }
        
        applySaveData(newSave)
    }
    
    func resetSimulationData() {
        startNewGame()
    }
    
    func applySaveData(_ save: SaveData) {
        self.currentSave = save
        
        // Dispatch aux variables publiées
        self.matches = save.savedMatches
        self.matchDays = save.savedMatchDays
        self.leagueTables = save.savedLeagueTables
        self.calendarEvents = save.savedCalendarEvents
        self.competitionSeasons = save.savedCompetitionSeasons
        self.teamHistories = save.savedTeamHistories
    }
    
    func saveAllData() {
        print("\n💾 [GameDatabase] Sauvegarde...")
        guard var saveToUpdate = self.currentSave else { return }
        
        // Mise à jour de l'objet SaveData avec les données en mémoire
        saveToUpdate.savedMatches = self.matches
        saveToUpdate.savedMatchDays = self.matchDays
        saveToUpdate.savedLeagueTables = self.leagueTables
        saveToUpdate.savedCalendarEvents = self.calendarEvents
        saveToUpdate.savedCompetitionSeasons = self.competitionSeasons
        saveToUpdate.savedTeamHistories = self.teamHistories
        
        let url = getFileURL(forName: saveFileName)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601 // Important pour la cohérence
            
            let data = try encoder.encode(saveToUpdate)
            try data.write(to: url)
            
            self.currentSave = saveToUpdate
            print("✅ Sauvegardé : \(saveFileName)")
        } catch {
            print("❌ Erreur sauvegarde : \(error)")
        }
    }
    
    // MARK: - Helpers & Utils (inchangés mais nécessaires)
    
    func saveMatches() { saveAllData() }
    func saveCompetitionSeasons() { saveAllData() }
    func saveMatchDays() { saveAllData() }
    func saveLeagueTables() { saveAllData() }
    func saveCalendarEvents() { saveAllData() }
    
    func saveClubs() { saveData(clubs, to: "Clubs.json") }
    func saveCompetitions() { saveData(competitions, to: "Competitions.json") }
    func saveSeasons() { saveData(seasons, to: "Seasons.json") }
    
    private func saveData<T: Encodable>(_ data: T, to filename: String) {
        let url = getFileURL(forName: filename)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: url)
        } catch { print("❌ Erreur save éditeur : \(error)") }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getFileURL(forName name: String) -> URL {
        getDocumentsDirectory().appendingPathComponent(name)
    }
    
    private func loadSafeTemplate<T: Decodable>(_ filename: String) -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }
    
    // Getters
    func getCountry(byId id: String) -> Country? { return countries.first { $0.id == id } }
    func getCity(byId id: String) -> City? { return cities.first { $0.id == id } }
    func getStadium(byId id: String) -> Stadium? { return stadiums.first { $0.id == id } }
    func getClub(byId id: String) -> Club? { return clubs.first { $0.id == id } }
    
    func getKit(forClub clubId: String, type: KitType) -> Kit? {
        return getClub(byId: clubId)?.getKit(type)
    }
    
    func getStadiums(forCountry countryId: String) -> [Stadium] { return stadiums.filter { $0.countryId == countryId } }
    func getClubs(forCountry countryId: String) -> [Club] { return clubs.filter { $0.countryId == countryId } }
    func getClubs(forLeague leagueId: String) -> [Club] { return clubs.filter { $0.leagueId == leagueId } }
    func getCompetitions(forCountry countryId: String) -> [Competition] { return competitions.filter { $0.countryId == countryId } }
    
    func getActiveDomesticCompetitions() -> [Competition] {
        guard let save = currentSave else { return [] }
        let allowedCountryIDs = save.selectedCountries.map { $0.id }
        return competitions.filter { competition in
            let isDomestic = (competition.scope == .domestic)
            let isCountryAllowed = allowedCountryIDs.contains(competition.countryId)
            return isDomestic && isCountryAllowed
        }
    }
    
    func getCompetitionSeason(competitionId: String, seasonId: String) -> CompetitionSeason? {
        competitionSeasons.first { $0.competitionId == competitionId && $0.seasonId == seasonId }
    }
    
    func getLeagueTable(competitionId: String, seasonId: String) -> [LeagueTableEntry] {
        return leagueTables
            .filter { $0.competitionId == competitionId && $0.seasonId == seasonId }
            .sorted {
                if $0.points != $1.points { return $0.points > $1.points }
                if $0.goalDifference != $1.goalDifference { return $0.goalDifference > $1.goalDifference }
                return $0.goalsFor > $1.goalsFor
            }
    }
    
    func getTeamPosition(teamId: String, tableId: String) -> Int? {
        leagueTables.first(where: { $0.teamId == teamId && $0.tableId == tableId })?.position
    }
    
    func getMatchDays(forDate date: Date) -> [MatchDay] {
        let calendar = Calendar.current
        return matchDays.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func getEvents(forDate targetDate: Date) -> [SeasonCalendarEvent] {
        let calendar = Calendar.current
        return calendarEvents.filter { event in
            guard let eventDate = event.date else { return false }
            return calendar.isDate(eventDate, inSameDayAs: targetDate)
        }
    }
    
    func getMatches(forDate date: Date) -> [Match] {
        let calendar = Calendar.current
        let activeMatchDays = getMatchDays(forDate: date)
        let activeMatchDayIds = activeMatchDays.map { $0.id }
        let matchesFromDays = matches.filter { activeMatchDayIds.contains($0.matchDayId) }
        let matchesDirect = matches.filter { match in
            guard let time = match.kickoffTime else { return false }
            return calendar.isDate(time, inSameDayAs: date)
        }
        return Array(Set(matchesFromDays + matchesDirect)).sorted { ($0.kickoffTime ?? Date.distantFuture) < ($1.kickoffTime ?? Date.distantFuture) }
    }
    
    func getNextActiveDate(after currentDate: Date) -> Date? {
        // Logique simplifiée pour l'exemple
        return nil
    }
    
    func getHistory(forTeam teamId: String) -> [TeamSeasonHistory] {
        return teamHistories.filter { $0.teamId == teamId }.sorted { $0.seasonId > $1.seasonId }
    }
    
    func getTrophyCabinet(forTeam teamId: String) -> [TrophyItem] {
        return []
    }
    
    func exportJSONToClipboard() {}
}
