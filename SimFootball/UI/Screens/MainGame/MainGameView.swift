//
//  MainGameView.swift
//  SimFootball
//
//  Created by Sabri Benhadda on 26/11/2025.
//

import SwiftUI

// Structure pour l'historique de navigation
struct NavigationState: Equatable {
    let tab: GameTab
    let contextId: String? // ID Club ou Compétition
}

struct MainGameView: View {
    @Environment(\.dismiss) var dismiss
    
    // --- ÉTATS DU JEU ---
    @State var gameState: GameState
    
    // --- NAVIGATION PRINCIPALE ---
    @State private var currentTab: GameTab = .inbox
    @State private var showCalendar: Bool = false
    
    // --- NAVIGATION HISTORY ---
    @State private var backStack: [NavigationState] = []
    @State private var forwardStack: [NavigationState] = []
    
    // --- ÉTATS MENU LATÉRAL (FLYOUT) ---
    @State private var showSideMenu: Bool = false
    @State private var sideMenuTitle: String = ""
    @State private var sideMenuIcon: String = ""
    @State private var sideMenuItems: [SideMenuItem] = []
    
    // --- NAVIGATION CONTEXTUELLE ---
    @State private var selectedCompetitionContext: String? // ID de la ligue
    @State private var selectedClubContext: String?        // ID du club
    @State private var currentClubTab: ClubTab = .overview // Mémoire de l'onglet club actif
    
    // --- ÉTATS INBOX ---
    @State private var selectedMessageId: String?
    
    // --- ÉTATS ÉVÉNEMENTS SPÉCIAUX ---
    @State private var showDrawPopup: Bool = false
    @State private var currentEventActionContext: String?
    
    // --- ÉTAT SIMULATION ---
    @State private var showSimulationOverlay: Bool = false
    
    // --- ÉTAT TRANSITION SAISON ---
    @State private var showNewSeasonPopup: Bool = false
    
    // MARK: - LOGIQUE MÉTIER INBOX
    
    var inboxMessages: [SeasonCalendarEvent] {
        GameDatabase.shared.calendarEvents
            .filter { event in
                guard let eventDate = event.date else { return false }
                let comparison = Calendar.current.compare(eventDate, to: gameState.currentDate, toGranularity: .day)
                return comparison != .orderedDescending
            }
            .sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
    }
    
    var unreadCount: Int {
        inboxMessages.filter { !gameState.readEventIds.contains($0.id) }.count
    }
    
    var hasBlockingActions: Bool {
        return inboxMessages.contains { event in
            if let action = event.action {
                return !action.isCompleted
            }
            return false
        }
    }
    
    // MARK: - LOGIQUE HEADER DYNAMIQUE
    
    // 1. Calcul du Titre
    var headerTitle: String {
        if currentTab == .league {
            if let id = selectedCompetitionContext,
               let comp = GameDatabase.shared.competitions.first(where: { $0.id == id }) {
                return comp.shortName
            }
            return "Competition"
        }
        if currentTab == .club {
            if let id = selectedClubContext,
               let club = GameDatabase.shared.getClub(byId: id) {
                return club.name
            }
            return "Club"
        }
        if currentTab == .primaryCountry {
            return gameState.selectedCountries.first?.name ?? "Country"
        }
        return currentTab.title
    }
    
    // 2. Calcul du Sous-titre
    var headerSubtitle: String? {
        switch currentTab {
        case .league:
            if let id = selectedCompetitionContext {
                let season = GameDatabase.shared.getCompetitionSeason(
                    competitionId: id,
                    seasonId: gameState.currentSeasonId
                )
                return "SEASON \(season?.yearLabel ?? "Unknown")"
            }
            return nil
            
        case .club:
            if let id = selectedClubContext,
               let club = GameDatabase.shared.getClub(byId: id),
               let city = GameDatabase.shared.getCity(byId: club.cityId ?? "") {
                return city.name.uppercased()
            }
            return nil
            
        case .matchDay:
            return "LIVE RESULTS"
            
        case .primaryCountry:
            return gameState.selectedCountries.first?.continent.uppercased()
            
        default:
            return nil
        }
    }
    
    // 3. Calcul de l'ID Compétition (pour le logo)
    var headerCompetitionId: String? {
        if currentTab == .league { return selectedCompetitionContext }
        return nil
    }
    
