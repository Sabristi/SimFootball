//
//  MainGameCalendar.swift
//  SimFootball
//
//  Created by Sabri Benhadda.
//

import SwiftUI

struct MainGameCalendar: View {
    @Environment(\.dismiss) var dismiss
    
    let gameDate: Date
    
    @State private var displayDate: Date
    @State private var selectedDate: Date
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    init(currentDate: Date) {
        self.gameDate = currentDate
        let startOfDay = Calendar.current.startOfDay(for: currentDate)
        _displayDate = State(initialValue: startOfDay)
        _selectedDate = State(initialValue: startOfDay)
    }
    
    // MARK: - BODY PRINCIPAL
    var body: some View {
        GeometryReader { _ in
            ZStack {
                backgroundDecor
                
                VStack(spacing: 0) {
                    headerView          // 1. En-tête
                    calendarGridView    // 2. Grille Calendrier
                    detailsFooterView   // 3. Détails en bas
                }
            }
        }
    }
    
    // MARK: - 1. HEADER VIEW
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .padding(10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .foregroundColor(.white)
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            Text("CALENDAR").font(.headline).tracking(4).foregroundColor(.white.opacity(0.5))
            Spacer()
            
            if !calendar.isDate(displayDate, equalTo: gameDate, toGranularity: .month) {
                Button("Today") {
                    let today = calendar.startOfDay(for: gameDate)
                    displayDate = today
                    selectedDate = today
                }
                .font(.caption).bold()
                .padding(8)
                .background(Color.green).foregroundColor(.black).cornerRadius(20)
                .buttonStyle(PlainButtonStyle())
            } else {
                Color.clear.frame(width: 60, height: 30)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3).ignoresSafeArea(edges: .top))
    }
    
    // MARK: - 2. CALENDAR GRID VIEW
    private var calendarGridView: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // Navigation Mois
                HStack(spacing: 40) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left.circle.fill").font(.largeTitle).foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack {
                        Text(displayDate.formatted(.dateTime.month(.wide).year()))
                            .font(.title).fontWeight(.black).foregroundColor(.white)
                        Text("Current Date: \(gameDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundColor(.green)
                    }
                    .frame(width: 250)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right.circle.fill").font(.largeTitle).foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 20)
                
                // Semaine
                HStack(spacing: 0) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day).font(.caption).fontWeight(.bold).foregroundColor(.gray).frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 10)
                .padding(.horizontal)
                
                // Grille des Jours
                                let days = generateDaysInMonth(for: displayDate)
                                LazyVGrid(columns: columns, spacing: 4) {
                                    ForEach(days) { dayValue in
                                        
                                        // Calculs distincts (Rapides grâce à la DB locale)
                                        let matchCount = GameDatabase.shared.getMatchDays(forDate: dayValue.date).count
                                        let eventCount = GameDatabase.shared.getEvents(forDate: dayValue.date).count
                                        
                                        DayCell(
                                            date: dayValue.date,
                                            isCurrentMonth: dayValue.isCurrentMonth,
                                            isToday: calendar.isDate(dayValue.date, inSameDayAs: gameDate),
                                            isSelected: calendar.isDate(dayValue.date, inSameDayAs: selectedDate),
                                            hasMatch: matchCount > 0, // ✅ On passe l'info Match
                                            hasEvent: eventCount > 0  // ✅ On passe l'info Event
                                        )
                                        .onTapGesture {
                                            selectedDate = dayValue.date
                                            if !dayValue.isCurrentMonth { displayDate = dayValue.date }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                
                Color.clear.frame(height: 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 3. DETAILS FOOTER VIEW
    private var detailsFooterView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.headline).foregroundColor(.green)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 15)
            
            // Récupération des données
            let matches = GameDatabase.shared.getMatchDays(forDate: selectedDate)
            let events = GameDatabase.shared.getEvents(forDate: selectedDate)
            
            if matches.isEmpty && events.isEmpty {
                HStack {
                    Spacer()
                    Text("No events scheduled.").font(.caption).italic().foregroundColor(.gray)
                    Spacer()
                }
                .padding(.bottom, 30)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        
                        // A. Affichage des MatchDays (Matchs de compétition)
                        ForEach(matches) { matchDay in
                            HStack {
                                Rectangle().fill(Color.green).frame(width: 4)
                                VStack(alignment: .leading) {
                                    Text(matchDay.label).fontWeight(.bold).foregroundColor(.white)
                                    Text(matchDay.stageId).font(.caption2).foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // B. Affichage des Events (Tirages, etc.)
                        ForEach(events) { event in
                            HStack {
                                // Couleur personnalisée de l'event (ou Jaune par défaut)
                                Rectangle()
                                    .fill(Color(hex: event.colorHex ?? "#FFD700"))
                                    .frame(width: 4)
                                
                                VStack(alignment: .leading) {
                                    Text(event.label)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text(event.eventType.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                                
                                // Heure de l'event
                                if let eventDate = event.date {
                                    Text(eventDate.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .padding(4)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(4)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(height: 130)
        .background(Color.black.opacity(0.8).ignoresSafeArea(edges: .bottom))
        .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.1)), alignment: .top)
    }
    
    // MARK: - BACKGROUND & HELPERS
    
    var backgroundDecor: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ZStack {
                Circle().fill(Color.blue.opacity(0.1)).frame(width: 800).blur(radius: 150).offset(x: 200, y: -200)
                Circle().fill(Color.green.opacity(0.05)).frame(width: 600).blur(radius: 120).offset(x: -200, y: 300)
            }
            .ignoresSafeArea()
        }
    }
    
    func checkActivity(for date: Date) -> Bool {
        return !GameDatabase.shared.getMatchDays(forDate: date).isEmpty ||
               !GameDatabase.shared.getEvents(forDate: date).isEmpty
    }
    
    func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayDate) {
            displayDate = newDate
        }
    }
    
    func generateDaysInMonth(for date: Date) -> [CalendarDayValue] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offset = (firstWeekday + 5) % 7 // Lundi=0 (pour le calendrier Grégorien standard, sinon ajuster)
        
        var days: [CalendarDayValue] = []
        
        // Jours du mois précédent
        if offset > 0, let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstDay) {
            let rangePrev = calendar.range(of: .day, in: .month, for: prevMonth)!
            let start = rangePrev.count - offset + 1
            if start <= rangePrev.count {
                for i in start...rangePrev.count {
                    if let d = calendar.date(from: DateComponents(year: calendar.component(.year, from: prevMonth), month: calendar.component(.month, from: prevMonth), day: i)) {
                        days.append(CalendarDayValue(date: d, isCurrentMonth: false))
                    }
                }
            }
        }
        
        // Jours du mois en cours
        for i in 1...range.count {
            if let d = calendar.date(byAdding: .day, value: i - 1, to: firstDay) {
                days.append(CalendarDayValue(date: d, isCurrentMonth: true))
            }
        }
        
        // Jours du mois suivant
        let remaining = 42 - days.count
        if remaining > 0, let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstDay) {
            for i in 1...remaining {
                if let d = calendar.date(byAdding: .day, value: i - 1, to: nextMonth) {
                    days.append(CalendarDayValue(date: d, isCurrentMonth: false))
                }
            }
        }
        return days
    }
}

// MARK: - SUB-STRUCTS

struct CalendarDayValue: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
}

struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    
    // Nouveaux paramètres distincts
    let hasMatch: Bool
    let hasEvent: Bool
    
    var body: some View {
        ZStack {
            // Fond sélection
            if isSelected {
                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.15))
            }
            // Cercle "Aujourd'hui"
            if isToday {
                Circle().stroke(Color.green, lineWidth: 2).frame(width: 34, height: 34)
            }
            
            VStack(spacing: 4) { // Espacement légèrement augmenté
                
                // Numéro du jour
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .heavy : .medium))
                    .foregroundColor(isCurrentMonth ? .white : .gray.opacity(0.3))
                
                // --- LES PASTILLES ---
                HStack(spacing: 3) {
                    // 1. Pastille MATCH (Orange)
                    if hasMatch {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 5, height: 5)
                    }
                    
                    // 2. Pastille EVENT (Jaune)
                    if hasEvent {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 5, height: 5)
                    }
                    
                    // Placeholder invisible pour garder la hauteur si rien
                    if !hasMatch && !hasEvent {
                        Color.clear.frame(width: 5, height: 5)
                    }
                }
            }
        }
        .frame(height: 50).frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
