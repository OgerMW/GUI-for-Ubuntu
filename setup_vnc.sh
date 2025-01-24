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

# Создание пользователя vnc и настройка прав
print_green "Создание пользователя vnc..."
useradd -m -s /bin/bash vnc > /dev/null 2>&1 &
spinner $!
usermod -aG sudo vnc > /dev/null 2>&1 &
spinner $!

# Установка пароля для пользователя vnc
print_green "Установите пароль для пользователя vnc:"
echo -e "172029\n172029" | passwd vnc

# Переключение на пользователя vnc и настройка VNC
print_green "Настройка VNC-сервера..."
su - vnc <<'EOF' > /dev/null 2>&1 &
print_green "Установите пароль для подключения по VNC:"

# Используем expect для автоматизации ввода пароля
expect <<EOS
spawn vncpasswd
expect "Password:"
send "172029\r"
expect "Verify:"
send "172029\r"
expect eof
EOS

# Создание и настройка файла xstartup
cat <<EOL > ~/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
autocutsel -fork
startxfce4 &
EOL

chmod 755 ~/.vnc/xstartup
EOF
spinner $!

# Перезагрузка системы
print_green "Настройка завершена. Хотите перезагрузить систему? (Y/n)"
# Открываем терминал для ввода
exec < /dev/tty
read -r answer  # Чтение ответа из терминала
# Приводим ответ к нижнему регистру
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
case $answer in
    y|yes)
        print_green "Система будет перезагружена..."
        sudo reboot
        ;;
    n|no)
        print_green "Перезагрузка отменена. Завершение работы скрипта."
        exit 0
        ;;
    *)
        print_green "Неверный ввод. Перезагрузка отменена. Завершение работы скрипта."
        exit 1
        ;;
esac
