# 15 Puzzle Game

A Flutter implementation of the classic 15 puzzle sliding tile game.

## Demo

![15 Puzzle Game Demo](/assets/output.gif)

## About the Game

The 15 puzzle is a sliding puzzle with 15 numbered tiles in a 4×4 grid with one empty space. The objective is to arrange the tiles in numerical order (1-15) by sliding them into the empty space.

## Features

- **Interactive Gameplay**: Tap tiles adjacent to the empty space to slide them  
- **Move Counter**: Track the number of moves taken to solve the puzzle  
- **Smart Shuffling**: Puzzle is shuffled using valid moves to ensure solvability  
- **Win Detection**: Automatically detects when puzzle is solved  
- **New Game**: Start a fresh game at any time  

## How to Play

- The puzzle starts in a shuffled state with tiles numbered 1–15  
- Tap any tile adjacent to the empty space to slide it  
- Continue sliding tiles until they are arranged in order from 1–15  
- The puzzle is solved when all tiles are in numerical order with the empty space in the bottom-right corner  
- Click **"New Game"** to start over with a new shuffle  

## Getting Started

### Prerequisites

- Flutter SDK installed (Installation Guide)
- A device or emulator to run the app

### Running the App

1. Clone or download this repository
2. Navigate to the project directory
3. Run the following commands:

```bash
flutter pub get
flutter run
