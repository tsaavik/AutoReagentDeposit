# Auto Reagent Deposit

A World of Warcraft addon that automatically deposits reagents into your Warband bank and personal bank whenever you visit a banker.

## Features

- **Automatic Deposit**: Reagents are automatically deposited when you open your bank
- **Warband Support**: Deposits into Warband bank first (if available), then into your personal bank
- **Zero Configuration**: Works out of the box with no setup required
- **Lightweight**: Minimal performance impact with clean, efficient code

## How It Works

When you interact with a banker and open your bank:
1. All reagents in your bags are first deposited into your **Warband bank** (if available)
2. Any remaining reagents are then deposited into your **personal bank**

This happens automatically - no buttons to click, no commands to remember!

## Installation

### CurseForge/Wago
1. Download from [CurseForge](https://www.curseforge.com/wow/addons/auto-reagent-deposit) or Wago
2. Install using your preferred addon manager

### Manual Installation
1. Download the latest release
2. Extract the `AutoReagentDeposit` folder to your `World of Warcraft\_retail_\Interface\AddOns\` directory
3. Restart WoW or reload your UI (`/reload`)

## Compatibility

- **Interface Version**: 12.0.0 (The War Within)
- **API**: Uses the modern `C_Bank.AutoDepositItemsIntoBank` API
- **Warband Support**: Fully compatible with Warband bank features

## History

This addon is a simplified continuation of **ReagentBanker** by Tuhljin, which stopped working after patch 9.0 (Shadowlands). Auto Reagent Deposit has been updated to use modern WoW APIs and includes support for the new Warband bank system.

## Support

- **Issues**: Report bugs or request features on the [GitHub Issues](https://github.com/yourusername/AutoReagentDeposit/issues) page
- **CurseForge Project**: [Project #1080787](https://www.curseforge.com/wow/addons/auto-reagent-deposit)

## Author

**Tsaavik** (Gnoballs@Greymane)

## License

This addon is free to use and modify.

---

## For Developers

### Debug Mode

To enable debug output in chat, edit `AutoReagentDeposit.lua` and change:
```lua
local DEBUG = false
```
to:
```lua
local DEBUG = true
```

### Building & Releasing

This project uses CurseForge's auto-build system via Git tags:

**Important**: Remember to bump the version in the `.toc` file before tagging!
```bash
 v="4.5" ; git commit -a && git tag -a v$v -m "Release $v" ; git push
```


### API Reference

The addon uses the following WoW API:
- [`C_Bank.AutoDepositItemsIntoBank(bankType)`](https://warcraft.wiki.gg/wiki/API_C_Bank.AutoDepositItemsIntoBank)
  - `bankType = 0`: Personal bank
  - `bankType = 2`: Warband bank
