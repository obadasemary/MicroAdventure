//
//  ContentView.swift
//  MicroAdventure
//
//  Created by Abdelrahman Mohamed on 05.02.2026.
//

import MapKit
import SwiftUI

struct Adventure: Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var category: String
    var effortLevel: String
    var locationName: String
    var latitude: Double
    var longitude: Double
    var isCompleted: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ContentView: View {
    private static let categories = ["Nature", "Food", "Culture", "Urban", "Water"]
    private static let effortLevels = ["Easy", "Moderate", "Challenging"]
    private static let sampleAdventures: [Adventure] = [
        Adventure(
            id: UUID(),
            title: "Golden Gate Sunrise Stroll",
            description: "Catch the morning light, walk a short waterfront loop, and snap a few photos before breakfast.",
            category: "Nature",
            effortLevel: "Easy",
            locationName: "Crissy Field",
            latitude: 37.8044,
            longitude: -122.4659,
            isCompleted: false
        ),
        Adventure(
            id: UUID(),
            title: "Mission Coffee Crawl",
            description: "Try two local roasters within a mile, rate the pour-over, and discover a new favorite.",
            category: "Food",
            effortLevel: "Easy",
            locationName: "Mission District",
            latitude: 37.7599,
            longitude: -122.4148,
            isCompleted: true
        ),
        Adventure(
            id: UUID(),
            title: "Downtown Photo Walk",
            description: "Pick three textures to hunt for and capture five street-level details in 45 minutes.",
            category: "Urban",
            effortLevel: "Moderate",
            locationName: "Market Street",
            latitude: 37.7879,
            longitude: -122.4075,
            isCompleted: false
        )
    ]

    private static let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    private static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    private static let initialRegion = MKCoordinateRegion(
        center: sampleAdventures.first?.coordinate ?? defaultCoordinate,
        span: defaultSpan
    )
    @State private var cameraPosition: MapCameraPosition = .region(Self.initialRegion)
    @State private var currentSpan = Self.defaultSpan
    @State private var selectedCategories = Set(Self.categories)
    @State private var selectedEffortLevels = Set(Self.effortLevels)
    @State private var adventures: [Adventure] = Self.sampleAdventures
    @State private var selectedAdventureId: UUID? = Self.sampleAdventures.first?.id

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(filteredAdventures) { adventure in
                    Annotation(adventure.title, coordinate: adventure.coordinate) {
                        let isSelected = adventure.id == selectedAdventureId
                        Button {
                            selectedAdventureId = adventure.id
                            focus(on: adventure)
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(adventure.isCompleted ? .green : .red)
                                .scaleEffect(isSelected ? 1.2 : 1.0)
                                .offset(y: isSelected ? -6 : 0)
                                .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .top) {
                infoCards
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
            }
            .overlay(alignment: .bottom) {
                nextAdventureButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
            .onMapCameraChange { context in
                currentSpan = context.region.span
            }
            .onChange(of: selectedCategories) { _, _ in
                ensureSelectedAdventure()
            }
            .onChange(of: selectedEffortLevels) { _, _ in
                ensureSelectedAdventure()
            }
            .onChange(of: selectedAdventureId) { _, newValue in
                guard let newValue,
                      let adventure = filteredAdventures.first(where: { $0.id == newValue }) else {
                    return
                }
                focus(on: adventure)
            }
            .onAppear {
                ensureSelectedAdventure()
            }
            .navigationTitle("Micro Adventures")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reset Filters") {
                            selectedCategories = Set(Self.categories)
                            selectedEffortLevels = Set(Self.effortLevels)
                        }
                        Section("Categories") {
                            Button("Clear All") {
                                selectedCategories.removeAll()
                            }
                            Button("Select All") {
                                selectedCategories = Set(Self.categories)
                            }
                            ForEach(Self.categories, id: \.self) { category in
                                Toggle(category, isOn: bindingForCategory(category))
                            }
                        }
                        Section("Effort Level") {
                            Button("Clear All") {
                                selectedEffortLevels.removeAll()
                            }
                            Button("Select All") {
                                selectedEffortLevels = Set(Self.effortLevels)
                            }
                            ForEach(Self.effortLevels, id: \.self) { effort in
                                Toggle(effort, isOn: bindingForEffortLevel(effort))
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    private var selectedAdventure: Adventure? {
        filteredAdventures.first { $0.id == selectedAdventureId }
    }

    private var infoCards: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(filteredAdventures) { adventure in
                        adventureCard(for: adventure)
                    }
                }
                .scrollTargetLayout()
                .padding(.trailing, 6)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedAdventureId, anchor: .center)
            carouselDots
        }
        .frame(maxHeight: 240)
    }

    private var carouselDots: some View {
        Group {
            if filteredAdventures.count > 1 {
                HStack(spacing: 6) {
                    ForEach(filteredAdventures) { adventure in
                        let isActive = adventure.id == selectedAdventureId
                        Circle()
                            .fill(isActive ? Color.accentColor : Color.accentColor.opacity(0.3))
                            .frame(width: isActive ? 8 : 6, height: isActive ? 8 : 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    private func adventureCard(for adventure: Adventure) -> some View {
        let isSelected = adventure.id == selectedAdventureId
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                pill(text: adventure.category)
                pill(text: adventure.effortLevel)
            }

            Text(adventure.title)
                .font(.headline)
                .fontWeight(.bold)

            Text(adventure.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button {
                    toggleAdventureCompletion(for: adventure.id)
                } label: {
                    Text(adventure.isCompleted ? "Completed" : "Mark Complete")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? .blue.opacity(0.7) : .white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        .frame(maxWidth: 360)
        .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 28)
        .padding(.trailing, 14)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        .onTapGesture {
            selectedAdventureId = adventure.id
            focus(on: adventure)
        }
    }

    private var nextAdventureButton: some View {
        Button {
            advanceToNextAdventure()
        } label: {
            Text("Next Adventure")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    private func pill(text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }

    private func bindingForCategory(_ category: String) -> Binding<Bool> {
        Binding(
            get: { selectedCategories.contains(category) },
            set: { isOn in
                if isOn {
                    selectedCategories.insert(category)
                } else {
                    selectedCategories.remove(category)
                }
            }
        )
    }

    private func bindingForEffortLevel(_ effort: String) -> Binding<Bool> {
        Binding(
            get: { selectedEffortLevels.contains(effort) },
            set: { isOn in
                if isOn {
                    selectedEffortLevels.insert(effort)
                } else {
                    selectedEffortLevels.remove(effort)
                }
            }
        )
    }

    private func toggleAdventureCompletion(for adventureId: UUID) {
        guard let index = adventures.firstIndex(where: { $0.id == adventureId }) else { return }
        adventures[index].isCompleted.toggle()
    }

    private func advanceToNextAdventure() {
        guard !filteredAdventures.isEmpty else { return }
        if let selectedId = selectedAdventureId,
           let currentIndex = filteredAdventures.firstIndex(where: { $0.id == selectedId }) {
            let nextIndex = (currentIndex + 1) % filteredAdventures.count
            let nextAdventure = filteredAdventures[nextIndex]
            selectedAdventureId = nextAdventure.id
            focus(on: nextAdventure)
            return
        }
        if let firstAdventure = filteredAdventures.first {
            selectedAdventureId = firstAdventure.id
            focus(on: firstAdventure)
        }
    }

    private var filteredAdventures: [Adventure] {
        adventures.filter { adventure in
            selectedCategories.contains(adventure.category) && selectedEffortLevels.contains(adventure.effortLevel)
        }
    }

    private func ensureSelectedAdventure() {
        if let selectedId = selectedAdventureId,
           filteredAdventures.contains(where: { $0.id == selectedId }) {
            return
        }
        selectedAdventureId = filteredAdventures.first?.id
        if let adventure = filteredAdventures.first {
            focus(on: adventure)
        }
    }

    private func focus(on adventure: Adventure) {
        withAnimation(.easeInOut(duration: 0.6)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: adventure.coordinate,
                    span: currentSpan
                )
            )
        }
    }
}

#Preview {
    ContentView()
}