    // 4. Calcul du Pays
    var headerCountry: Country? {
        if currentTab == .primaryCountry { return gameState.selectedCountries.first }
        return nil
    }
    
    // MARK: - CORPS DE LA VUE
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            // 1. FOND GLOBAL
            Color.black.ignoresSafeArea()
            ZStack {
                Circle().fill(Color.green.opacity(0.1)).frame(width: 800).blur(radius: 150).offset(x: -200, y: -300)
                Circle().fill(Color.blue.opacity(0.08)).frame(width: 600).blur(radius: 120).offset(x: 400, y: 200)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // 2. HEADER
                MainGameHeader(
                    title: headerTitle,
                    subtitle: headerSubtitle,
                    icon: currentTab.icon,
                    competitionId: headerCompetitionId,
                    country: headerCountry,
                    
                    // ✅ NAVIGATION CLUB ACTIVÉE
                    showClubNavigation: currentTab == .club,
                    onClubNavigation: { direction in
                        navigateClub(direction: direction)
                    },
                    
                    currentDate: gameState.currentDate,
                    onBack: {
                        if !backStack.isEmpty {
                            goBack()
                        } else {
                            // Si pas d'historique, retour accueil ou fermeture
                            if currentTab != .home {
                                navigateTo(tab: .home)
                            } else {
                                dismiss()
                            }
                        }
                    },
                    onContinue: handleContinueButton,
                    onCalendarClick: { showCalendar = true }
                )
                .zIndex(20)
                
                // 3. STRUCTURE PRINCIPALE
                HStack(spacing: 0) {
                    
                    // A. SIDEBAR
                    MainGameSidebar(
                        selectedTab: Binding(
                            get: { currentTab },
                            set: { newValue in navigateTo(tab: newValue) } // Intercepte le changement pour l'historique
                        ),
                        unreadCount: unreadCount,
                        primaryCountry: gameState.selectedCountries.first,
                        onPrimaryCountryClick: {
                            openPrimaryCountryMenu()
                        }
                    )
                    .zIndex(15)
                    
                    // B. ZONE DE CONTENU
                    ZStack {
                        Color.clear
                        
                        switch currentTab {
                        case .inbox:
                            inboxView
                            
                        case .primaryCountry:
                            if let country = gameState.selectedCountries.first {
                                VStack(spacing: 20) {
                                    Text(country.flagEmoji).font(.system(size: 80))
                                    Text(country.name.uppercased())
                                        .font(.headline).fontWeight(.black).foregroundColor(.white)
                                    Text("Utilisez le menu latéral pour naviguer").foregroundColor(.gray)
                                }
                            } else {
                                Text("No Country Selected").foregroundColor(.gray)
                            }
                            
                        case .home:
                            Text("Manager Dashboard").font(.title).foregroundColor(.white)
                            
                        case .league:
                            if let compId = selectedCompetitionContext {
                                // ✅ ON UTILISE LA NOUVELLE VUE ROUTEUR
                                CompetitionDetailsView(
                                    competitionId: compId,
                                    seasonId: gameState.currentSeasonId
                                )
                            } else {
                                Text("No Competition Selected").foregroundColor(.gray)
                            }
                            
                        case .club: // ✅ INTÉGRATION VUE CLUB
                            if let clubId = selectedClubContext {
                                ClubDetailsView(
                                    clubId: clubId,
                                    seasonId: gameState.currentSeasonId,
                                    selectedTab: $currentClubTab // Passe le binding pour conserver l'onglet
                                )
                                .id(clubId) // Force le refresh lors de la navigation
                                .transition(.opacity)
                            } else {
                                Text("No Club Selected").foregroundColor(.gray)
                            }
                            
                        case .matchDay:
                            MatchDayView(
                                date: gameState.currentDate,
                                onCompetitionTap: { competitionId in
                                    self.navigateTo(tab: .league, contextId: competitionId)
                                }
                            )
                            
                        default:
                            Text("Module: \(currentTab.title)").foregroundColor(.gray)
                        }
                        
                        // 4. MENU LATÉRAL
                        if showSideMenu {
                            HStack(spacing: 0) {
                                SideMenuPanel(
                                    title: sideMenuTitle,
                                    headerIcon: sideMenuIcon,
                                    items: sideMenuItems,
                                    isPresented: $showSideMenu
                                )
                                Spacer()
                            }
                            .zIndex(30)
                            .transition(.move(edge: .leading))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
            }
            
            // 5. POPUP TIRAGE
            if showDrawPopup {
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea()
                        .onTapGesture { showDrawPopup = false }
                    
                    if let context = currentEventActionContext, context == "COMP-MAR-CT" {
                        // 🏆 CAS SPÉCIAL : COUPE DU TRÔNE
                        CupDrawView(
                            roundId: currentRoundId,
                            seasonId: gameState.currentSeasonId,
                            onDismiss: {
                                self.showDrawPopup = false
                                if let msgId = selectedMessageId { markActionAsCompleted(eventId: msgId) }
                            }
                        )
                        .frame(maxWidth: 800, maxHeight: 600)
                        .cornerRadius(20)
                        .shadow(radius: 20)
                        
                    } else {
                        // ⚽️ CAS CLASSIQUE : CHAMPIONNAT (Botola)
                        CompetitionDrawView(
                            competitionId: currentEventActionContext ?? "",
                            seasonId: gameState.currentSeasonId,
                            onClose: { showDrawPopup = false },
                            onComplete: {
                                if let msgId = selectedMessageId { markActionAsCompleted(eventId: msgId) }
                                showDrawPopup = false
                            }
                        )
                    }
                }
                .zIndex(100)
                .transition(.opacity)
            }
            
            // 6. OVERLAY SIMULATION
            if showSimulationOverlay {
                let matchesToPlay = GameDatabase.shared.getMatches(forDate: gameState.currentDate)
                    .filter { $0.status != .played }
                
                SimulationOverlayView(
                    matchesToSimulate: matchesToPlay,
                    onComplete: {
                        withAnimation { showSimulationOverlay = false }
                        let _ = SaveManager.shared.save(gameState: gameState, slotId: gameState.saveSlotId)
                    }
                )
                .zIndex(200)
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .statusBar(hidden: true)
        #endif
        
        // 7. MODALE CALENDRIER
        #if os(iOS)
        .fullScreenCover(isPresented: $showCalendar) {
            MainGameCalendar(currentDate: gameState.currentDate)
        }
        #else
        .sheet(isPresented: $showCalendar) {
            MainGameCalendar(currentDate: gameState.currentDate)
                .frame(minWidth: 800, minHeight: 600)
        }
        #endif
        
        // 8. ALERTE DE TRANSITION DE SAISON
        .alert("Fin de Saison", isPresented: $showNewSeasonPopup) {
            Button("Commencer la nouvelle saison", role: .cancel) { }
        } message: {
            Text("La saison a été archivée avec succès.\nLes classements ont été réinitialisés et le calendrier de la saison prochaine est en cours de préparation.")
        }
        
        // ✅ 9. ÉCOUTEUR DE NAVIGATION (POUR TeamLinkView)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToClub"))) { notification in
            if let clubId = notification.userInfo?["clubId"] as? String {
                self.navigateTo(tab: .club, contextId: clubId)
            }
        }
    }
    
    // MARK: - NAVIGATION INTELLIGENTE (HISTORY)
    
    // Fonction centrale pour naviguer
    func navigateTo(tab: GameTab, contextId: String? = nil) {
        // 1. Sauvegarder l'état actuel
        let currentState = NavigationState(
            tab: currentTab,
            contextId: (currentTab == .club ? selectedClubContext : selectedCompetitionContext)
        )
        
        // Eviter doublons consécutifs
        if let last = backStack.last, last == currentState {
            // Rien
        } else {
            backStack.append(currentState)
        }
        
        // 2. Vider Forward Stack
        forwardStack.removeAll()
        
        // 3. Appliquer
        applyNavigation(tab: tab, contextId: contextId)
    }
    
    // Applique l'état sans toucher à l'historique
    private func applyNavigation(tab: GameTab, contextId: String?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentTab = tab
            if tab == .club {
                selectedClubContext = contextId
            } else if tab == .league {
                selectedCompetitionContext = contextId
            }
        }
    }
    
