#!/bin/bash
# ── Colors ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/vps-tools.log"

BOX_WIDTH=58   # lebar isi box (tanpa border kiri/kanan)

# ── Helper: cetak baris box dengan padding otomatis ──────
# Menghitung panjang visual (strip kode warna & emoji dihitung lebar 2)
# supaya border kanan selalu rapi walau isinya beda-beda panjang.
visual_len() {
    local s="$1"
    # buang kode warna ANSI
    s=$(echo -ne "$s" | sed -E 's/\x1b\[[0-9;]*m//g')
    local len=0 char
    local i=0
    while [ $i -lt ${#s} ]; do
        char="${s:$i:1}"
        # deteksi karakter multi-byte (emoji/unicode) kasar: anggap lebar 2 jika byte > 127
        if [[ "$char" =~ [^\x00-\x7F] ]]; then
            len=$((len + 2))
        else
            len=$((len + 1))
        fi
        i=$((i + 1))
    done
    echo "$len"
}

print_box_line() {
    local content="$1"
    local align="${2:-left}"   # left | center
    local vlen
    vlen=$(visual_len "$content")
    local pad=$((BOX_WIDTH - vlen))
    [ $pad -lt 0 ] && pad=0

    if [ "$align" = "center" ]; then
        local left=$((pad / 2))
        local right=$((pad - left))
        printf "${BLUE}║${NC}%*s" $left ""
        echo -ne "$content"
        printf "%*s${BLUE}║${NC}\n" $right ""
    else
        echo -ne "${BLUE}║${NC} $content"
        printf "%*s${BLUE}║${NC}\n" $((pad - 1)) ""
    fi
}

print_box_top()    { echo -e "${BLUE}╔$(printf '%0.s═' $(seq 1 $((BOX_WIDTH + 2))))╗${NC}"; }
print_box_mid()    { echo -e "${BLUE}╠$(printf '%0.s═' $(seq 1 $((BOX_WIDTH + 2))))╣${NC}"; }
print_box_bottom() { echo -e "${BLUE}╚$(printf '%0.s═' $(seq 1 $((BOX_WIDTH + 2))))╝${NC}"; }

# ── Loading animation ─────────────────────────────────────
loading_animation() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local i=0
    local progress=0

    echo -ne "\n${CYAN}▓${NC}"
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        progress=$(( (progress + 1) % 10 ))
        echo -ne "\r${CYAN}▓${NC} ${WHITE}[${NC}"
        for ((j=0; j<10; j++)); do
            if [ $j -lt $progress ]; then
                echo -ne "${GREEN}▓${NC}"
            else
                echo -ne "${DIM}░${NC}"
            fi
        done
        echo -ne "${WHITE}] ${NC}$((progress * 10))%  ${CYAN}${spinstr:$i:1}${NC}"
        sleep $delay
    done
    echo -ne "\r${GREEN}▓${NC} ${WHITE}[${GREEN}▓▓▓▓▓▓▓▓▓▓${WHITE}] ${GREEN}100% ✓${NC}   \n"
}

progress_bar() {
    local duration=$1
    local steps=20
    local delay
    delay=$(awk -v d="$duration" -v s="$steps" 'BEGIN{printf "%.2f", d/s}')

    echo -ne "\n${CYAN}▓${NC} "
    for ((i=0; i<=steps; i++)); do
        local percent=$((i * 100 / steps))
        local filled=$((i * 50 / steps))
        local empty=$((50 - filled))

        printf "\r${CYAN}▓${NC} ${WHITE}[${GREEN}"
        printf "%${filled}s" | tr ' ' '▓'
        printf "${DIM}"
        printf "%${empty}s" | tr ' ' '░'
        printf "${WHITE}] ${NC}%3d%%" $percent
        sleep "$delay"
    done
    echo -e "\n"
}

clear

# ── Header ─────────────────────────────────────────────
show_header() {
    echo -e "${CYAN}"
    print_box_top
    print_box_line "${BOLD}${WHITE}🚀 VPS TOOLS DASHBOARD${NC} ${MAGENTA}v2.1${NC}" center
    print_box_line "${DIM}System Info & Installation Tools${NC} 🔧" center
    print_box_bottom
    echo -e "${NC}"
}

# ── Bagian bar (RAM/Disk) yang seragam ───────────────────
render_usage_bar() {
    local percent=$1
    local color=$2
    [ -z "$percent" ] && percent=0
    local filled=$((percent / 2))
    [ "$filled" -gt 50 ] && filled=50
    [ "$filled" -lt 0 ] && filled=0
    local empty=$((50 - filled))

    local bar=""
    [ "$filled" -gt 0 ] && bar=$(printf "%0.s▓" $(seq 1 $filled))
    local rest=""
    [ "$empty" -gt 0 ] && rest=$(printf "%0.s░" $(seq 1 $empty))

    echo -ne "${WHITE}[${color}${bar}${DIM}${rest}${NC}${WHITE}]${NC} ${YELLOW}${percent}%${NC}"
}

show_system_info() {
    clear
    show_header

    echo -e "${BLUE}📊 MENGUMPULKAN INFORMASI SISTEM...${NC}"
    progress_bar 2

    HOSTNAME=$(hostname)
    OS=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
    KERNEL=$(uname -r)
    CPU_CORES=$(nproc)
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    RAM_USED=$(free -h | awk '/^Mem:/ {print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    UPTIME=$(uptime -p | sed 's/up //')
    SHELL_NAME=$(echo "$SHELL")
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)

    RAM_PERCENT=$(awk '/^Mem:/ {printf "%.0f", ($3/$2)*100}' <(free))
    DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

    echo ""
    print_box_top
    print_box_line "${WHITE}📊 INFORMASI SISTEM${NC}" center
    print_box_mid
    print_box_line "${CYAN}Hostname${NC}      : ${WHITE}${HOSTNAME}${NC}"
    print_box_line "${CYAN}OS${NC}            : ${WHITE}${OS}${NC}"
    print_box_line "${CYAN}Kernel${NC}        : ${WHITE}${KERNEL}${NC}"
    print_box_line "${CYAN}Shell${NC}         : ${WHITE}${SHELL_NAME}${NC}"
    print_box_line "${CYAN}Load Average${NC}  : ${WHITE}${LOAD_AVG}${NC}"
    print_box_mid
    print_box_line "${WHITE}💾 HARDWARE INFO${NC}" center
    print_box_mid
    print_box_line "${CYAN}CPU Model${NC}     : ${WHITE}${CPU_MODEL}${NC}"
    print_box_line "${CYAN}CPU Cores${NC}     : ${WHITE}${CPU_CORES}${NC}"
    print_box_line "${CYAN}RAM${NC}           : ${WHITE}${RAM_USED} / ${RAM_TOTAL}${NC}"
    print_box_line "$(render_usage_bar "$RAM_PERCENT" "$GREEN")"
    print_box_line "${CYAN}Disk${NC}          : ${WHITE}${DISK_USED} / ${DISK_TOTAL}${NC}"
    print_box_line "$(render_usage_bar "$DISK_PERCENT" "$YELLOW")"
    print_box_mid
    print_box_line "${WHITE}⏱️  UPTIME${NC}" center
    print_box_mid
    print_box_line "${GREEN}${UPTIME}${NC}"
    print_box_bottom

    echo -e "\n${GREEN}✓ VPS Status: RUNNING OPTIMAL${NC} 🟢\n"
    read -p "Tekan ENTER untuk kembali ke menu..."
}

# ── Install Nginx ─────────────────────────────────────
install_nginx() {
    clear
    show_header
    echo -e "${CYAN}🌐 INSTALL NGINX WEB SERVER${NC}"
    echo -e "${BLUE}$(printf '%0.s━' $(seq 1 51))${NC}"
    echo ""
    echo "Nginx adalah web server yang powerful untuk hosting aplikasi"
    echo ""
    echo -e "${YELLOW}Command yang akan dijalankan:${NC}"
    echo -e "${WHITE}1/4${NC} ${CYAN}\$ sudo apt update${NC}"
    echo -e "${WHITE}2/4${NC} ${CYAN}\$ sudo apt install -y nginx${NC}"
    echo -e "${WHITE}3/4${NC} ${CYAN}\$ sudo systemctl enable --now nginx${NC}"
    echo -e "${WHITE}4/4${NC} ${CYAN}\$ sudo systemctl status nginx${NC}"
    echo ""

    read -p "Mulai instalasi? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[*] Memulai instalasi Nginx...${NC}"
        (
            set -e
            sudo apt update
            sudo apt install -y nginx
            sudo systemctl enable nginx
            sudo systemctl start nginx
        ) &
        pid=$!
        loading_animation $pid
        wait $pid
        status=$?

        echo ""
        if [ $status -ne 0 ]; then
            echo -e "${RED}[✗] Instalasi gagal! Cek pesan error di atas.${NC}"
            read -p "Tekan ENTER untuk kembali ke menu..."
            return
        fi

        echo -e "${GREEN}[✓] Instalasi selesai!${NC}"
        echo -e "${CYAN}🌐 Nginx version:${NC}"
        nginx -v
        PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me)
        echo ""
        echo -e "${GREEN}✓ Nginx berjalan di:${NC}"
        [ -n "$PUBLIC_IP" ] && echo -e "  - ${WHITE}http://${PUBLIC_IP}${NC}"
        echo -e "  - ${WHITE}http://localhost${NC}"
        echo ""
        read -p "Tekan ENTER untuk kembali ke menu..."
    fi
}

