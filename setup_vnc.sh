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
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/99needrestart > /dev/null &
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/10periodic > /dev/null & 

# Установка необходимых пакетов и обновление системы
print_green "Установка sudo и обновление системы..."
apt install sudo -y > /dev/null 2>&1 &
spinner $!
sudo apt update > /dev/null 2>&1 &
spinner $!
sudo apt upgrade -y > /dev/null 2>&1 &
spinner $!

print_green "Установка дополнительных компонентов..."
sudo apt install -y xfce4 xfce4-goodies tightvncserver autocutsel expect > /dev/null 2>&1 &
spinner $!

# Создание пользователя vnc и настройка прав
print_green "Создание пользователя vnc..."
useradd -m -s /bin/bash vnc > /dev/null 2>&1 &
spinner $!
usermod -aG sudo vnc > /dev/null 2>&1 &
spinner $!

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
sudo -u vnc cat <<EOL > /home/vnc/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
autocutsel -fork
startxfce4 &
EOL
sudo chmod 755 /home/vnc/.vnc/xstartup

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
sudo systemctl enable vncserver@1 > /dev/null 2>&1 &
spinner $!
sudo systemctl start vncserver@1 > /dev/null 2>&1 &
spinner $!

# Завершение установки
print_green "Установка завершена. Теперь вы можете подключиться по протоколу VNC к вашему серверу, используя выданный вам IP и Port 5901."
print_green "Пароль пользователя vnc - 172029. Пароль для входа по VNC - 172029."
print_green "Данные пароли созданы автоматически, вы можете изменить их, следуя инструкции на странице скрипта на GitHub"
