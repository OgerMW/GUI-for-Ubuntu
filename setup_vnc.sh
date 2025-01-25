#!/bin/bash

# Функция для вывода текста зеленым цветом
print_green() {
    echo -e "\e[32m$1\e[0m"
}

# Функция для отображения анимации
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    # Скрываем курсор
    tput civis
    while ps -p $pid > /dev/null; do
        for i in $(seq 0 3); do
            printf "\r [%c] " "${spinstr:$i:1}"
            sleep $delay
        done
    done
    # Восстанавливаем курсор
    tput cnorm
    printf "\r      \r"  # Очищаем строку с анимацией
}

# Отключаем автоматическое обновление системы
print_green "Отключаем вывод запроса о необходимости перезапуска системных служб..."
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/99needrestart > /dev/null &&
spinner $!
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/10periodic > /dev/null &&
spinner $!

# Установка необходимых пакетов и обновление системы
print_green "Установка обновлений системы..."
sudo apt-get update && spinner $!
sudo apt-get install -y sudo && spinner $!
sudo apt-get upgrade -y && spinner $!

print_green "Установка дополнительных компонентов..."
sudo apt-get install -y xfce4 xfce4-goodies tightvncserver autocutsel && spinner $!

# Создание пользователя vnc и настройка прав
print_green "Создание пользователя vnc..."
sudo useradd -m -s /bin/bash vnc && spinner $!
sudo usermod -aG sudo vnc && spinner $!

# Установка пароля для пользователя vnc
print_green "Установите пароль для пользователя vnc:"
echo -e "172029\n172029" | sudo passwd vnc

# Настройка VNC
print_green "Настройка VNC-сервера..."
sudo -u vnc expect <<EOS
spawn vncpasswd
expect "Password:"
send "172029\r"
expect "Verify:"
send "172029\r"
expect eof
EOS

# Создание и настройка файла xstartup
sudo -u vnc cat <<EOL > ~/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
autocutsel -fork
startxfce4 &
EOL
sudo chmod 755 ~/.vnc/xstartup

# Создание и настройка systemd-юнита для VNC
print_green "Настройка systemd-юнита для VNC..."
sudo bash -c 'cat <<EOL > /etc/systemd/system/vncserver@.service
[Unit]
Description=Start VNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=vnc
Group=vnc
WorkingDirectory=/home/vnc

PIDFile=/home/vnc/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOL'

# Включение и запуск службы VNC
print_green "Включение и запуск службы VNC..."
sudo systemctl enable vncserver@1 && spinner $!
sudo systemctl start vncserver@1 && spinner $!

# Завершение установки
print_green "Установка завершена. Теперь вы можете подключиться по протоколу VNC к вашему серверу, используя выданный вам IP и Port 5901."
print_green "Пароль пользователя vnc - 172029. Пароль для входа по VNC - 172029."
print_green "Данные пароли созданы автоматически, вы можете изменить их, следуя инструкции на странице скрипта на GitHub"
