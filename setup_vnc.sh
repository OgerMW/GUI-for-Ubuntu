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

# Проверка прав администратора
if [ "$EUID" -ne 0 ]; then
    print_green "Этот скрипт нужно запускать с правами администратора (sudo)."
    exit 1
fi

# Запись логов в файл
log_file="install.log"
echo "Запуск скрипта..." >> "$log_file"

# Меню выбора версии скрипта
PS3="Выберите версию скрипта: "
options=("Полностью автоматическая установка" "Ручная установка")

select opt in "${options[@]}"; do
    case $opt in
        "Полностью автоматическая установка")
            VNC_PASSWORD="172029"
            echo "Выбранная версия: полностью автоматическая установка." >> "$log_file"
            break
            ;;
        "Ручная установка")
            read -s -p "Введите пароль для пользователя vnc: " VNC_PASSWORD
            echo  # Для новой строки после ввода пароля
            echo "Выбранная версия: ручная установка." >> "$log_file"
            break
            ;;
        *) 
            print_green "Неверный выбор. Пожалуйста, попробуйте снова."
            echo "Пользователь ввел неверный вариант: '$REPLY'." >> "$log_file"
            ;;
    esac
done
