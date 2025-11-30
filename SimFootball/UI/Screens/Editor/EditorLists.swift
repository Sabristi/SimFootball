import SwiftUI

// MARK: - 1. MOTEUR DE TABLEAU GÉNÉRIQUE (REUSABLE)

struct DataColumn<T> {
    let title: String
    let width: CGFloat
    let alignment: Alignment
    let sortComparator: ((T, T) -> Bool)?
    let cellContent: (T) -> AnyView
    
    init(
        title: String,
        width: CGFloat = 100,
        alignment: Alignment = .leading,
        sort: ((T, T) -> Bool)? = nil,
        @ViewBuilder content: @escaping (T) -> some View
    ) {
        self.title = title
        self.width = width
        self.alignment = alignment
        self.sortComparator = sort
        self.cellContent = { AnyView(content($0)) }
    }
}

struct DataTable<T: Identifiable>: View {
    // DONNÉES
    let data: [T]
    let columns: [DataColumn<T>]
    
    // ACTIONS
    let onEdit: (T) -> Void // Closure appelée quand on clique sur le stylet
    
    // CONFIGURATION
    let itemsPerPage: Int = 12
    
    // ÉTATS LOCAUX
    @State private var currentPage: Int = 0
    @State private var sortColumnIndex: Int? = 0
    @State private var isAscending: Bool = true
    
    // LOGIQUE DE TRI
    var sortedData: [T] {
        guard let index = sortColumnIndex, let comparator = columns[index].sortComparator else {
            return data
        }
        return data.sorted { (a, b) -> Bool in
            isAscending ? comparator(a, b) : !comparator(a, b)
        }
    }
    
    // LOGIQUE DE PAGINATION
    var paginatedData: [T] {
        let start = currentPage * itemsPerPage
        let end = min(start + itemsPerPage, sortedData.count)
        guard start < end else { return [] }
        return Array(sortedData[start..<end])
    }
    
    var totalPages: Int {
        return Int(ceil(Double(data.count) / Double(itemsPerPage)))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- A. HEADER (En-têtes) ---
            HStack(spacing: 0) {
                ForEach(0..<columns.count, id: \.self) { index in
                    let col = columns[index]
                    
                    Button(action: {
                        if sortColumnIndex == index {
                            isAscending.toggle()
                        } else {
                            sortColumnIndex = index
                            isAscending = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(col.title.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1) // Empêche le texte de casser l'alignement
                            
                            if sortColumnIndex == index {
                                Image(systemName: isAscending ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 8))
                                    .foregroundColor(.purple)
                            }
                        }
                        // CORRECTION CRITIQUE D'ALIGNEMENT :
                        // 1. D'abord le padding interne
                        .padding(.horizontal, 4)
                        .padding(.vertical, 12)
                        // 2. ENSUITE le frame qui fixe la largeur totale
                        .frame(width: col.width, alignment: col.alignment)
                        // 3. Enfin le background
                        .background(Color.white.opacity(0.05))
                    }
                    .disabled(col.sortComparator == nil)
                    .buttonStyle(PlainButtonStyle()) // Évite les effets de clics parasites
                    
                    // Séparateur visuel
                    if index < columns.count - 1 {
                        Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 20)
                    }
                }
                
                // Espace réservé pour la colonne "Actions"
                Spacer()
                Text("EDIT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 40)
                    .padding(.trailing, 10) // Alignement avec la ligne de donnée
            }
            .background(Color.black.opacity(0.8))
            
            // --- B. LISTE DES DONNÉES ---
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(paginatedData) { item in
                        HStack(spacing: 0) {
                            // COLONNES DE DONNÉES
                            ForEach(0..<columns.count, id: \.self) { index in
                                let col = columns[index]
                                
                                col.cellContent(item)
                                    // CORRECTION CRITIQUE D'ALIGNEMENT :
                                    // Même logique que le Header : Padding d'abord, Frame ensuite.
                                    .padding(.horizontal, 4)
                                    .frame(width: col.width, alignment: col.alignment)
                                    .padding(.vertical, 10)
                            }
                            
                            Spacer()
                            
                            // COLONNE ACTION (Stylet Cliquable)
                            Button(action: { onEdit(item) }) {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(width: 40)
                            .padding(.trailing, 10) // Même padding que le header
                        }
                        .background(Color.white.opacity(0.02))
                        .overlay(
                            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.05)),
                            alignment: .bottom
                        )
                    }
                }
            }
            
            // --- C. FOOTER (Pagination) ---
            HStack {
                Text("\(data.count) Records")
                    .font(.caption).foregroundColor(.gray)
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { if currentPage > 0 { currentPage -= 1 } }) {
                        Image(systemName: "chevron.left").font(.headline)
                            .foregroundColor(currentPage > 0 ? .white : .gray.opacity(0.3))
                    }
                    .disabled(currentPage == 0)
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Page \(currentPage + 1) / \(max(1, totalPages))")
                        .font(.caption).monospacedDigit().foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.white.opacity(0.1)).cornerRadius(4)
                    
                    Button(action: { if currentPage < totalPages - 1 { currentPage += 1 } }) {
                        Image(systemName: "chevron.right").font(.headline)
                            .foregroundColor(currentPage < totalPages - 1 ? .white : .gray.opacity(0.3))
                    }
                    .disabled(currentPage >= totalPages - 1)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.6))
            .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.1)), alignment: .top)
        }
    }
}