# ── Install Git & Clone ───────────────────────────────
install_git_clone() {
    clear
    show_header
    echo -e "${CYAN}📦 INSTALL GIT & CLONE REPOSITORY${NC}"
    echo -e "${BLUE}$(printf '%0.s━' $(seq 1 51))${NC}"
    echo ""

    read -p "Install Git? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        (
            set -e
            sudo apt update
            sudo apt install -y git
        ) &
        pid=$!
        loading_animation $pid
        wait $pid
        if [ $? -ne 0 ]; then
            echo -e "${RED}[✗] Gagal install Git!${NC}"
            read -p "Tekan ENTER untuk kembali..."
            return
        fi
        echo -e "${GREEN}[✓] Git installed!${NC}"
        git --version
    fi

    echo ""
    echo -e "${YELLOW}Step 2: Clone Repository${NC}"
    echo -e "  ${WHITE}1${NC}) Laravel      ${CYAN}https://github.com/laravel/laravel.git${NC}"
    echo -e "  ${WHITE}2${NC}) Express.js   ${CYAN}https://github.com/expressjs/express.git${NC}"
    echo -e "  ${WHITE}3${NC}) React App    ${CYAN}https://github.com/facebook/create-react-app.git${NC}"
    echo -e "  ${WHITE}4${NC}) Custom URL"
    echo ""

    read -p "Pilih repository (1-4): " repo_choice
    case $repo_choice in
        1) REPO_URL="https://github.com/laravel/laravel.git"; REPO_NAME="laravel" ;;
        2) REPO_URL="https://github.com/expressjs/express.git"; REPO_NAME="express" ;;
        3) REPO_URL="https://github.com/facebook/create-react-app.git"; REPO_NAME="react-app" ;;
        4)
            read -p "Masukkan URL repository: " REPO_URL
            if [ -z "$REPO_URL" ]; then
                echo -e "${RED}URL tidak boleh kosong!${NC}"
                read -p "Tekan ENTER untuk kembali..."
                return
            fi
            REPO_NAME=$(basename "$REPO_URL" .git)
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            read -p "Tekan ENTER untuk kembali..."
            return
            ;;
    esac

    echo ""
    read -p "Clone repository ${REPO_NAME}? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "$REPO_NAME" ]; then
            echo -e "${RED}[✗] Folder '${REPO_NAME}' sudah ada di direktori ini!${NC}"
            read -p "Tekan ENTER untuk kembali..."
            return
        fi
        echo -e "${GREEN}[*] Cloning ${REPO_NAME}...${NC}"
        ( set -e; git clone "$REPO_URL" ) &
        pid=$!
        loading_animation $pid
        wait $pid
        if [ $? -ne 0 ]; then
            echo -e "${RED}[✗] Clone gagal! Cek URL repository.${NC}"
            read -p "Tekan ENTER untuk kembali..."
            return
        fi
        echo ""
        echo -e "${GREEN}[✓] Repository cloned!${NC}"
        echo -e "${CYAN}📁 Lokasi: ${WHITE}$(pwd)/${REPO_NAME}${NC}"
        echo ""
        ls -la "$REPO_NAME" | head -10
        echo ""
        echo -e "${YELLOW}💡 Langkah selanjutnya:${NC}  cd ${REPO_NAME}"
        echo ""
        read -p "Tekan ENTER untuk kembali ke menu..."
    fi
}

