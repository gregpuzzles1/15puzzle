# 15 Puzzle Game

A Flutter implementation of the classic 15 puzzle sliding tile game.

## About the Game

The 15 puzzle is a sliding puzzle with 15 numbered tiles in a 4×4 grid with one empty space. The objective is to arrange the tiles in numerical order (1-15) by sliding them into the empty space.

## Features

- **Interactive Gameplay**: Tap tiles adjacent to the empty space to slide them
- **Move Counter**: Track the number of moves taken to solve the puzzle
- **Smart Shuffling**: Puzzle is shuffled using valid moves to ensure solvability
- **Win Detection**: Automatically detects when puzzle is solved
- **New Game**: Start a fresh game at any time

## Getting Started

### Prerequisites

- Flutter SDK installed ([Installation Guide](https://docs.flutter.dev/get-started/install))
- A device or emulator to run the app

### Running the App

1. Clone or download this repository
2. Navigate to the project directory
3. Run the following commands:

```bash
flutter pub get
flutter run
```

## How to Play

1. The puzzle starts in a shuffled state with tiles numbered 1-15
2. Tap any tile adjacent to the empty space to slide it
3. Continue sliding tiles until they are arranged in order from 1-15
4. The puzzle is solved when all tiles are in numerical order with the empty space in the bottom-right corner
5. Click "New Game" to start over with a new shuffle

## Project Structure

- `lib/main.dart` - Main application code containing the puzzle logic and UI
- Standard Flutter project structure for Android, iOS, Web, Windows, macOS, and Linux

## Built With

- [Flutter](https://flutter.dev/) - UI framework
- [Dart](https://dart.dev/) - Programming language

## Game Mechanics

The puzzle implements proper solvability by:
- Shuffling using only valid moves (never creating unsolvable states)
- Validating moves to ensure tiles can only slide into the empty space
- Checking win conditions after each move

## License

This project is open source and available for educational purposes.
