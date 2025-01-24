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