# ── Install Node.js ───────────────────────────────────
install_nodejs() {
    clear
    show_header
    echo -e "${CYAN}⚡ INSTALL NODE.JS${NC}"
    echo -e "${BLUE}$(printf '%0.s━' $(seq 1 51))${NC}"
    echo ""
    echo -e "  ${WHITE}1${NC}) Node.js 20.x (Stable)"
    echo -e "  ${WHITE}2${NC}) Node.js 18.x (LTS)"
    echo -e "  ${WHITE}3${NC}) Node.js 16.x"
    echo ""

    read -p "Pilih versi (1-3): " version_choice
    case $version_choice in
        1) NODE_VERSION="20.x" ;;
        2) NODE_VERSION="18.x" ;;
        3) NODE_VERSION="16.x" ;;
        *) NODE_VERSION="20.x" ;;
    esac

    echo ""
    read -p "Mulai instalasi Node.js ${NODE_VERSION}? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[*] Memulai instalasi Node.js ${NODE_VERSION}...${NC}"
        (
            set -e
            curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}" | sudo -E bash -
            sudo apt-get install -y nodejs
        ) &
        pid=$!
        loading_animation $pid
        wait $pid
        if [ $? -ne 0 ]; then
            echo -e "${RED}[✗] Instalasi Node.js gagal!${NC}"
            read -p "Tekan ENTER untuk kembali..."
            return
        fi

        echo ""
        echo -e "${GREEN}[✓] Instalasi selesai!${NC}"
        echo -e "${CYAN}📦 Node:${NC} $(node --version)   ${CYAN}NPM:${NC} $(npm --version)"
        echo ""
        read -p "Install PM2 dan Nodemon? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ( set -e; sudo npm install -g pm2 nodemon ) &
            pid=$!
            loading_animation $pid
            wait $pid
            if [ $? -ne 0 ]; then
                echo -e "${RED}[✗] Gagal install global packages!${NC}"
            else
                echo -e "${GREEN}[✓] Global packages installed!${NC}"
            fi
        fi
        read -p "Tekan ENTER untuk kembali ke menu..."
    fi
}

