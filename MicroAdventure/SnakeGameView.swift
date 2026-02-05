//
//  SnakeGameView.swift
//  MicroAdventure
//
//  Created by Abdelrahman Mohamed on 05.02.2026.
//

import Combine
import SwiftUI
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct SnakeGameView: View {
    private enum SnakeAIDifficulty: String, CaseIterable, Identifiable {
        case relaxed
        case normal
        case intense

        var id: String { rawValue }

        var label: String {
            switch self {
            case .relaxed:
                return "Relaxed"
            case .normal:
                return "Normal"
            case .intense:
                return "Intense"
            }
        }

        var tickInterval: TimeInterval {
            switch self {
            case .relaxed:
                return 0.24
            case .normal:
                return 0.18
            case .intense:
                return 0.12
            }
        }
    }

    private let columns = 18
    private let rows = 18
    private var tickInterval: TimeInterval { difficulty.tickInterval }

    @State private var rng = SystemRandomNumberGenerator()
    @State private var game: SnakeGameState
    @State private var isAIEnabled = false
    @State private var difficulty: SnakeAIDifficulty = .normal
    @State private var manualOverrideTicks = 0

    init() {
        var generator = SystemRandomNumberGenerator()
        let initial = SnakeGameState.newGame(columns: columns, rows: rows, using: &generator)
        _rng = State(initialValue: generator)
        _game = State(initialValue: initial)
    }

    var body: some View {
        let timer = Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
        NavigationStack {
            VStack(spacing: 16) {
                header
                SnakeBoardView(state: game)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Snake board")
                statusText
                controlPad
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .navigationTitle("Snake")
            .navigationBarTitleDisplayMode(.inline)
        }
        .overlay(
            SnakeKeyInputView(
                onDirection: { direction in
                    setDirection(direction)
                },
                onPauseToggle: {
                    togglePause()
                }
            )
            .frame(width: 0, height: 0)
        )
        .onReceive(timer) { _ in
            tick()
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(game.score)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                Button(game.isPaused ? "Resume" : "Pause") {
                    togglePause()
                }
                .buttonStyle(.bordered)
                .disabled(game.isGameOver)

                Button("Restart") {
                    restart()
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 12) {
                Toggle("AI", isOn: $isAIEnabled)
                    .toggleStyle(.switch)
                    .disabled(game.isGameOver)

                Picker("Difficulty", selection: $difficulty) {
                    ForEach(SnakeAIDifficulty.allCases) { level in
                        Text(level.label).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!isAIEnabled || game.isGameOver)
            }
        }
    }

    private var statusText: some View {
        Group {
            if game.isGameOver {
                Text("Game Over")
                    .font(.headline)
                    .foregroundStyle(.red)
            } else if game.isPaused {
                Text("Paused")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                if isAIEnabled, manualOverrideTicks > 0 {
                    Text("Manual override active")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text(isAIEnabled ? "AI is playing" : "Use arrow keys or WASD")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var controlPad: some View {
        VStack(spacing: 10) {
            Button {
                setDirection(.up)
            } label: {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.title2)
                    .frame(width: 52, height: 40)
            }
            .buttonStyle(.bordered)

            HStack(spacing: 16) {
                Button {
                    setDirection(.left)
                } label: {
                    Image(systemName: "arrowtriangle.left.fill")
                        .font(.title2)
                        .frame(width: 52, height: 40)
                }
                .buttonStyle(.bordered)

                Button {
                    setDirection(.right)
                } label: {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.title2)
                        .frame(width: 52, height: 40)
                }
                .buttonStyle(.bordered)
            }

            Button {
                setDirection(.down)
            } label: {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.title2)
                    .frame(width: 52, height: 40)
            }
            .buttonStyle(.bordered)
        }
        .disabled(game.isGameOver)
    }

    private func tick() {
        var copy = rng
        if isAIEnabled, manualOverrideTicks == 0 {
            let direction = aiDirection(for: game, using: &copy)
            game.setDirection(direction)
        } else if manualOverrideTicks > 0 {
            manualOverrideTicks -= 1
        }
        game.tick(using: &copy)
        rng = copy
    }

    private func setDirection(_ direction: SnakeDirection) {
        if isAIEnabled {
            manualOverrideTicks = 3
        }
        game.setDirection(direction)
    }

    private func togglePause() {
        game.togglePause()
    }

    private func restart() {
        var copy = rng
        game.reset(using: &copy)
        rng = copy
    }

    private func aiDirection(for state: SnakeGameState, using rng: inout SystemRandomNumberGenerator) -> SnakeDirection {
        guard let head = state.snake.first else { return state.direction }

        let candidates = SnakeDirection.allCases.filter { direction in
            if state.snake.count > 1, direction == state.direction.opposite {
                return false
            }
            let nextHead = head.moved(direction)
            if isOutOfBounds(nextHead, columns: state.columns, rows: state.rows) {
                return false
            }
            let willGrow = state.pendingGrowth > 0 || nextHead == state.food
            let bodyToCheck = willGrow ? state.snake : Array(state.snake.dropLast())
            return !bodyToCheck.contains(nextHead)
        }

        guard !candidates.isEmpty else { return state.direction }

        let food = state.food
        let scored = candidates.map { direction -> (SnakeDirection, Int) in
            let next = head.moved(direction)
            let distance = abs(next.x - food.x) + abs(next.y - food.y)
            return (direction, distance)
        }

        let minDistance = scored.map(\.1).min() ?? 0
        let best = scored.filter { $0.1 == minDistance }.map(\.0)

        switch difficulty {
        case .relaxed:
            if Int.random(in: 0..<10, using: &rng) < 3 {
                return best.randomElement(using: &rng) ?? state.direction
            }
            return candidates.randomElement(using: &rng) ?? state.direction
        case .intense:
            if best.contains(state.direction) { return state.direction }
            if let straight = best.first(where: { $0 == state.direction }) { return straight }
            if Int.random(in: 0..<100, using: &rng) < 95 {
                return best.randomElement(using: &rng) ?? state.direction
            }
            return candidates.randomElement(using: &rng) ?? state.direction
        case .normal:
            if Int.random(in: 0..<10, using: &rng) < 7 {
                return best.randomElement(using: &rng) ?? state.direction
            }
            return candidates.randomElement(using: &rng) ?? state.direction
        }

        if best.isEmpty {
            return candidates.randomElement(using: &rng) ?? state.direction
        }
        let index = Int.random(in: 0..<best.count, using: &rng)
        return best[index]
    }

    private func isOutOfBounds(_ point: GridPoint, columns: Int, rows: Int) -> Bool {
        point.x < 0 || point.x >= columns || point.y < 0 || point.y >= rows
    }
}

private struct SnakeBoardView: View {
    let state: SnakeGameState

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cell = size / CGFloat(state.columns)

            Canvas { context, _ in
                let boardRect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
                context.fill(Path(roundedRect: boardRect, cornerSize: CGSize(width: 16, height: 16)), with: .color(Color(.systemGray6)))

                for segmentIndex in state.snake.indices {
                    let point = state.snake[segmentIndex]
                    let rect = CGRect(
                        x: CGFloat(point.x) * cell,
                        y: CGFloat(point.y) * cell,
                        width: cell,
                        height: cell
                    ).insetBy(dx: cell * 0.12, dy: cell * 0.12)
                    let color: Color = segmentIndex == 0 ? .green : .green.opacity(0.75)
                    context.fill(
                        Path(roundedRect: rect, cornerSize: CGSize(width: cell * 0.2, height: cell * 0.2)),
                        with: .color(color)
                    )
                }

                let foodRect = CGRect(
                    x: CGFloat(state.food.x) * cell,
                    y: CGFloat(state.food.y) * cell,
                    width: cell,
                    height: cell
                ).insetBy(dx: cell * 0.18, dy: cell * 0.18)
                context.fill(
                    Path(roundedRect: foodRect, cornerSize: CGSize(width: cell * 0.3, height: cell * 0.3)),
                    with: .color(.orange)
                )
            }
            .frame(width: size, height: size)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct SnakeKeyInputView: View {
    let onDirection: (SnakeDirection) -> Void
    let onPauseToggle: () -> Void

    var body: some View {
        KeyInputRepresentable(onDirection: onDirection, onPauseToggle: onPauseToggle)
    }
}

#if os(iOS) || os(tvOS)
private struct KeyInputRepresentable: UIViewControllerRepresentable {
    let onDirection: (SnakeDirection) -> Void
    let onPauseToggle: () -> Void

    func makeUIViewController(context: Context) -> KeyInputController {
        let controller = KeyInputController()
        controller.onDirection = onDirection
        controller.onPauseToggle = onPauseToggle
        return controller
    }

    func updateUIViewController(_ uiViewController: KeyInputController, context: Context) {
        uiViewController.onDirection = onDirection
        uiViewController.onPauseToggle = onPauseToggle
    }

    final class KeyInputController: UIViewController {
        var onDirection: ((SnakeDirection) -> Void)?
        var onPauseToggle: (() -> Void)?

        override var canBecomeFirstResponder: Bool { true }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder()
        }

        override var keyCommands: [UIKeyCommand]? {
            [
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(handleUp)),
                UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(handleDown)),
                UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleLeft)),
                UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleRight)),
                UIKeyCommand(input: "w", modifierFlags: [], action: #selector(handleUp)),
                UIKeyCommand(input: "s", modifierFlags: [], action: #selector(handleDown)),
                UIKeyCommand(input: "a", modifierFlags: [], action: #selector(handleLeft)),
                UIKeyCommand(input: "d", modifierFlags: [], action: #selector(handleRight)),
                UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handlePause))
            ]
        }

        @objc private func handleUp() {
            onDirection?(.up)
        }

        @objc private func handleDown() {
            onDirection?(.down)
        }

        @objc private func handleLeft() {
            onDirection?(.left)
        }

        @objc private func handleRight() {
            onDirection?(.right)
        }

        @objc private func handlePause() {
            onPauseToggle?()
        }
    }
}
#elseif os(macOS)
private struct KeyInputRepresentable: NSViewRepresentable {
    let onDirection: (SnakeDirection) -> Void
    let onPauseToggle: () -> Void

    func makeNSView(context: Context) -> KeyInputView {
        let view = KeyInputView()
        view.onDirection = onDirection
        view.onPauseToggle = onPauseToggle
        return view
    }

    func updateNSView(_ nsView: KeyInputView, context: Context) {
        nsView.onDirection = onDirection
        nsView.onPauseToggle = onPauseToggle
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class KeyInputView: NSView {
        var onDirection: ((SnakeDirection) -> Void)?
        var onPauseToggle: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }

        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 126:
                onDirection?(.up)
                return
            case 125:
                onDirection?(.down)
                return
            case 123:
                onDirection?(.left)
                return
            case 124:
                onDirection?(.right)
                return
            default:
                break
            }

            if let characters = event.charactersIgnoringModifiers?.lowercased() {
                switch characters {
                case "w":
                    onDirection?(.up)
                    return
                case "s":
                    onDirection?(.down)
                    return
                case "a":
                    onDirection?(.left)
                    return
                case "d":
                    onDirection?(.right)
                    return
                case " ":
                    onPauseToggle?()
                    return
                default:
                    break
                }
            }

            super.keyDown(with: event)
        }
    }
}
#endif

#Preview {
    SnakeGameView()
}
