<div align="center">
  
### VPS Tools Dashboard

![Bash](https://x.xcute.workers.dev/f/images/ef9c10520a79.gif)



**One dashboard. One command. Every tool your VPS needs.**

[Features](#-features) • [Install](#-installation) • [Usage](#-usage) • [Menu](#-menu-list) • [Contributing](#-contributing)

</div>

---

## 📋 About

**Moon Luna** is a lightweight, interactive bash dashboard that turns VPS setup into a one-key experience:

- 📊 Instantly inspect your server specs — no more digging through five different commands
- ⚙️ Spin up web servers, runtimes, and dev tools with a single keypress
- 🖱️ Fully menu-driven — pick a number, hit `y`, done

Built for people who'd rather manage servers than memorize `apt install` incantations.

## ✨ Features

| | |
|---|---|
| 📊 | Full system report — OS, kernel, CPU, RAM, disk, load average |
| 🌐 | One-click Nginx install |
| 📦 | Git install + instant repo cloning |
| ⚡ | Node.js installer (v16 / v18 / v20) |
| 📦 | NVM (Node Version Manager) setup |
| 🎮 | Pterodactyl Panel installer |
| 🎨 | Neofetch install |
| 🔧 | Batch-install multiple tools in one go |
| 🎬 | Loading animations & progress bars so waiting doesn't feel like waiting |

## 🛠️ Requirements

- Ubuntu / Debian (or a derivative)
- `root` or `sudo` access
- An active internet connection

## 📥 Installation

**Clone it:**

```bash
git clone https://github.com/mooonlunaa/vpstools.git
cd vpstools
chmod +x vpstools.sh
```

## ▶️ Usage

Run it as root:

```bash
sudo bash ranzx.sh
```

The interactive menu pops up — type the number you want, hit Enter, and let Ranzx do the rest.

## 📜 Menu List

| No | Menu | Description |
|----|------|------------|
| 1 | 📊 System Info | Full VPS specs at a glance |
| 2 | 🌐 Install Nginx | Sets up and starts the Nginx web server |
| 3 | 📦 Git + Clone | Installs Git and clones a repo of your choice |
| 4 | ⚡ Install Node.js | Choose between v16 / v18 / v20 |
| 5 | 📦 Install NVM | Node Version Manager setup |
| 6 | 🎮 Pterodactyl Panel | Installs the game server panel |
| 7 | 🎨 Install Neofetch | System info fetch tool |
| 8 | 🔧 Multi-install | Install several tools at once |
| 0 | ❌ Exit | Closes the dashboard |

## ⚠️ Notes

- The script runs `sudo apt install` under the hood — know what you're installing before confirming `y`
- Pterodactyl Panel requires PHP, MySQL/MariaDB, and Composer to already be set up
- After installing NVM, open a fresh terminal before running `nvm`

## 🤝 Contributing

PRs are always welcome. For bigger changes, open an issue first so we can talk it through.

1. Fork the repo
2. Create a branch (`git checkout -b feature-name`)
3. Commit your changes (`git commit -m 'Add feature X'`)
4. Push the branch (`git push origin feature-name`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License.

## 👤 Identity

```yaml
identity:
  name: moonluna
  role: IT tinkerer / VPS enthusiast
  hobbies:
    - sleeping 😴
    - listening to music 🎧
  socials:
    github: "@moonluna"
    instagram: "@moonluna"
    telegram: "@moonluna"
```

---

<div align="center">

⭐ If Ranzx saved you some typing, drop a **star** — it means a lot.

</div>