# ── Install NVM ────────────────────────────────────────
install_nvm() {
    clear
    show_header
    echo -e "${CYAN}📦 INSTALL NVM (Node Version Manager)${NC}"
    echo -e "${BLUE}$(printf '%0.s━' $(seq 1 51))${NC}"
    echo ""

    read -p "Mulai instalasi? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[*] Memulai instalasi NVM...${NC}"
        ( set -e; curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash ) &
        pid=$!
        loading_animation $pid
        wait $pid
        if [ $? -ne 0 ]; then
            echo -e "${RED}[✗] Instalasi NVM gagal!${NC}"
            read -p "Tekan ENTER untuk kembali..."
            return
        fi
        echo ""
        echo -e "${GREEN}[✓] Instalasi NVM selesai!${NC}"
        echo -e "${YELLOW}⚠️  Buka terminal baru lalu jalankan:${NC}"
        echo -e "  nvm install --lts && nvm use --lts"
        echo ""
        read -p "Tekan ENTER untuk kembali ke menu..."
    fi
}

# ── Install Neofetch ───────────────────────────────────
install_neofetch() {
    clear
    show_header
    echo -e "${CYAN}🎨 INSTALL NEOFETCH${NC}"
    echo -e "${BLUE}$(printf '%0.s━' $(seq 1 51))${NC}"
    echo ""

    read -p "Mulai instalasi? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[*] Memulai instalasi Neofetch...${NC}"
        ( set -e; sudo apt update; sudo apt install -y neofetch ) &
        pid=$!
        loading_animation $pid
        wait $pid
        if [ $? -ne 0 ]; then
            echo -e "${RED}[✗] Instalasi Neofetch gagal!${NC}"
            read -p "Tekan ENTER untuk kembali..."
            return
        fi
        echo ""
        echo -e "${GREEN}[✓] Instalasi selesai!${NC}"
        echo ""
        neofetch
        echo ""
        read -p "Tekan ENTER untuk kembali ke menu..."
    fi
}

# ── Install Pterodactyl ────────────────────────────────
install_pterodactyl() {
    clear
    show_header
    echo -e "${CYAN}🎮 INSTALL PTERODACTYL PANEL${NC}"
    echo -e "${BLUE}$(printf '%0.s━' $(seq 1 51))${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  REQUIREMENT:${NC} PHP 8.0+, MySQL/MariaDB, Composer, Redis (opsional)"
    echo ""

    read -p "Mulai instalasi? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[*] Memulai instalasi Pterodactyl...${NC}"
        (
            set -e
            mkdir -p /var/www/pterodactyl
            cd /var/www/pterodactyl
            curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
            tar -xzvf panel.tar.gz
            chmod -R 755 storage bootstrap/cache
            cp .env.example .env
            composer install --no-dev --optimize-autoloader
            php artisan key:generate --force
        ) &
        pid=$!
        loading_animation $pid
        wait $pid
        if [ $? -ne 0 ]; then
            echo -e "${RED}[✗] Instalasi Pterodactyl gagal! Cek requirement PHP/Composer.${NC}"
            read -p "Tekan ENTER untuk kembali..."
            return
        fi

        echo ""
        read -p "Database sudah siap untuk migration? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ( set -e; cd /var/www/pterodactyl; php artisan migrate --seed --force ) &
            pid=$!
            loading_animation $pid
            wait $pid
            if [ $? -ne 0 ]; then
                echo -e "${RED}[✗] Migration gagal! Cek koneksi database.${NC}"
            else
                echo -e "${GREEN}[✓] Instalasi Pterodactyl selesai!${NC}"
            fi
        fi
        echo ""
        read -p "Tekan ENTER untuk kembali ke menu..."
    fi
}

