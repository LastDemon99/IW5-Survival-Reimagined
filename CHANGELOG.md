# 📌 Changelog – IW5-Survival-Reimagined v3.0

### 🛠️ General Improvements
- **Start Time Reset Fix**: Fixed an issue where `getTime` persisted from the server's start instead of resetting on every map change, causing incorrect match time display.
- **Post-Death Exploit Fix**: Addressed an exploit where players could disconnect after dying and reconnect to respawn without penalty.
- **Map Load Coordination**: Added a feature that allows players to wait for others before starting the match. After a map change, the game now waits until someone manually starts the round.
- **Auto Map Rotation**: Now the map will rotate automatically if all players disconnect, avoiding rounds being stuck indefinitely in high waves.

### 💥 Combat & AI Changes
- **Airstrike vs Helicopters**: Airstrikes now deal damage to helicopters.
- **Helicopter AI on Custom Maps**: Fixed helicopters not functioning properly on custom maps without Guard Nodes. These nodes enable aggressive behavior like descending to attack instead of hovering.
- **Helicopter Damage Rebalance**: Updated helicopter damage values for improved gameplay balance.
- **Reduced Bot Melee Range**: The melee attack range of bots has been decreased to make close encounters less punishing.
- **Dog Melee Auto-Aim**: Added auto-aim functionality to dog melee attacks for smoother combat.
- **Sentry Gun Damage Fix**: Corrected sentry gun damage values and added modified damage behavior.
- **Enemy Voice Lines**: Added voice lines for enemy attackers to enhance audio feedback and immersion.

### 🔧 Gameplay Mechanics
- **Revive System Fixes**: Players can now be revived by teammates when downed (note: not using the standard revive system). Fixed an issue where reviving could cause players to become stuck.
- **Weapon & Ammo Pickup System Rework**: Redesigned the entire pickup/drop system to use a single trigger, maintaining the preservation of weapon buffs and ammunition while improving performance and reducing entity load.
- **Weapon/Entity Overflow Fix**: Implemented periodic cleanup of dropped weapons and corpses to prevent crashes in high-round scenarios due to entity overflow.
- **Predator Missile Bug**: Fixed a bug that rendered the Predator missile unusable.
- **Drop Restriction Near Armories**: Disabled weapon drop functionality when near armories to prevent overlapping entities and UI clutter.
- **Player Limit Increased**: The default maximum number of players has been increased to 5. As a result, the game difficulty has been adjusted to scale more aggressively with player count.

### 🛍️ Shop System
- **Joystick Input Bug**: Fixed an issue where joystick users would unintentionally spam the shop interface.
- **Shop Validation**: Added internal checks to make the shop system more stable and less prone to crashes.

### 🌍 Map & Content Additions
- **DLC Maps**: All DLC maps are now supported, including those that were never part of the original Survival Mode.
- **Plutonium Maps**: Plutonium maps are now supported.
- **Map Edit DSR**: A pre-configured DSR is now included to allow easy map editing and custom setup creation.