// MARK: - 2. IMPLEMENTATION PAYS

struct CountryEditorList: View {
    let countries = GameDatabase.shared.countries
    
    var body: some View {
        DataTable(
            data: countries,
            columns: [
                DataColumn(title: "Flag", width: 50, alignment: .center) { country in
                    Text(country.flagEmoji).font(.title2)
                },
                
                DataColumn(title: "ID", width: 60, sort: { $0.id < $1.id }) { country in
                    Text(country.id)
                        .font(.caption).fontWeight(.bold)
                        .padding(4).background(Color.blue.opacity(0.3)).cornerRadius(4)
                },
                
                DataColumn(title: "Name", width: 180, sort: { $0.name < $1.name }) { country in
                    Text(country.name).fontWeight(.semibold).foregroundColor(.white).lineLimit(1)
                },
                
                DataColumn(title: "Continent", width: 110, sort: { $0.continent.rawValue < $1.continent.rawValue }) { country in
                    Text(country.continent.rawValue).font(.caption).foregroundColor(.gray)
                },
                
                DataColumn(title: "Confed", width: 70, sort: { ($0.confederationId ?? "") < ($1.confederationId ?? "") }) { country in
                    Text(country.confederationId ?? "-").font(.caption).foregroundColor(.purple)
                },
                
                DataColumn(title: "Playable", width: 70, alignment: .center, sort: { $0.isPlayable && !$1.isPlayable }) { country in
                    if country.isPlayable {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red.opacity(0.5))
                    }
                }
            ],
            onEdit: { country in
                print("✏️ Éditer pays : \(country.name)")
            }
        )
    }
}

// MARK: - 3. IMPLEMENTATION CONFÉDÉRATIONS

struct ConfederationEditorList: View {
    let confeds = GameDatabase.shared.confederations
    
    var body: some View {
        DataTable(
            data: confeds,
            columns: [
                DataColumn(title: "Code", width: 80, sort: { $0.shortName < $1.shortName }) { conf in
                    Text(conf.shortName).font(.headline).fontWeight(.black).foregroundColor(.purple)
                },
                
                DataColumn(title: "Name", width: 280, sort: { $0.name < $1.name }) { conf in
                    Text(conf.name).foregroundColor(.white).lineLimit(1)
                },
                
                DataColumn(title: "Scope", width: 100, sort: { $0.scope.rawValue < $1.scope.rawValue }) { conf in
                    Text(conf.scope.rawValue).font(.caption)
                        .padding(4).background(Color.white.opacity(0.1)).cornerRadius(4)
                },
                
                DataColumn(title: "Region", width: 100) { conf in
                    Text(conf.continent?.rawValue ?? "Global").font(.caption).foregroundColor(.gray)
                }
            ],
            onEdit: { conf in
                print("✏️ Éditer confédération : \(conf.name)")
            }
        )
    }
}

// MARK: - 4. IMPLEMENTATION STADES

struct StadiumEditorList: View {
    let stadiums = GameDatabase.shared.stadiums
    
