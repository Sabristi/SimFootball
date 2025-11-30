import Foundation

class GameDatabase {
    // Singleton : accessible de partout via GameDatabase.shared
    static let shared = GameDatabase()
    
    // MARK: - Données Statiques (chargées au démarrage)
    var confederations: [Confederation] = []
    var countries: [Country] = []
    var cities: [City] = []
    var stadiums: [Stadium] = []
    var clubs: [Club] = []
    var competitions: [Competition] = []
    
    // Données de configuration de saison
    var competitionSeasons: [CompetitionSeason] = []
    
    // MARK: - Données Dynamiques (Simulation)
    var matches: [Match] = []
    var matchDays: [MatchDay] = []
    
    // NOUVEAU : Les classements (League Tables)
    var leagueTables: [LeagueTableEntry] = []
    
    var calendarDays: [SeasonCalendarDay] = []
    var calendarEvents: [SeasonCalendarEvent] = []
    
    // MARK: - Initialisation
    private init() {
        print("📂 [GameDatabase] Initialisation du moteur de données...")
        loadAllData()
    }
    
    /// Charge tous les fichiers JSON et initialise l'état du jeu
    func loadAllData() {
        print("⏳ Chargement des données...")
        
        // 1. Géographie & Infrastructures
        self.confederations = DataLoader.load("Confederations.json")
        self.countries = DataLoader.load("Countries.json")
        self.cities = DataLoader.load("Cities.json")
        self.stadiums = DataLoader.load("Stadiums.json")
        self.competitions = DataLoader.load("Competitions.json")
        
        // 2. Entités Sportives (Clubs)
        if Bundle.main.url(forResource: "Clubs.json", withExtension: nil) != nil {
             self.clubs = DataLoader.load("Clubs.json")
        }
        
        // 3. Configurations de Saisons (INDISPENSABLE POUR LE TIRAGE)
        if Bundle.main.url(forResource: "CompetitionSeasons.json", withExtension: nil) != nil {
            self.competitionSeasons = DataLoader.load("CompetitionSeasons.json")
            print("   ✅ \(competitionSeasons.count) Saisons de compétition chargées.")
        }
        
        // 4. Calendrier & Matchs
        if Bundle.main.url(forResource: "Matches.json", withExtension: nil) != nil {
            self.matches = DataLoader.load("Matches.json")
            print("   ✅ \(matches.count) Matchs chargés.")
        }
        
        if Bundle.main.url(forResource: "MatchDays.json", withExtension: nil) != nil {
            self.matchDays = DataLoader.load("MatchDays.json")
            print("   ✅ \(matchDays.count) Journées chargées.")
        }
        
        if Bundle.main.url(forResource: "SeasonCalendarEvents.json", withExtension: nil) != nil {
            self.calendarEvents = DataLoader.load("SeasonCalendarEvents.json")
            print("   ✅ \(calendarEvents.count) Événements chargés.")
        }
        
        if Bundle.main.url(forResource: "SeasonCalendarDays.json", withExtension: nil) != nil {
            self.calendarDays = DataLoader.load("SeasonCalendarDays.json")
            print("   ✅ \(calendarDays.count) Jours de calendrier chargés.")
        }
        
        // Note: leagueTables est vide au démarrage, rempli par la simulation.
        
        print("✅ Base de données chargée :")
        print("   - \(countries.count) Pays")
        print("   - \(cities.count) Villes")
        print("   - \(stadiums.count) Stades")
        print("   - \(clubs.count) Clubs")
    }
    
    // MARK: - Helpers : Géographie
    
    func getCountry(byId id: String) -> Country? {
        return countries.first { $0.id == id }
    }
    
    func getCity(byId id: String) -> City? {
        return cities.first { $0.id == id }
    }
    
    func getStadium(byId id: String) -> Stadium? {
        return stadiums.first { $0.id == id }
    }
    
    func getStadiums(forCountry countryId: String) -> [Stadium] {
        return stadiums.filter { $0.countryId == countryId }
    }
    
    // MARK: - Helpers : Clubs
    
    func getClub(byId id: String) -> Club? {
        return clubs.first { $0.id == id }
    }
    
    func getClubs(forCountry countryId: String) -> [Club] {
        return clubs.filter { $0.countryId == countryId }
    }
    
    // MARK: - Helpers : Compétitions
    
    func getCompetitionSeason(competitionId: String, seasonId: String) -> CompetitionSeason? {
        return competitionSeasons.first {
            $0.competitionId == competitionId && $0.seasonId == seasonId
        }
    }
    
    // Récupérer le classement d'une compétition
    func getLeagueTable(competitionId: String, seasonId: String) -> [LeagueTableEntry] {
        return leagueTables
            .filter { $0.competitionId == competitionId && $0.seasonId == seasonId }
            .sorted {
                // Tri par Points > Diff > Buts Pour
                if $0.points != $1.points { return $0.points > $1.points }
                if $0.goalDifference != $1.goalDifference { return $0.goalDifference > $1.goalDifference }
                return $0.goalsFor > $1.goalsFor
            }
    }
    
    func getCompetitions(forCountry countryId: String) -> [Competition] {
        return competitions.filter { $0.countryId == countryId }
    }
    
    // MARK: - Helpers : Calendrier & Matchs
    
    func getMatchDays(forDate date: Date) -> [MatchDay] {
        let calendar = Calendar.current
        guard let day = calendarDays.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else { return [] }
        return matchDays.filter { day.matchDayIds.contains($0.id) }
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
        
        let allMatches = Array(Set(matchesFromDays + matchesDirect))
        return allMatches.sorted {
            ($0.kickoffTime ?? Date.distantFuture) < ($1.kickoffTime ?? Date.distantFuture)
        }
    }
    
    func getEvents(forDate date: Date) -> [SeasonCalendarEvent] {
        let calendar = Calendar.current
        guard let day = calendarDays.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else { return [] }
        return calendarEvents.filter { day.eventIds.contains($0.id) }
    }
    
    func getNextActiveDate(after currentDate: Date) -> Date? {
        let futureDays = calendarDays
            .filter { $0.date > currentDate }
            .filter { !$0.matchDayIds.isEmpty || !$0.eventIds.isEmpty }
            .sorted { $0.date < $1.date }
        return futureDays.first?.date
    }
}
