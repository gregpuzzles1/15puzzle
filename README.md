# 15 Puzzle Games

A Flutter implementation of the classic 15 puzzle sliding tile game.

## 🎮 Play Online

**[Play Now →](https://gregpuzzles1.github.io/15puzzle/)**

The game is deployed and playable online at: https://gregpuzzles1.github.io/15puzzle/

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
- **Responsive Design**: Adapts seamlessly to desktop (≥1024px), tablet (768-1023px), and mobile (<768px) screens
- **Web Platform**: Playable in modern web browsers with loading screen and fallback support
- **Cross-Platform**: Runs on Android, iOS, Windows, macOS, Linux, and Web

## How to Play

The goal is to slide the numbered tiles until they are in order from 1 to 15, with the empty space in the bottom-right corner. Click or tap a tile next to the empty space to move it into the gap.

Try to solve the puzzle in as few moves as possible. If you get stuck, press **"New Game"** to reshuffle and start fresh.

- The puzzle starts in a shuffled state with tiles numbered 1–15  
- Tap any tile adjacent to the empty space to slide it  
- Continue sliding tiles until they are arranged in order from 1–15  
- The puzzle is solved when all tiles are in numerical order with the empty space in the bottom-right corner  
- Click **"New Game"** to start over with a new shuffle  

## A Bit of History

The 15 puzzle is a classic sliding puzzle from the late 1800s. It became a worldwide craze when people challenged friends and family to restore the tiles to the correct order after scrambling them.

Today it’s still popular as a quick logic game and a great example of how simple rules can create surprisingly deep challenges — including the fact that only certain scrambled positions are solvable.

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