    var body: some View {
        DataTable(
            data: stadiums,
            columns: [
                // Col 1 : Nom du Stade
                DataColumn(title: "Name", width: 200, sort: { $0.name < $1.name }) { stadium in
                    Text(stadium.name).fontWeight(.bold).foregroundColor(.white).lineLimit(1)
                },
                
                // Col 2 : Ville (Lookup via GameDatabase)
                DataColumn(title: "City", width: 120, sort: {
                    let cityA = GameDatabase.shared.getCity(byId: $0.cityId)?.name ?? ""
                    let cityB = GameDatabase.shared.getCity(byId: $1.cityId)?.name ?? ""
                    return cityA < cityB
                }) { stadium in
                    let cityName = GameDatabase.shared.getCity(byId: stadium.cityId)?.name ?? stadium.cityId
                    Text(cityName).foregroundColor(.gray)
                },
                
                // Col 3 : Capacité (Format nombre)
                DataColumn(title: "Capacity", width: 80, sort: { $0.capacity > $1.capacity }) { stadium in
                    Text("\(stadium.capacity)")
                        .font(.system(.caption, design: .monospaced))
                        .padding(4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(4)
                },
                
                // Col 4 : Surface
                DataColumn(title: "Surface", width: 90, sort: { $0.surface.rawValue < $1.surface.rawValue }) { stadium in
                    Text(stadium.surface.rawValue).font(.caption).foregroundColor(.purple)
                },
                
                // Col 5 : Toit ?
                DataColumn(title: "Roof", width: 50, alignment: .center, sort: { $0.hasRoof && !$1.hasRoof }) { stadium in
                    if stadium.hasRoof {
                        Image(systemName: "roof.box.fill").foregroundColor(.white)
                    } else {
                        Text("-").foregroundColor(.gray.opacity(0.3))
                    }
                },
                
                // Col 6 : Année
                DataColumn(title: "Built", width: 60, sort: { $0.yearBuilt < $1.yearBuilt }) { stadium in
                    Text(String(stadium.yearBuilt)).font(.caption).foregroundColor(.gray)
                }
            ],
            onEdit: { stadium in
                print("✏️ Éditer stade : \(stadium.name)")
            }
        )
    }
}

// MARK: - 5. IMPLEMENTATION CLUBS

struct ClubEditorList: View {
    let clubs = GameDatabase.shared.clubs
    
    var body: some View {
        DataTable(
            data: clubs,
            columns: [
                // Col 1 : Pays (Drapeau)
                DataColumn(title: "Nat", width: 50, alignment: .center, sort: {
                    let cA = GameDatabase.shared.getCountry(byId: $0.countryId)?.name ?? ""
                    let cB = GameDatabase.shared.getCountry(byId: $1.countryId)?.name ?? ""
                    return cA < cB
                }) { club in
                    if let country = GameDatabase.shared.getCountry(byId: club.countryId) {
                        Text(country.flagEmoji).font(.title2)
                    } else {
                        Text("-")
                    }
                },
                
                // Col 2 : Nom Complet
                DataColumn(title: "Name", width: 220, sort: { $0.name < $1.name }) { club in
                    HStack {
                        // Carré de couleur du club
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: club.identity.primaryColor))
                            .frame(width: 12, height: 12)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 1))
                        
                        Text(club.name).fontWeight(.bold).foregroundColor(.white)
                    }
                },
                
                // Col 3 : Nom Court
                DataColumn(title: "Short", width: 100, sort: { $0.shortName < $1.shortName }) { club in
                    Text(club.shortName).font(.caption).foregroundColor(.gray)
                },
                
                // Col 4 : Réputation
                DataColumn(title: "Rep", width: 80, sort: { $0.reputation > $1.reputation }) { club in
                    // Affichage étoiles (calcul simple)
                    let stars = min(5, max(1, club.reputation / 2000))
                    HStack(spacing: 1) {
                        ForEach(0..<stars, id: \.self) { _ in
                            Image(systemName: "star.fill").font(.system(size: 8)).foregroundColor(.yellow)
                        }
                    }
                },
                
                // Col 5 : Ville
                DataColumn(title: "City", width: 120) { club in
                    if let cityId = club.cityId, let city = GameDatabase.shared.getCity(byId: cityId) {
                        Text(city.name).foregroundColor(.gray)
                    } else {
                        Text("-").foregroundColor(.gray.opacity(0.3))
                    }
                },
                
                // Col 6 : Stade
                DataColumn(title: "Stadium", width: 150) { club in
                    if let stadId = club.stadiumId, let stad = GameDatabase.shared.getStadium(byId: stadId) {
                        Text(stad.name).font(.caption).foregroundColor(.gray)
                    } else {
                        Text("No Stadium").font(.caption).italic().foregroundColor(.red.opacity(0.5))
                    }
                },
                
                // Col 7 : Fondation
                DataColumn(title: "Est.", width: 60, sort: { $0.foundedYear < $1.foundedYear }) { club in
                    Text(String(club.foundedYear)).font(.caption).foregroundColor(.gray)
                }
            ],
            onEdit: { club in
                print("✏️ Éditer Club : \(club.name)")
            }
        )
    }
}

// L'extension Color a été déplacée dans Shared/ColorExtensions.swift
