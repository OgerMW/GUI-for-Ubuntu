#!/bin/bash

# Имя пользователя и номер дисплея VNC
VNC_USER="vnc"
DISPLAY_NUMBER="1"
LOG_FILE="/var/log/vnc_setup.log"  # Путь к файлу лога

# Функция для записи в лог-файл
log_message() {
    local message="\$1"
    echo "$message" >> "$LOG_FILE"
}

# Функция для вывода сообщений по центру экрана
center_text() {
    local text="\$1"
    local cols=$(tput cols)
    local length=${#text}
    local padding=$(( (cols - length) / 2 ))
    printf "%${padding}s\n" "$text"
}

# Функция для вывода сообщений зеленым цветом
green_text() {
    tput bold # Включаем жирный шрифт
    tput setaf 2 # Устанавливаем зеленый цвет
    center_text "\$1"
    tput sgr0 # Сбрасываем настройки формата
}

# Функция анимации
show_loading() {
    local pid="\$1"
    local delay=0.75
    local spin='/-\|'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${spin:i++%${#spin}:1} "
        sleep "$delay"
    done
    printf "\r"  # Очистить строку после завершения
}

# Начало установки
green_text "Начинаем установку. Все операции займут около 5-7 минут."
log_message "Начинаем установку. Все операции займут около 5-7 минут."
echo "Unattended-Upgrade::Automatic-Reboot \"false\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "Unattended-Upgrade::Automatic-Reboot-WithUsers \"false\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "APT::Periodic::Unattended-Upgrade \"0\";" | sudo tee -a /etc/apt/apt.conf.d/99needrestart
echo "APT::Periodic::Unattended-Upgrade \"0\";" | sudo tee -a /etc/apt/apt.conf.d/10periodic &>> "$LOG_FILE" &
show_loading $!

# Установка необходимых пакетов
green_text "Установка необходимых пакетов"
log_message "Установка необходимых пакетов"
{
    sudo apt-get update -qq && sudo apt-get upgrade -y -q
    sudo apt-get install -y -q xfce4 xfce4-goodies tightvncserver autocutsel expect
} &>> "$LOG_FILE" &
show_loading $!

# Создаем пользователя vnc
green_text "Создаем пользователя vnc. Устанавливаем User - vnc / Устанавливаем Password - 172029"
log_message "Создаем пользователя vnc"
{
    sudo useradd -m -s /bin/bash "${VNC_USER}"
    sudo usermod -aG sudo "${VNC_USER}"
    echo "${VNC_USER}:172029" | sudo chpasswd
} &>> "$LOG_FILE" &
show_loading $!

# Настраиваем VNC
green_text "Настраиваем VNC. Устанавливаем Password - 172029"
log_message "Настраиваем VNC"
LANG=en_US.UTF-8 expect -c "
    spawn sudo -u ${VNC_USER} vncpasswd;
    expect \"Enter new UNIX password:\";
    send \"172029\r\";
    expect \"Retype new UNIX password:\";
    send \"172029\r\";
    expect \"Would you like to enter a view-only password (y/n)?\";
    send \"n\r\";
    interact
" &>> "$LOG_FILE" &
show_loading $!

# Создание файла xstartup
green_text "Создание файла xstartup"
log_message "Создание файла xstartup"
sudo -u "${VNC_USER}" bash -c 'cat << EOF > ~/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
autocutsel -fork
startxfce4 &
EOF' &>> "$LOG_FILE" &
show_loading $!
sudo -u "${VNC_USER}" chmod +x ~/.vnc/xstartup &>> "$LOG_FILE" &
show_loading $!

# Создание systemd сервиса для VNC
green_text "Создание systemd сервиса для VNC"
cat << EOF | sudo tee /etc/systemd/system/vncserver@.service
[Unit]
Description=Start VNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User =${VNC_USER}
Group=${VNC_USER}
WorkingDirectory=/home/${VNC_USER}

PIDFile=/home/${VNC_USER}/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

# Включение и запуск VNC сервиса
green_text "Включение и запуск VNC сервиса"
log_message "Включение и запуск VNC сервиса"
{
    sudo systemctl daemon-reload
    sudo systemctl enable vncserver@${DISPLAY_NUMBER}
    sudo systemctl start vncserver@${DISPLAY_NUMBER}
} &>> "$LOG_FILE" &
show_loading $!

# Проверяем статус службы
green_text "Проверка статуса службы VNC"
log_message "Проверка статуса службы VNC"
sudo systemctl status vncserver@${DISPLAY_NUMBER} &>> "$LOG_FILE" &
show_loading $!

# Предложение о перезагрузке
green_text "Настройка VNC сервера завершена. Вы можете подключиться к серверу. Для завершения настроек рекомендуется перезагрузить систему. Выполнить перезагрузку сейчас? (Y/N)"
log_message "Настройка VNC сервера завершена. Вы можете подключиться к серверу. Для завершения настроек рекомендуется перезагрузить систему. Выполнить перезагрузку сейчас?"
read -p "" answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    log_message "Выполняется перезагрузка..."
    sudo reboot
else
    green_text "Перезагрузка отменена. Завершайте работу системы вручную."
    log_message "Перезагрузка отменена. Работа системы продолжается."
fi
