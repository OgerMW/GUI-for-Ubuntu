#!/bin/bash
# Функция для вывода текста зеленым цветом
print_green() {
    echo -e "\e[32m$1\e[0m"
}

# Функция для проверки успешности выполнения команды
check_success() {
    if [ $? -ne 0 ]; then
        print_green "Ошибка при выполнении команды!"
        exit 1
    fi
}

# Функция для отображения анимации
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    tput civis
    while ps -p $pid > /dev/null; do
        for i in $(seq 0 3); do
            printf "\r [%c] " "${spinstr:$i:1}"
            sleep $delay
        done
    done
    tput cnorm
    printf "\r      \r"
}

# Перенаправление вывода в файл логов
exec > >(tee -i install.log)
exec 2>&1

# Проверка прав администратора
if [ "$EUID" -ne 0 ]; then
    print_green "Этот скрипт нужно запускать с правами администратора (sudo)."
    exit 1
fi

# Меню выбора версии скрипта
print_green "Выберите версию скрипта:"
print_green "1) Полностью автоматическая установка"
print_green "2) Ручная установка"
read -p "Введите номер варианта: " choice

# Установка пароля по умолчанию или запрос пользователя в зависимости от выбора
if [ "$choice" == "1" ]; then
    VNC_PASSWORD="172029"
elif [ "$choice" == "2" ]; then
    read -s -p "Введите пароль для пользователя vnc: " VNC_PASSWORD
else
    print_green "Неверный выбор. Завершение работы скрипта."
    exit 1
fi

# Отключаем автоматическое обновление системы
print_green "Отключаем вывод запроса о необходимости перезапуска системных служб..."
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/99needrestart > /dev/null
check_success
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/10periodic > /dev/null 
check_success

# Установка необходимых пакетов и обновление системы
print_green "Устанавливаем обновления системы..."
apt update > /dev/null 2>&1 &
spinner $!
wait $!
check_success

apt upgrade -y > /dev/null 2>&1 &
spinner $!
wait $!
check_success

print_green "Устанавливаем дополнительные компоненты..."
apt install -y xfce4 xfce4-goodies tightvncserver autocutsel expect > /dev/null 2>&1 &
spinner $!
wait $!
check_success

# Добавление репозитория Google Chrome
print_green "Добавляем репозиторий Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - > /dev/null 2>&1
check_success

echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null 2>&1
check_success

# Обновление списка пакетов после добавления нового репозитория
print_green "Обновляем список пакетов..."
apt update > /dev/null 2>&1 &
spinner $!
wait $!
check_success

# Установка Google Chrome
print_green "Устанавливаем Google Chrome..."
apt install google-chrome-stable -y > /dev/null 2>&1 &
spinner $!
wait $!
check_success

# Выбор варианта для x-terminal-emulator
print_green "Заменяем Terminal Emulator..."
sudo update-alternatives --config x-terminal-emulator <<< "2" > /dev/null 2>&1
check_success

# Создание пользователя vnc и настройка прав
print_green "Создаём пользователя vnc..."
useradd -m -s /bin/bash vnc > /dev/null 2>&1
check_success

usermod -aG sudo vnc > /dev/null 2>&1
check_success

# Установка пароля для пользователя vnc
print_green "Устанавливаем пароль для пользователя vnc..."
echo -e "$VNC_PASSWORD\n$VNC_PASSWORD" | sudo passwd vnc > /dev/null 2>&1
check_success

# Настройка VNC
print_green "Настраиваем VNC-сервер..."
sudo -u vnc expect <<EOS > /dev/null 2>&1
spawn vncpasswd
expect "Password:"
send "$VNC_PASSWORD\r"
expect "Verify:"
send "$VNC_PASSWORD\r"
expect "Would you like to enter a view-only password (y/n)?"
send "n\r"
expect eof
EOS
check_success

# Создание и настройка файла xstartup
sudo -u vnc cat <<EOL > /home/vnc/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
autocutsel -fork
startxfce4 &
EOL
sudo chmod 755 /home/vnc/.vnc/xstartup
check_success

# Создание и настройка systemd-юнита для VNC
print_green "Настраиваем systemd-юнит для VNC..."
sudo bash -c 'cat <<EOL > /etc/systemd/system/vncserver@.service
[Unit]
Description=Start VNC server at startup
After=syslog.target network.target
[Service]
Type=forking
User=vnc
Group=vnc
WorkingDirectory=/home/vnc
PIDFile=/home/vnc/.vnc/%H%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080 :%i
ExecStop=/usr/bin/vncserver -kill :%i
[Install]
WantedBy=multi-user.target
EOL'
check_success

# Включение и запуск службы VNC
print_green "Включаем и запускаем службы VNC..."
sudo systemctl enable vncserver@1 > /dev/null 2>&1
check_success

sudo systemctl start vncserver@1 > /dev/null 2>&1
check_success

# Завершение установки
print_green "Установка завершена. Теперь вы можете подключиться по протоколу VNC к вашему серверу, используя выданный вам IP и Port 5901."
print_green "Пароль пользователя vnc - ${VNC_PASSWORD}. Пароль для входа по VNC - ${VNC_PASSWORD}."
print_green "Данные пароли созданы автоматически, вы можете изменить их, следуя инструкции на странице скрипта на GitHub"
