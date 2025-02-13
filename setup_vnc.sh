channel_logo() {  
  echo -e '\033[0;31m'
  echo -e '   **                                                                                              
  echo -e '   **                       ****      ***      ****  *****                   **    **  ***        ***'
  echo -e '   **                     **   *    **  **   ***  * **    **                ***   ***  * **        **'
  echo -e '   *                     **    **  **   **  **    *   *   **               * **  * *     **   **   **'
  echo -e '  **                     **    ** **    **  **  ***  **   **              * **  ****    **   **    **'
  echo -e '  *****   **   **       **     ** **    **  **  **   **   **             ** **  * **    **  ***    **'
  echo -e '  **  **  **   **       *      * **         **       *   **              *  ** *  *    **  ***     * '
  echo -e ' ***  **  **  **       **     ** **          ***    ******              **  *  * **    ** ****    ** '
  echo -e ' **   **  *   **       **     ** **  ****   **      ****                *  ** *  **   **  * **    ** '
  echo -e ' *    *  **  ***       **    **  **   ***  **      **  **              **  ** *  **   ** *  **   **  '                                                 
  echo -e ' *   **  ** * *        **   **   **   *    **   *  **  **             **   ***   *    ** *  **   *   '                                                 
  echo -e ' *  **  ** * **        **  **    **  **    **  ** **    **            *    ***   *    ***   **  *    '                                                 
  echo -e ' ****    **  *          ****      ****      ****  *      ***        ***    **    ***   *     ***     '                                                 
  echo -e '            **                                              ********                                 '
  echo -e '            **                                                                                       '                     
  echo -e '           **                                                                                        '
  echo -e '          **                                                                                         '
  echo -e '\e[0m'
}

# Функция для вывода текста зеленым цветом
print_green() {
echo -e "\e[32m$1\e[0m"
}