    func goBack() {
        guard let previousState = backStack.popLast() else { return }
        
        // Sauver dans Forward
        let currentState = NavigationState(
            tab: currentTab,
            contextId: (currentTab == .club ? selectedClubContext : selectedCompetitionContext)
        )
        forwardStack.append(currentState)
        
        // Restaurer
        applyNavigation(tab: previousState.tab, contextId: previousState.contextId)
    }
    
    // MARK: - NAVIGATION CLUB (SUIVANT / PRÉCÉDENT)
    
    func navigateClub(direction: Int) {
        guard let currentClubId = selectedClubContext,
              let currentClub = GameDatabase.shared.getClub(byId: currentClubId) else { return }
        
        let leagueId = currentClub.leagueId
        let table = GameDatabase.shared.getLeagueTable(competitionId: leagueId, seasonId: gameState.currentSeasonId)
        
        if table.isEmpty { return }
        
        guard let currentIndex = table.firstIndex(where: { $0.teamId == currentClubId }) else { return }
        
        var newIndex = currentIndex + direction
        if newIndex < 0 { newIndex = table.count - 1 }
        else if newIndex >= table.count { newIndex = 0 }
        
        let nextTeamId = table[newIndex].teamId
        
        // On change le club SANS changer d'onglet
        // On n'ajoute pas à l'historique pour éviter de spammer le bouton Back
        withAnimation(.easeInOut(duration: 0.2)) {
            self.selectedClubContext = nextTeamId
        }
    }
    