# ── Menu utama ─────────────────────────────────────────
show_menu() {
    echo ""
    print_box_top
    print_box_line "${WHITE}📋 MAIN MENU${NC}" center
    print_box_mid
    print_box_line "${CYAN}1${NC}) 📊 Cek System Information"
    print_box_line "${CYAN}2${NC}) 🌐 Install Nginx Web Server"
    print_box_line "${CYAN}3${NC}) 📦 Install Git & Clone Repository"
    print_box_line "${CYAN}4${NC}) ⚡ Install Node.js"
    print_box_line "${CYAN}5${NC}) 📦 Install NVM"
    print_box_line "${CYAN}6${NC}) 🎮 Install Pterodactyl Panel"
    print_box_line "${CYAN}7${NC}) 🎨 Install Neofetch"
    print_box_line "${CYAN}8${NC}) 🔧 Install Multiple Tools"
    print_box_line "${RED}0${NC}) ❌ Exit"
    print_box_bottom
    echo ""
}

install_multiple() {
    clear
    show_header
    echo -e "${CYAN}🔧 INSTALL MULTIPLE TOOLS${NC}"
    echo -e "${BLUE}$(printf '%0.s━' $(seq 1 51))${NC}"
    echo ""
    echo -e "  ${CYAN}a${NC}) 🌐 Nginx"
    echo -e "  ${CYAN}b${NC}) 📦 Git"
    echo -e "  ${CYAN}c${NC}) ⚡ Node.js 20.x"
    echo -e "  ${CYAN}d${NC}) 🎨 Neofetch"
    echo -e "  ${CYAN}e${NC}) All Tools"
    echo ""

    read -p "Pilihan (a/b/c/d/e): " multi_choice
    case $multi_choice in
        a) install_nginx ;;
        b)
            ( set -e; sudo apt update; sudo apt install -y git ) &
            pid=$!
            loading_animation $pid
            wait $pid
            if [ $? -ne 0 ]; then
                echo -e "${RED}[✗] Gagal install Git!${NC}"
            else
                echo -e "${GREEN}[✓] Git installed!${NC}"
                git --version
            fi
            read -p "Tekan ENTER untuk kembali..."
            ;;
        c) install_nodejs ;;
        d) install_neofetch ;;
        e)
            echo -e "${GREEN}[*] Menginstall semua tools...${NC}"
            (
                set -e
                sudo apt update
                sudo apt install -y nginx git neofetch
                curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
                sudo apt-get install -y nodejs
            ) &
            pid=$!
            loading_animation $pid
            wait $pid
            if [ $? -ne 0 ]; then
                echo -e "${RED}[✗] Sebagian atau semua instalasi gagal! Cek pesan error di atas.${NC}"
                read -p "Tekan ENTER untuk kembali..."
                return
            fi
            echo -e "${GREEN}[✓] Semua tools terinstall!${NC}"
            echo ""
            nginx -v 2>&1
            git --version
            node --version
            npm --version
            neofetch --version
            read -p "Tekan ENTER untuk kembali..."
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 2
            ;;
    esac
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}⚠️  Script ini perlu dijalankan sebagai root untuk install tools${NC}"
        echo -e "${YELLOW}Silakan jalankan: sudo bash vps-tools.sh${NC}"
        exit 1
    fi
}

main() {
    while true; do
        clear
        show_header
        show_menu

        read -p "Pilih menu (0-8): " choice
        case $choice in
            1) show_system_info ;;
            2) install_nginx ;;
            3) install_git_clone ;;
            4) install_nodejs ;;
            5) install_nvm ;;
            6) install_pterodactyl ;;
            7) install_neofetch ;;
            8) install_multiple ;;
            0)
                echo -e "${GREEN}Terima kasih telah menggunakan VPS Tools Dashboard!${NC}"
                echo -e "${CYAN}Bye bye! 👋${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Menu tidak valid! Coba lagi.${NC}"
                sleep 2
                ;;
        esac
    done
}

check_root
main
