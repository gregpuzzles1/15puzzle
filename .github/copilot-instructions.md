# 15 Puzzle Flutter Project

## Project Overview
A Flutter implementation of the classic 15 puzzle sliding tile game.

## Project Status
✅ Project successfully created and configured

### Completed Steps
- [x] Created copilot-instructions.md file
- [x] Scaffolded Flutter project structure
- [x] Implemented 15 puzzle game logic and UI
- [x] Installed dependencies
- [x] Updated README with project documentation

## Features Implemented
- Interactive 4×4 grid with numbered tiles
- Tap-to-slide tile movement
- Move counter tracking
- Smart shuffling ensuring solvability
- Win detection with congratulations dialog
- New game functionality

## Running the Project
To run the application:
```bash
flutter run
```

To run on a specific device:
```bash
flutter devices        # List available devices
flutter run -d <device-id>
```

## Project Structure
- `lib/main.dart` - Main game implementation with puzzle logic and UI
- `.github/copilot-instructions.md` - This file
- `README.md` - Project documentation
- Standard Flutter platform folders (android, ios, web, windows, macos, linux)

## Game Implementation Details
- Uses StatefulWidget for reactive UI updates
- Implements proper move validation
- Shuffles puzzle using valid moves to ensure solvability
- Detects win condition by checking tile order
- Material Design 3 UI with responsive layout
