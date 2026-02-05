//
//  MicroAdventureTests.swift
//  MicroAdventureTests
//
//  Created by Abdelrahman Mohamed on 05.02.2026.
//

import Testing
@testable import MicroAdventure

struct MicroAdventureTests {

    @Test func snakeMovesForward() async throws {
        var rng = SeededGenerator(seed: 1)
        var state = SnakeGameState(
            columns: 6,
            rows: 6,
            snake: [
                GridPoint(x: 2, y: 2),
                GridPoint(x: 1, y: 2),
                GridPoint(x: 0, y: 2)
            ],
            direction: .right,
            food: GridPoint(x: 5, y: 5)
        )

        state.tick(using: &rng)

        #expect(state.snake == [
            GridPoint(x: 3, y: 2),
            GridPoint(x: 2, y: 2),
            GridPoint(x: 1, y: 2)
        ])
        #expect(state.score == 0)
        #expect(state.isGameOver == false)
    }

    @Test func snakeEatsFoodAndGrows() async throws {
        var rng = SeededGenerator(seed: 2)
        var state = SnakeGameState(
            columns: 6,
            rows: 6,
            snake: [
                GridPoint(x: 2, y: 2),
                GridPoint(x: 1, y: 2),
                GridPoint(x: 0, y: 2)
            ],
            direction: .right,
            food: GridPoint(x: 3, y: 2)
        )

        state.tick(using: &rng)

        #expect(state.score == 1)
        #expect(state.snake.count == 4)
        #expect(state.snake.first == GridPoint(x: 3, y: 2))
        #expect(state.snake.contains(state.food) == false)
    }

    @Test func snakeHitsWall() async throws {
        var rng = SeededGenerator(seed: 3)
        var state = SnakeGameState(
            columns: 4,
            rows: 4,
            snake: [
                GridPoint(x: 3, y: 1),
                GridPoint(x: 2, y: 1)
            ],
            direction: .right,
            food: GridPoint(x: 0, y: 0)
        )

        state.tick(using: &rng)

        #expect(state.isGameOver == true)
    }

    @Test func snakeHitsItself() async throws {
        var rng = SeededGenerator(seed: 4)
        var state = SnakeGameState(
            columns: 5,
            rows: 5,
            snake: [
                GridPoint(x: 2, y: 2),
                GridPoint(x: 2, y: 3),
                GridPoint(x: 1, y: 3),
                GridPoint(x: 1, y: 2)
            ],
            direction: .down,
            food: GridPoint(x: 4, y: 4)
        )

        state.tick(using: &rng)

        #expect(state.isGameOver == true)
    }

    @Test func foodSpawnsInOnlyAvailableCell() async throws {
        var rng = SeededGenerator(seed: 5)
        var snake: [GridPoint] = []
        for row in 0..<4 {
            for column in 0..<4 {
                if row == 3 && column == 3 { continue }
                snake.append(GridPoint(x: column, y: row))
            }
        }

        var state = SnakeGameState(
            columns: 4,
            rows: 4,
            snake: snake,
            direction: .right,
            food: GridPoint(x: 0, y: 0)
        )

        state.placeFood(using: &rng)

        #expect(state.food == GridPoint(x: 3, y: 3))
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}