    func openPrimaryCountryMenu() {
        guard let country = gameState.selectedCountries.first else { return }
        
        self.sideMenuTitle = country.name
        self.sideMenuIcon = country.flagEmoji
        
        var items: [SideMenuItem] = []
        
        items.append(SideMenuItem(title: "National Team", icon: "tshirt.fill", color: .blue) {
            navigateTo(tab: .primaryCountry)
        })
        
        let competitions = GameDatabase.shared.getCompetitions(forCountry: country.id)
        for comp in competitions {
            items.append(SideMenuItem(title: comp.shortName, icon: "trophy.fill", color: .yellow) {
                self.navigateTo(tab: .league, contextId: comp.id)
            })
        }
        
        items.append(SideMenuItem(title: "Stadiums", icon: "sportscourt.fill", color: .green) {
            print("Navigation vers Stades")
        })
        
        items.append(SideMenuItem(title: "Jobs", icon: "briefcase.fill", color: .purple) {
            print("Navigation vers Emplois")
        })
        
        self.sideMenuItems = items
        
        withAnimation(.spring()) {
            self.showSideMenu = true
        }
    }
    
    // MARK: - AVANCEE JOUR & EVENTS
    
    func handleContinueButton() {
        if hasBlockingActions {
            withAnimation { navigateTo(tab: .inbox) }
            return
        }
        
        let todaysMatches = GameDatabase.shared.getMatches(forDate: gameState.currentDate)
        let allPlayed = todaysMatches.allSatisfy { $0.status == .played }
        
        if !todaysMatches.isEmpty && !allPlayed {
            if currentTab != .matchDay {
                withAnimation { navigateTo(tab: .matchDay) }
            } else {
                withAnimation { showSimulationOverlay = true }
            }
        } else {
            advanceDate()
            if currentTab == .matchDay {
                withAnimation { navigateTo(tab: .inbox) }
            }
        }
    }
    
