# Warcell ⚔️

> *Infinity Blade* combat meets the *Helldivers 2* galactic war. A persistent, community-driven medieval campaign fought one perfect parry at a time.

**Warcell** is an asynchronous MMO action game designed for mobile. Players act as individual soldiers in a massive, ongoing fantasy war, fighting bite-sized, high-skill combat sessions to conquer territory on a globally shared map.

## 🎯 The Vision

Bridging the gap between casual mobile sessions and hardcore action mechanics. Players can drop in for a 3-minute session, execute precise directional parries and strikes, and actively contribute to a massive, community-wide war effort before closing the app.

## 🔄 Core Gameplay Loop

### 1. The Global Map (The War)

* **One Shared State:** The game features a single, persistent top-down map divided into a massive grid of cells.
* **Community Driven:** Every registered player shares this exact same map state.
* **Cell Sieges:** Cells contain enemy encounters or events. Players select a frontline cell to "challenge," dropping them into a combat session.
* **Asynchronous Progress:** Instead of locking cells, thousands of players can siege a single cell simultaneously. Successful combat sessions chip away at a cell's massive global health pool. Once depleted, the territory is claimed for the player faction.

### 2. The Frontline (The Combat)

* **First-Person Action:** Combat is viewed from a portrait, first-person perspective against 1-3 enemies.
* **Rhythm & Precision:** Mechanics are heavily inspired by *Sekiro* and *Infinity Blade*. Combat relies on reading enemy telegraphs and responding with precise directional swipes to parry, block, or counter-attack.
* **Session-Based:** Encounters are short, intense, and designed for one-handed mobile play.

## 🛠️ Tech Stack (Current)

* **Engine:** Godot 4.x
* **Language:** GDScript
* **Target Platforms:** iOS & Android
* **Backend Architecture:** *[TBD - Planning phase for handling asynchronous global state, concurrent damage reports, and player profiles]*

## 🚀 Current Status: Prototyping

Currently building out the core combat loop. 

* **Focus:** Perfecting touchscreen swipe detection, directional parry logic, and enemy attack telegraphs in a 3D environment.