# Функция для вывода текста красным цветом (для сообщений об ошибках)
print_red() {
echo -e "\e[31m$1\e[0m"
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

# Функция для записи логов
log() {
echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

# Проверка прав администратора
if [ "$EUID" -ne 0 ]; then
print_red "Этот скрипт нужно запускать с правами администратора (sudo)."
log "Скрипт запущен без прав администратора."
exit 1
fi

# Запись логов в файл
log_file="install.log"
echo "Запуск скрипта..." >> "$log_file"
log "Начало работы скрипта"

# Функция для выхода из скрипта
exit_from_script() {
log "Завершение работы скрипта"
exit 0
}

# Функция для автоматической установки
auto_setup() {
print_green "Автоматическая установка началась..."
log "Начало автоматической установки"

# Отключаем автоматическое обновление системы
print_green "Отключаем вывод запроса о необходимости перезапуска системных служб..."
log "Отключение автоматического обновления системы"
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/99needrestart > /dev/null &
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/10periodic > /dev/null & 
wait

# Устанавливаем необходимые пакеты и обновления системы
print_green "Устанавливаем обновления системы..."
log "Установка обновлений системы"
apt install sudo -y > /dev/null 2>&1 &
spinner $!
wait $!
    
sudo apt update > /dev/null 2>&1 &
spinner $!
wait $!
    
sudo apt upgrade -y > /dev/null 2>&1 &
spinner $!
wait $!
    
print_green "Устанавливаем дополнительные компоненты..."
log "Установка дополнительных компонентов"
sudo apt install -y xfce4 xfce4-goodies tightvncserver autocutsel expect > /dev/null 2>&1 &
spinner $!
wait $!
    
# Добавление репозитория Google Chrome
print_green "Добавляем репозиторий Google Chrome..."
log "Добавление репозитория Google Chrome"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - > /dev/null 2>&1 &
spinner $!
wait $!
    
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null 2>&1 &
spinner $!
wait $!
    
# Обновление списка пакетов после добавления нового репозитория
print_green "Обновляем список пакетов..."
log "Обновление списка пакетов"
sudo apt update > /dev/null 2>&1 &
spinner $!
wait $!
    
# Установка Google Chrome
print_green "Устанавливаем Google Chrome..."
log "Установка Google Chrome"
sudo apt install google-chrome-stable -y > /dev/null 2>&1 &
spinner $!
wait $!
    
# Выбор варианта для x-terminal-emulator
print_green "Заменяем Terminal Emulator..."
log "Замена Terminal Emulator"
sudo update-alternatives --config x-terminal-emulator <<< "2" > /dev/null 2>&1 &
spinner $!
wait $!
    
# Создание пользователя vnc и настройка прав
print_green "Создаём пользователя vnc..."
log "Создание пользователя vnc"
useradd -m -s /bin/bash vnc > /dev/null 2>&1 &
spinner $!
wait $!
    
usermod -aG sudo vnc > /dev/null 2>&1 &
spinner $!
wait $!
    
# Установка пароля для пользователя vnc
print_green "Устанавливаем пароль для пользователя vnc..."
log "Установка пароля для пользователя vnc"
echo -e "172029\n172029" | sudo passwd vnc > /dev/null 2>&1 &
spinner $!
wait $!
    
# Настройка VNC
print_green "Настраиваем VNC-сервер..."
log "Настройка VNC-сервера"
sudo -u vnc expect <<EOS > /dev/null 2>&1
spawn vncpasswd
expect "Password:"
send "172029\r"
expect "Verify:"
send "172029\r"
expect "Would you like to enter a view-only password (y/n)?"
send "n\r"
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

PIDFile=/home/vnc/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOL'

# Включение и запуск службы VNC
print_green "Включаем и запускаем службы VNC..."
sudo systemctl enable vncserver@1 > /dev/null 2>&1 &
spinner $!
wait $!
sudo systemctl start vncserver@1 > /dev/null 2>&1 &
spinner $!
wait $!
    
# Завершение установки
print_green "Установка завершена. Теперь вы можете подключиться по протоколу VNC к вашему серверу, используя выданный вам IP и Port 5901."
print_red "Пароль пользователя vnc - 172029. Пароль для входа по VNC - 172029."
print_green "Данные пароли созданы автоматически, вы можете изменить их, следуя инструкции на странице скрипта на GitHub"
log "Автоматическая установка завершена"

# Выход из цикла и завершение работы скрипта
exit_from_script

}

# Функция для ручной установки
manual_setup() {
print_green "Ручная установка началась..."
log "Начало ручной установки"

# Отключаем автоматическое обновление системы
print_green "Отключаем вывод запроса о необходимости перезапуска системных служб..."
log "Отключение автоматического обновления системы"
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/99needrestart > /dev/null
echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/10periodic > /dev/null 
    
# Установка необходимых пакетов и обновление системы
print_green "Устанавливаем обновления системы..."
log "Установка обновлений системы"
apt update > /dev/null 2>&1 &
spinner $!
wait $!
    
apt upgrade -y > /dev/null 2>&1 &
spinner $!
wait $!
    
print_green "Устанавливаем дополнительные компоненты..."
log "Установка дополнительных компонентов"
apt install -y xfce4 xfce4-goodies tightvncserver autocutsel expect > /dev/null 2>&1 &
spinner $!
wait $!
    
# Добавление репозитория Google Chrome
print_green "Добавляем репозиторий Google Chrome..."
log "Добавление репозитория Google Chrome"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - > /dev/null 2>&1
    
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null 2>&1
    
# Обновление списка пакетов после добавления нового репозитория
print_green "Обновляем список пакетов..."
log "Обновление списка пакетов"
apt update > /dev/null 2>&1 &
spinner $!
wait $!
    
# Установка Google Chrome
print_green "Устанавливаем Google Chrome..."
log "Установка Google Chrome"
apt install google-chrome-stable -y > /dev/null 2>&1 &
spinner $!
wait $!
    
# Выбор варианта для x-terminal-emulator
print_green "Заменяем Terminal Emulator..."
log "Замена Terminal Emulator"
sudo update-alternatives --config x-terminal-emulator <<< "2" > /dev/null 2>&1
    
# Создание пользователя vnc и настройка прав
print_green "Создаём пользователя vnc..."
log "Создание пользователя vnc"
useradd -m -s /bin/bash vnc > /dev/null 2>&1
usermod -aG sudo vnc > /dev/null 2>&1
    
# Установка пароля для пользователя vnc
print_green "Устанавливаем пароль для пользователя vnc..."
log "Установка пароля для пользователя vnc"

# Инициализация флагов для управления циклом
password_matched=false

# Цикл для многократного ввода пароля до тех пор, пока пароли не совпадут
until $password_matched; do
read -sp "Введите пароль для пользователя vnc: " VNC_PASSWORD
echo ""
read -sp "Введите пароль еще раз для подтверждения: " VNC_PASSWORD_CONFIRM
echo ""

# Проверка совпадения паролей
if [ "$VNC_PASSWORD" = "$VNC_PASSWORD_CONFIRM" ]; then
password_matched=true
echo -e "$VNC_PASSWORD\n$VNC_PASSWORD" | sudo passwd vnc > /dev/null 2>&1
else
print_red "Пароли не совпадают. Пожалуйста, попробуйте еще раз."
log "Пароли не совпадают. Попытка ввода снова."
fi
done

# Настройка VNC
print_green "Настраиваем VNC-сервер..."
log "Настройка VNC-сервера"
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
    
# Создание и настройка файла xstartup
sudo -u vnc cat <<EOL > /home/vnc/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
autocutsel -fork
startxfce4 &
EOL
sudo chmod 755 /home/vnc/.vnc/xstartup
    
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

PIDFile=/home/vnc/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOL'

# Включение и запуск службы VNC
print_green "Включаем и запускаем службы VNC..."
sudo systemctl enable vncserver@1 > /dev/null 2>&1 &
spinner $!
wait $!
sudo systemctl start vncserver@1 > /dev/null 2>&1 &
spinner $!
wait $!
    
# Завершение установки
print_green "Установка завершена. Теперь вы можете подключиться по протоколу VNC к вашему серверу, используя выданный вам IP и Port 5901."
print_red "Пароль пользователя vnc - ${VNC_PASSWORD}. Пароль для входа по VNC - ${VNC_PASSWORD}."
log "Ручная установка завершена"

# Выход из цикла и завершение работы скрипта
exit_from_script

}

# Меню выбора версии скрипта
while true; do
channel_logo
sleep 2
echo -e "\n\nВыберите вариант установки:"
print_green "1. Полностью автоматическая установка"
print_green "2. Ручная установка с возможностью ввода паролей"
print_green "3. Выйти из скрипта\n"
read -p "Выберите пункт меню: " choice
case $choice in
1)
auto_setup
;;
2)
manual_setup
;;
3)
exit_from_script
;;
*)
print_red "Такого пункта нет. Пожалуйста, выберите правильную цифру в меню."
log "Неверный пункт меню выбран пользователем"
;;
esac
done
