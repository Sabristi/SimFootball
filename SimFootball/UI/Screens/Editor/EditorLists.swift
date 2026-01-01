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
    let onEdit: (T) -> Void
    
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
    
    // MARK: - BODY PRINCIPAL
    // ✅ Correction : Découpage du body pour soulager le compilateur
    var body: some View {
        VStack(spacing: 0) {
            headerView
            rowsScrollView
            footerView
        }
    }
    
    // MARK: - SOUS-VUES (Pour aider le compilateur)
    
    // 1. L'En-tête (Header)
    private var headerView: some View {
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
                            .lineLimit(1)
                        
                        if sortColumnIndex == index {
                            Image(systemName: isAscending ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 12)
                    .frame(width: col.width, alignment: col.alignment)
                    .background(Color.white.opacity(0.05))
                }
                .disabled(col.sortComparator == nil)
                .buttonStyle(PlainButtonStyle())
                
                if index < columns.count - 1 {
                    Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 20)
                }
            }
            
            Spacer()
            Text("EDIT")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.gray)
                .frame(width: 40)
                .padding(.trailing, 10)
        }
        .background(Color.black.opacity(0.8))
    }
    
    // 2. La Liste des données (Rows)
    private var rowsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(paginatedData) { item in
                    rowView(for: item)
                }
            }
        }
    }
    
    // 3. Une ligne individuelle (Row)
    private func rowView(for item: T) -> some View {
        HStack(spacing: 0) {
            // COLONNES DE DONNÉES
            ForEach(0..<columns.count, id: \.self) { index in
                let col = columns[index]
                
                col.cellContent(item)
                    .padding(.horizontal, 4)
                    .frame(width: col.width, alignment: col.alignment)
                    .padding(.vertical, 10)
            }
            
            Spacer()
            
            // COLONNE ACTION
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
            .padding(.trailing, 10)
        }
        .background(Color.white.opacity(0.02))
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.05)),
            alignment: .bottom
        )
    }
    
    // 4. Le Pied de page (Pagination)
    private var footerView: some View {
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
                
                DataColumn(title: "Continent", width: 110, sort: { $0.continent < $1.continent }) { country in
                    Text(country.continent).font(.caption).foregroundColor(.gray)
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
                DataColumn(title: "Name", width: 200, sort: { $0.name < $1.name }) { stadium in
                    Text(stadium.name).fontWeight(.bold).foregroundColor(.white).lineLimit(1)
                },
                
                DataColumn(title: "City", width: 120, sort: {
                    let cityA = GameDatabase.shared.getCity(byId: $0.cityId)?.name ?? ""
                    let cityB = GameDatabase.shared.getCity(byId: $1.cityId)?.name ?? ""
                    return cityA < cityB
                }) { stadium in
                    let cityName = GameDatabase.shared.getCity(byId: stadium.cityId)?.name ?? stadium.cityId
                    Text(cityName).foregroundColor(.gray)
                },
                
                DataColumn(title: "Capacity", width: 80, sort: { $0.capacity > $1.capacity }) { stadium in
                    Text("\(stadium.capacity)")
                        .font(.system(.caption, design: .monospaced))
                        .padding(4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(4)
                },
                
                DataColumn(title: "Surface", width: 90, sort: { $0.surface.rawValue < $1.surface.rawValue }) { stadium in
                    Text(stadium.surface.rawValue).font(.caption).foregroundColor(.purple)
                },
                
                DataColumn(title: "Roof", width: 50, alignment: .center, sort: { $0.hasRoof && !$1.hasRoof }) { stadium in
                    if stadium.hasRoof {
                        Image(systemName: "roof.box.fill").foregroundColor(.white)
                    } else {
                        Text("-").foregroundColor(.gray.opacity(0.3))
                    }
                },
                
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

// MARK: - 5. IMPLEMENTATION CLUBS (RETRAVAILLÉE)

struct ClubIDWrapper: Identifiable {
    let id: String
}

struct ClubEditorList: View {
    @ObservedObject var database = GameDatabase.shared
    @State private var selectedClubWrapper: ClubIDWrapper?
    
    var body: some View {
        Table(database.clubs) {
            
            // Colonne 1 : Club (Logo + ShortName)
            TableColumn("Club") { club in
                HStack(spacing: 12) {
                    // Logo Logic (Fallback dynamique si pas d'image)
                    if let logoImage = PlatformImage(named: "Logo_\(club.id)") {
                        Image(platformImage: logoImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    } else {
                        // Placeholder Logo : Cercle Couleur Principale + Initiale
                        ZStack {
                            Circle()
                                .fill(Color(hex: club.identity.primaryColor))
                                .strokeBorder(Color(hex: club.identity.secondaryColor), lineWidth: 2)
                            
                            // --- CORRECTION ICI ---
                            // On utilise l'acronyme s'il existe (??), SINON on prend les 3 premières lettres du nom
                            Text(club.acronym ?? String(club.name.prefix(3)).uppercased())
                                .font(.system(size: 8, weight: .bold)) // Taille réduite pour entrer dans le rond
                                .foregroundColor(Color(hex: club.identity.secondaryColor))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5) // Rétrécit le texte si trop long
                        }
                        .frame(width: 32, height: 32)
                    }
                    
                    Text(club.shortName)
                        .font(.headline)
                        .fontWeight(.medium)
                }
            }
            .width(min: 200)
            
            // Colonne 2 : Ville
            TableColumn("Ville") { club in
                // On vérifie si cityId existe ET si on trouve la ville
                if let cityId = club.cityId, let city = database.getCity(byId: cityId) {
                    Text(city.name).foregroundColor(.secondary)
                } else {
                    Text("-").foregroundColor(.gray.opacity(0.5))
                }
            }
            .width(100)
            
            // Colonne 3 : Pays
            TableColumn("Pays") { club in
                // CORRECTION : On cherche directement le pays via l'ID du club
                if let country = database.getCountry(byId: club.countryId) {
                    HStack(spacing: 6) {
                        Text(country.flagEmoji)
                            .font(.title3)
                        Text(country.id)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                } else {
                    // Si l'ID du pays ne correspond à rien dans la base de données
                    Text(club.countryId)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .width(70)
            
            // Colonne 4 : Kits
            TableColumn("Kits") { club in
                HStack(spacing: 10) {
                    MiniKitView(kit: club.getKit(.home), fallbackIcon: "house.fill")
                    MiniKitView(kit: club.getKit(.away), fallbackIcon: "airplane")
                    MiniKitView(kit: club.getKit(.third), fallbackIcon: "tshirt")
                }
            }
            .width(130)
            
            // Colonne 5 : Action
            TableColumn("Action") { club in
                Button(action: {
                    selectedClubWrapper = ClubIDWrapper(id: club.id)
                }) {
                    Label("Éditer", systemImage: "pencil")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .width(50)
        }
        .sheet(item: $selectedClubWrapper) { wrapper in
            if let index = database.clubs.firstIndex(where: { $0.id == wrapper.id }) {
                ClubKitsEditorView(club: $database.clubs[index])
            }
        }
    }
}

// Helper pour les maillots
struct MiniKitView: View {
    let kit: Kit?
    var fallbackIcon: String
    
    var body: some View {
        if let k = kit {
            KitRendererView(kit: k)
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        } else {
            Image(systemName: fallbackIcon)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.1))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.05))
                .cornerRadius(4)
        }
    }
}
