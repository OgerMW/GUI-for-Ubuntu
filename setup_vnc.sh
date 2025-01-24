#!/bin/bash

# Функция для выполнения команд с сокрытием вывода
execute_silent() {
  "$@" > /dev/null 2>&1
}

# Функция для вывода сообщений зеленым цветом
green_echo() {
  echo -e "\033[32m$1\033[0m"
}

# Отключаем автоматическое обновление системы
green_echo "Отключаем автоматическое обновление системы..."
execute_silent bash -c 'echo "APT::Periodic::Unattended-Upgrade \"0\";" >> /etc/apt/apt.conf.d/99needrestart'
execute_silent bash -c 'echo "APT::Periodic::Unattended-Upgrade \"0\";" >> /etc/apt/apt.conf.d/10periodic'

# Проверяем наличие sudo и устанавливаем его, если необходимо
if ! command -v sudo &>/dev/null; then
  green_echo "Устанавливаем sudo..."
  execute_silent apt-get update
  execute_silent apt-get install -y sudo
else
  green_echo "Sudo уже установлен."
fi

# Обновляем систему и устанавливаем необходимые пакеты
green_echo "Обновляем систему и устанавливаем необходимые пакеты..."
execute_silent sudo apt-get update
execute_silent sudo apt-get upgrade -y
execute_silent sudo apt-get install -y xfce4 xfce4-goodies tightvncserver autocutsel

# Запрашиваем пароль для пользователя vnc
read -sp 'Введите пароль для пользователя "vnc": ' vnc_password
echo

# Создание пользователя VNC
green_echo "Создаем пользователя VNC..."
execute_silent sudo adduser --disabled-password --gecos "" vnc
echo "vnc:$vnc_password" | chpasswd
execute_silent sudo usermod -aG sudo vnc

# Настройка VNC сервера для пользователя vnc
green_echo "Настраиваем VNC сервер для пользователя vnc..."
su - vnc <<EOF
vncpasswd
mkdir -p ~/.vnc
cat <<'VNCSTARTUP' > ~/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
autocutsel -fork
startxfce4 &
VNCSTARTUP
chmod +x ~/.vnc/xstartup
exit
EOF

# Создание системного сервиса для автоматического запуска VNC сервера
green_echo "Создаем системный сервис для автоматического запуска VNC сервера..."
sudo bash -c 'cat <<VNCSYSTEMD > /etc/systemd/system/vncserver@.service
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
VNCSYSTEMD'

# Активируем сервис и перезагружаем систему
green_echo "Активируем сервис и запускаем VNC сервер..."
execute_silent sudo systemctl daemon-reload
execute_silent sudo systemctl enable vncserver@1
execute_silent sudo systemctl start vncserver@1
# sudo reboot # Комментарий о необходимости перезагрузки системы

green_echo "GUI и VNC установлены успешно. Чтобы подключиться, используйте IP-адрес вашего сервера и порт 5901."
