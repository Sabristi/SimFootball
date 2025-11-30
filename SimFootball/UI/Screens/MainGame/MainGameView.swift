import SwiftUI

struct MainGameView: View {
    @Environment(\.dismiss) var dismiss
    
    // --- ÉTATS DU JEU ---
    @State var gameState: GameState
    
    // --- NAVIGATION PRINCIPALE ---
    @State private var currentTab: GameTab = .inbox
    @State private var showCalendar: Bool = false
    
    // --- ÉTATS MENU LATÉRAL (FLYOUT) ---
    @State private var showSideMenu: Bool = false
    @State private var sideMenuTitle: String = ""
    @State private var sideMenuIcon: String = ""
    @State private var sideMenuItems: [SideMenuItem] = []
    
    // --- NAVIGATION LEAGUE (Nouveau) ---
    @State private var selectedCompetitionContext: String? // ID de la compétition sélectionnée
    
    // --- ÉTATS INBOX ---
    @State private var selectedMessageId: String?
    
    // --- ÉTATS ÉVÉNEMENTS SPÉCIAUX ---
    @State private var showDrawPopup: Bool = false
    @State private var currentEventActionContext: String?
    
    // MARK: - LOGIQUE MÉTIER INBOX
    
    var inboxMessages: [SeasonCalendarEvent] {
        GameDatabase.shared.calendarEvents
            .filter { event in
                guard let eventDate = event.time else { return false }
                let comparison = Calendar.current.compare(eventDate, to: gameState.currentDate, toGranularity: .day)
                return comparison != .orderedDescending
            }
            .sorted { ($0.time ?? Date()) > ($1.time ?? Date()) }
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
                    icon: currentTab.icon,
                    currentDate: gameState.currentDate,
                    onBack: { dismiss() },
                    onContinue: {
                        if hasBlockingActions {
                            withAnimation { currentTab = .inbox }
                        } else {
                            advanceDate()
                        }
                    },
                    onCalendarClick: { showCalendar = true }
                )
                .zIndex(20)
                
                // 3. STRUCTURE PRINCIPALE (Sidebar + Contenu)
                HStack(spacing: 0) {
                    
                    // A. SIDEBAR PRINCIPALE (Fixe)
                    MainGameSidebar(
                        selectedTab: $currentTab,
                        unreadCount: unreadCount,
                        primaryCountry: gameState.selectedCountries.first,
                        onPrimaryCountryClick: {
                            // CLIC SUR LE DRAPEAU -> OUVRE LA POPUP LATÉRALE
                            openPrimaryCountryMenu()
                        }
                    )
                    .zIndex(15)
                    
                    // B. ZONE DE CONTENU
                    ZStack {
                        Color.clear
                        
                        // --- CONTENU VARIABLE ---
                        switch currentTab {
                        case .inbox:
                            inboxView
                            
                        case .primaryCountry:
                            // Dashboard pays (Peut aussi être atteint via le menu latéral)
                            if let country = gameState.selectedCountries.first {
                                // Placeholder pour le dashboard pays par défaut
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
                            // Affiche les détails de la ligue sélectionnée
                            if let compId = selectedCompetitionContext {
                                LeagueDetailsView(
                                    competitionId: compId,
                                    seasonId: gameState.currentSeasonId
                                )
                            } else {
                                Text("No Competition Selected").foregroundColor(.gray)
                            }
                            
                        default:
                            Text("Module: \(currentTab.title)").foregroundColor(.gray)
                        }
                        
                        // 4. MENU LATÉRAL (FLYOUT GÉNÉRIQUE)
                        // S'affiche par dessus le contenu, à côté de la sidebar
                        if showSideMenu {
                            HStack(spacing: 0) {
                                SideMenuPanel(
                                    title: sideMenuTitle,
                                    headerIcon: sideMenuIcon,
                                    items: sideMenuItems,
                                    isPresented: $showSideMenu
                                )
                                
                                Spacer() // Pousse le menu à gauche
                            }
                            .zIndex(30) // Au-dessus du contenu
                            .transition(.move(edge: .leading))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped() // Important pour ne pas déborder sur le header
                }
            }
            
            // 5. POPUP TIRAGE
            if showDrawPopup {
                CompetitionDrawView(
                    competitionId: currentEventActionContext ?? "",
                    seasonId: gameState.currentSeasonId,
                    onClose: { showDrawPopup = false },
                    onComplete: {
                        if let msgId = selectedMessageId { markActionAsCompleted(eventId: msgId) }
                        showDrawPopup = false
                    }
                )
                .zIndex(100)
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .statusBar(hidden: true)
        #endif
        
        // 6. MODALE CALENDRIER
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
    }
    
    // MARK: - LOGIQUE MENU LATÉRAL (PAYS)
    
    func openPrimaryCountryMenu() {
        guard let country = gameState.selectedCountries.first else { return }
        
        self.sideMenuTitle = country.name
        self.sideMenuIcon = country.flagEmoji
        
        // Construction dynamique des boutons
        var items: [SideMenuItem] = []
        
        // 1. Federation / National Team
        items.append(SideMenuItem(title: "National Team", icon: "tshirt.fill", color: .blue) {
            print("Navigation vers Equipe Nationale")
            currentTab = .primaryCountry
            // TODO: Naviguer vers écran équipe nationale
        })
        
        // 2. Compétitions (Dynamique)
        let competitions = GameDatabase.shared.getCompetitions(forCountry: country.id)
        for comp in competitions {
            items.append(SideMenuItem(title: comp.shortName, icon: "trophy.fill", color: .yellow) {
                print("Navigation vers Compétition: \(comp.name)")
                
                // ACTION DE NAVIGATION VERS LA LIGUE
                self.selectedCompetitionContext = comp.id
                self.currentTab = .league // Bascule sur la vue LeagueDetails
            })
        }
        
        // 3. Infrastructures & Jobs
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
    
    // MARK: - HELPERS UI
    
    var headerTitle: String {
        if currentTab == .league {
            // Trouve le nom de la ligue actuelle
            if let id = selectedCompetitionContext,
               let comp = GameDatabase.shared.competitions.first(where: { $0.id == id }) {
                return comp.shortName
            }
            return "Competition"
        }
        if currentTab == .primaryCountry {
            return gameState.selectedCountries.first?.name ?? "Country"
        }
        return currentTab.title
    }
    
    // MARK: - VUE INBOX
    
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
                                Text(message.time?.formatted(date: .abbreviated, time: .shortened) ?? "").font(.caption).foregroundColor(.gray)
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
                    Text(message.time?.formatted(date: .numeric, time: .omitted) ?? "").font(.caption2).foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(10)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .overlay(Rectangle().frame(width: 4).foregroundColor(isBlocking ? .red : .clear), alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - ACTIONS
    
    func advanceDate() {
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: gameState.currentDate) {
            withAnimation { gameState.currentDate = nextDay }
            let _ = SaveManager.shared.save(gameState: gameState, slotId: gameState.saveSlotId)
        }
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
            selectedMessageId = nil
            selectedMessageId = eventId
        }
    }
}

#Preview(traits: .landscapeLeft) {
    let mockState = GameState.createNew(
        slotId: 1,
        mode: .manager,
        countries: [
            Country(id: "FRA", name: "France", flagEmoji: "🇫🇷", continent: .europe, confederationId: "UEFA")
        ]
    )
    MainGameView(gameState: mockState)
}