    func advanceDate() {
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: gameState.currentDate) {
            withAnimation { gameState.currentDate = nextDay }
            
            // ✅ TRAITEMENT DES ÉVÉNEMENTS AUTOMATIQUES (BACKGROUND)
            processAutomaticEvents(for: nextDay)
            
            let calendar = Calendar.current
            let day = calendar.component(.day, from: nextDay)
            let month = calendar.component(.month, from: nextDay)
            
            if month == 7 && day == 9 {
                let currentYear = calendar.component(.year, from: nextDay)
                SeasonTransitionManager.shared.processSeasonTransition(currentYear: currentYear - 1)
                
                let nextSeasonId = "S_\(currentYear)_\(currentYear + 1 - 2000)"
                gameState.currentSeasonId = nextSeasonId
                showNewSeasonPopup = true
            }
            
            let _ = SaveManager.shared.save(gameState: gameState, slotId: gameState.saveSlotId)
        }
    }
    
    // ✅ GESTION DES EVENTS AUTOMATIQUES
    func processAutomaticEvents(for date: Date) {
        // On récupère les events du jour
        let dailyEvents = GameDatabase.shared.getEvents(forDate: date)
        
        for event in dailyEvents {
            // On vérifie s'il y a une action configurée en AUTOMATIC et non terminée
            if var action = event.action, action.executionMode == .automatic, !action.isCompleted {
                
                print("⚙️ Exécution automatique de l'événement : \(event.label)")
                
                // CAS 1 : TIRAGE AU SORT (DRAW)
                if event.eventType == .draw {
                                    if let competitionId = (event.refType == .competitionSeason) ? event.refId : nil {
                                        
                                        // ✅ Extraction du roundId depuis contextData (pour la Coupe)
                                        let roundId = action.contextData?["roundId"]
                                        
                                        // On lance le tirage avec le paramètre optionnel
                                        CompetitionDrawService.shared.performDrawForCurrentStage(
                                            competitionId: competitionId,
                                            seasonId: gameState.currentSeasonId,
                                            roundId: roundId // <--- C'est ici qu'on passe l'info
                                        )
                                        
                                        updateEventToReport(eventId: event.id, newLabel: "Résultats : \(event.label)")
                                    }
                }
                
                // Finalement, on marque l'action comme terminée pour ne pas bloquer le bouton "Continue"
                markActionAsCompleted(eventId: event.id)
            }
        }
    }
    
    // Helper pour changer le titre de l'event (ex: "Tirage à faire" -> "Résultats Tirage")
    func updateEventToReport(eventId: String, newLabel: String) {
        if let index = GameDatabase.shared.calendarEvents.firstIndex(where: { $0.id == eventId }) {
            let event = GameDatabase.shared.calendarEvents[index]
            
            // On recrée l'objet avec le nouveau titre et description
            let updatedEvent = SeasonCalendarEvent(
                id: event.id,
                seasonId: event.seasonId,
                calendarDayId: event.calendarDayId,
                eventType: event.eventType,
                refType: event.refType,
                refId: event.refId,
                label: newLabel, // Nouveau titre
                description: "Cet événement a été traité automatiquement par la fédération. Les résultats sont disponibles.",
                date: event.date,
                colorHex: event.colorHex,
                action: event.action
            )
            
            GameDatabase.shared.calendarEvents[index] = updatedEvent
        }
    }
    
    // MARK: - VUE INBOX & ACTIONS
    
    var inboxView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("INBOX").font(.caption).fontWeight(.bold).foregroundColor(.gray).padding()
                if inboxMessages.isEmpty {
                    Spacer(); Text("No messages").font(.caption).foregroundColor(.gray).frame(maxWidth: .infinity); Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(inboxMessages) { message in inboxRow(for: message) }
                        }
                    }
                }
            }
            .frame(width: 280)
            .background(Color.white.opacity(0.05))
            .overlay(Rectangle().frame(width: 1).foregroundColor(.white.opacity(0.1)), alignment: .trailing)
            
            ZStack {
                if let selectedId = selectedMessageId, let message = inboxMessages.first(where: { $0.id == selectedId }) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text(message.eventType.rawValue.uppercased()).font(.caption).fontWeight(.bold).padding(6)
                                    .background(Color(hex: message.colorHex ?? "#888888").opacity(0.2))
                                    .foregroundColor(Color(hex: message.colorHex ?? "#FFFFFF")).cornerRadius(4)
                                Spacer()
                                Text(message.date?.formatted(date: .abbreviated, time: .shortened) ?? "").font(.caption).foregroundColor(.gray)
                            }
                            Divider().background(Color.white.opacity(0.1))
                            Text(message.label).font(.title3).fontWeight(.bold).foregroundColor(.white)
                            Text(message.description ?? "No details.").foregroundColor(.white.opacity(0.8)).font(.body).lineSpacing(4).padding(.top, 10)
                            Spacer(minLength: 40)
                            
                            if let action = message.action {
                                HStack {
                                    Spacer()
                                    if action.isCompleted {
                                        HStack { Image(systemName: "checkmark.circle.fill"); Text("Action Completed") }
                                            .font(.subheadline).bold().foregroundColor(.green).padding().background(Color.green.opacity(0.1)).cornerRadius(12)
                                    } else {
                                        Button(action: { handleEventAction(event: message, action: action) }) {
                                            HStack {
                                                Image(systemName: "exclamationmark.circle.fill").font(.title3).foregroundColor(.white)
                                                Text(action.label.uppercased()).fontWeight(.bold).font(.caption)
                                                Image(systemName: "arrow.right.circle.fill")
                                            }
                                            .padding().frame(minWidth: 200)
                                            .background(Color(hex: message.colorHex ?? "#FFD700")).foregroundColor(.black).cornerRadius(12)
                                            .shadow(color: Color(hex: message.colorHex ?? "#FFD700").opacity(0.5), radius: 10, x: 0, y: 5)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    Spacer()
                                }
                                .padding(.bottom, 50)
                            }
                        }
                        .padding(20)
                    }
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "envelope.open").font(.system(size: 60)).foregroundColor(.white.opacity(0.05))
                        Text("Select a message").font(.headline).foregroundColor(.white.opacity(0.2))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func inboxRow(for message: SeasonCalendarEvent) -> some View {
        let isRead = gameState.readEventIds.contains(message.id)
        let isSelected = selectedMessageId == message.id
        let isBlocking = (message.action != nil && message.action?.isCompleted == false)
        
        return Button(action: {
            selectedMessageId = message.id
            markAsRead(message.id)
        }) {
            HStack(alignment: .top, spacing: 10) {
                if isBlocking {
                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red).frame(width: 12, height: 12).padding(.top, 4)
                } else {
                    Circle().fill(isRead ? Color.clear : Color.green).frame(width: 8, height: 8).padding(.top, 6)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(message.eventType.rawValue).font(.caption2).fontWeight(.bold).foregroundColor(isRead ? .gray : .green)
                        Spacer()
                        if isSelected { Image(systemName: "chevron.right").font(.caption2).foregroundColor(.gray) }
                    }
                    Text(message.label).font(.system(size: 12, weight: isRead ? .regular : .bold))
                        .foregroundColor(isRead ? .white.opacity(0.7) : .white).lineLimit(2).multilineTextAlignment(.leading)
                    Text(message.date?.formatted(date: .numeric, time: .omitted) ?? "").font(.caption2).foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(10)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .overlay(Rectangle().frame(width: 4).foregroundColor(isBlocking ? .red : .clear), alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func markAsRead(_ id: String) {
        if !gameState.readEventIds.contains(id) {
            var newSet = gameState.readEventIds
            newSet.insert(id)
            gameState.readEventIds = newSet
            let _ = SaveManager.shared.save(gameState: gameState, slotId: gameState.saveSlotId)
        }
    }
    
    func handleEventAction(event: SeasonCalendarEvent, action: EventAction) {
        if action.type == .navigation, action.targetScreen == "CompetitionDraw" {
            self.currentEventActionContext = event.refId
            withAnimation { self.showDrawPopup = true }
        } else {
            markActionAsCompleted(eventId: event.id)
        }
    }
    
    func markActionAsCompleted(eventId: String) {
        if let index = GameDatabase.shared.calendarEvents.firstIndex(where: { $0.id == eventId }) {
            GameDatabase.shared.calendarEvents[index].action?.isCompleted = true
            syncGameState()
            let _ = SaveManager.shared.save(gameState: gameState, slotId: gameState.saveSlotId)
            selectedMessageId = nil
            selectedMessageId = eventId
        }
    }
    
    func syncGameState() {
        gameState.savedCompetitionSeasons = GameDatabase.shared.competitionSeasons
        gameState.savedMatches = GameDatabase.shared.matches
        gameState.savedMatchDays = GameDatabase.shared.matchDays
        gameState.savedLeagueTables = GameDatabase.shared.leagueTables
        gameState.savedCalendarEvents = GameDatabase.shared.calendarEvents
    }
    
    var currentRoundId: String {
        if let msgId = selectedMessageId,
           let event = GameDatabase.shared.calendarEvents.first(where: { $0.id == msgId }),
           let contextData = event.action?.contextData,
           let round = contextData["roundId"] {
            return round
        }
        return "R32"
    }
}
