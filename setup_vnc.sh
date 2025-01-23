#!/bin/bash

# Функция для вывода сообщений по центру экрана
center_text() {
    local text="$1"
    local cols=$(tput cols)
    local length=${#text}
    local padding=$(( ($cols - $length) / 2 ))
    printf "%${padding}s\n" "$text"
}

# Функция для вывода сообщений зеленым цветом
green_text() {
    tput bold # Включаем жирный шрифт
    tput setaf 2 # Устанавливаем зеленый цвет
    center_text "$1"
    tput sgr0 # Сбрасываем настройки формата
}

# Отключаем уведомления через конфигурацию APT
green_text "Отключаем уведомления через конфигурацию APT"
echo "Unattended-Upgrade::Automatic-Reboot \"false\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "Unattended-Upgrade::Automatic-Reboot-WithUsers \"false\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades

# Установка необходимых пакетов
green_text "Установка необходимых пакетов"
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y xfce4 xfce4-goodies tightvncserver autocutsel expect

# Создаем пользователя vnc
green_text "Создаем пользователя vnc"
sudo useradd -m -s /bin/bash vnc
sudo usermod -aG sudo vnc
echo "vnc:172029" | sudo chpasswd vnc

# Настраиваем VNC
green_text "Настраиваем VNC"
LANG=en_US.UTF-8 expect -c '
    spawn su - vnc -c vncpasswd;
    expect "Enter new UNIX password:";
    send "172029\r";
    expect "Retype new UNIX password:";
    send "172029\r";
    expect "Would you like to enter a view-only password (y/n)?";
    send "n\r";
    interact
'

# Создание файла xstartup
green_text "Создание файла xstartup"
su - vnc -c 'cat << EOF > ~/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
autocutsel -fork
startxfce4 &
EOF'

su - vnc -c 'chmod +x ~/.vnc/xstartup'

# Создание systemd сервиса для VNC
green_text "Создание systemd сервиса для VNC"
cat << EOF | sudo tee /etc/systemd/system/vncserver@.service
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
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080  :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

# Включение и запуск VNC сервиса
green_text "Включение и запуск VNC сервиса"
sudo systemctl daemon-reload
sudo systemctl enable vncserver@1
sudo systemctl start vncserver@1

# Перезагружаемся?
green_text "Настройка VNC сервера завершена. Вы можете подключиться к серверу. Для завершения настроек рекомендуется перезагрузить систему. Выполнить перезагрузку сейчас? (Y/N)"
read -p "" answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    green_text "Перезагрузка отменена. Завершайте работу системы вручную."
fi