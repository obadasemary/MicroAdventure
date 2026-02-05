//
//  SnakeGameLogic.swift
//  MicroAdventure
//
//  Created by Abdelrahman Mohamed on 05.02.2026.
//

import Foundation

struct GridPoint: Hashable, Equatable {
    let x: Int
    let y: Int

    func moved(_ direction: SnakeDirection) -> GridPoint {
        GridPoint(x: x + direction.delta.dx, y: y + direction.delta.dy)
    }
}

enum SnakeDirection: CaseIterable, Equatable {
    case up
    case down
    case left
    case right

    var delta: (dx: Int, dy: Int) {
        switch self {
        case .up:
            return (0, -1)
        case .down:
            return (0, 1)
        case .left:
            return (-1, 0)
        case .right:
            return (1, 0)
        }
    }

    var opposite: SnakeDirection {
        switch self {
        case .up:
            return .down
        case .down:
            return .up
        case .left:
            return .right
        case .right:
            return .left
        }
    }
}

struct SnakeGameState: Equatable {
    let columns: Int
    let rows: Int
    var snake: [GridPoint]
    var direction: SnakeDirection
    var pendingDirection: SnakeDirection?
    var food: GridPoint
    var score: Int
    var isGameOver: Bool
    var isPaused: Bool
    var pendingGrowth: Int

    init(
        columns: Int,
        rows: Int,
        snake: [GridPoint],
        direction: SnakeDirection,
        food: GridPoint,
        pendingGrowth: Int = 0,
        score: Int = 0,
        isGameOver: Bool = false,
        isPaused: Bool = false
    ) {
        self.columns = columns
        self.rows = rows
        self.snake = snake
        self.direction = direction
        self.pendingDirection = nil
        self.food = food
        self.score = score
        self.isGameOver = isGameOver
        self.isPaused = isPaused
        self.pendingGrowth = pendingGrowth
    }

    static func newGame<R: RandomNumberGenerator>(columns: Int, rows: Int, using rng: inout R) -> SnakeGameState {
        let startX = max(2, columns / 2)
        let startY = rows / 2
        let head = GridPoint(x: startX, y: startY)
        let middle = GridPoint(x: startX - 1, y: startY)
        let tail = GridPoint(x: startX - 2, y: startY)
        var state = SnakeGameState(
            columns: columns,
            rows: rows,
            snake: [head, middle, tail],
            direction: .right,
            food: head
        )
        state.placeFood(using: &rng)
        return state
    }

    mutating func reset<R: RandomNumberGenerator>(using rng: inout R) {
        self = SnakeGameState.newGame(columns: columns, rows: rows, using: &rng)
    }

    mutating func setDirection(_ newDirection: SnakeDirection) {
        guard !isGameOver else { return }
        if snake.count > 1, newDirection == direction.opposite {
            return
        }
        pendingDirection = newDirection
    }

    mutating func togglePause() {
        guard !isGameOver else { return }
        isPaused.toggle()
    }

    mutating func tick<R: RandomNumberGenerator>(using rng: inout R) {
        guard !isGameOver, !isPaused else { return }

        if let pendingDirection {
            direction = pendingDirection
            self.pendingDirection = nil
        }

        guard let head = snake.first else {
            isGameOver = true
            return
        }

        let nextHead = head.moved(direction)
        if isOutOfBounds(nextHead) {
            isGameOver = true
            return
        }

        let willGrow = pendingGrowth > 0 || nextHead == food
        let bodyToCheck = willGrow ? snake : Array(snake.dropLast())
        if bodyToCheck.contains(nextHead) {
            isGameOver = true
            return
        }

        snake.insert(nextHead, at: 0)

        if nextHead == food {
            score += 1
            pendingGrowth += 1
            placeFood(using: &rng)
        }

        if pendingGrowth > 0 {
            pendingGrowth -= 1
        } else {
            snake.removeLast()
        }
    }

    mutating func placeFood<R: RandomNumberGenerator>(using rng: inout R) {
        let occupied = Set(snake)
        var available: [GridPoint] = []
        available.reserveCapacity(columns * rows)
        for row in 0..<rows {
            for column in 0..<columns {
                let point = GridPoint(x: column, y: row)
                if !occupied.contains(point) {
                    available.append(point)
                }
            }
        }

        guard !available.isEmpty else {
            isGameOver = true
            return
        }

        let index = Int.random(in: 0..<available.count, using: &rng)
        food = available[index]
    }

    private func isOutOfBounds(_ point: GridPoint) -> Bool {
        point.x < 0 || point.x >= columns || point.y < 0 || point.y >= rows
    }
}
