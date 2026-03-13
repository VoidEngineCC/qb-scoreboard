# VD Scoreboard

A modern **QBCore scoreboard UI** for FiveM servers.  
Displays online players, job counts, and activity requirements with a clean customizable UI.

> ⚠️ **Notice**  
> This scoreboard was originally developed for the **VoidCore Framework**.  
> It has been **converted to QBCore**, but because of this conversion **some bugs or unexpected behavior may still occur**. If you encounter issues, feel free to report them.

---

## ✨ Features

- Modern **NUI scoreboard interface**
- **Command-based toggle** (`/scoreboard`)
- Displays **total players online**
- Shows **job counts** (police, ambulance, mechanic, etc.)
- **Activity requirements** (e.g. police required for activities)
- **Customizable themes**
- Lightweight and optimized
- Converted for **QBCore compatibility**

---

## 📦 Requirements

- [QBCore Framework](https://github.com/qbcore-framework)
- FiveM server (DUH)

---

## 📂 Installation

1. Download the latest release.
2. Extract the folder into your server's `resources` directory.

Example:

```
resources/[qb]/vd-scoreboard
```

3. Add the resource to your `server.cfg`:

```
ensure vd-scoreboard
```

4. Restart your server.

---

## ⚙️ Configuration

All configuration is located in:

```
config.lua
```

### Change Scoreboard Command

```lua
Config.Command = 'scoreboard'
```

Default usage:

```
/scoreboard
```

---

### Change Theme

```lua
Config.Theme = 'red'
```

Available themes:

- `red`
- `purple`
- `green`

You can also create **custom themes** inside:

```lua
Config.Themes = {
    red = {
        primaryColor = '#ef4444',
        secondaryColor = '#f87171',
        accentColor = '#dc2626',
        backgroundColor = '#1a1a1a',
        textColor = '#ffffff'
    }
}
```

---

## 👮 Supported Job Counters

The scoreboard can display counts for:

- Police
- Ambulance
- Mechanic
- Bennys
- Biker
- Pizzathis
- Cardealer
- Beanmachine

You can modify job handling inside the scripts if needed.

---

## 🎮 Activities System

Activities can require:

- Minimum **police online**
- Minimum **player level**
- Required **items**

Example configuration:

```lua
{
    name = "chopchop",
    label = "Vehicle Dismantle",
    description = "Rob the jewelry store in the city",
    icon = "fas fa-car",
    minPolice = 3,
    minLevel = 1
}
```

---

## 🖥 UI

The UI is built with:

- HTML
- CSS
- JavaScript

Files are located in:

```
html/
```

You can freely modify styling and layout.

---

## 📁 Resource Structure

```
vd-scoreboard
│
├── client.lua
├── server.lua
├── config.lua
├── fxmanifest.lua
│
└── html
    ├── index.html
    ├── css
    │   └── style.css
    └── js
        └── script.js
```

---

## 👤 Author

**VoidEngineCC**

---

## 📜 License

This project is released for community use.  
You may modify it for your server.

Please keep credits if you redistribute.

---

## 💡 Support

No support is provided..
