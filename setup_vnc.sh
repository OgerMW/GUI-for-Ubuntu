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
print_green "Выберите версию скрипта:"
print_green "1) Полностью автоматическая установка"
print_green "2) Ручная установка"

while true; do
    read -p "Введите номер варианта: " choice
    
    # Проверяем, введен ли какой-то символ
    if [[ -z "$choice" ]]; then
        continue
    fi
    
    case $choice in
        1)
            VNC_PASSWORD="172029"
            echo "Выбранная версия: полностью автоматическая установка." >> "$log_file"
            break
            ;;
        2)
            read -s -p "Введите пароль для пользователя vnc: " VNC_PASSWORD
            echo  # Для новой строки после ввода пароля
            echo "Выбранная версия: ручная установка." >> "$log_file"
            break
            ;;
        *)
            print_green "Неверный выбор. Пожалуйста, попробуйте снова."
            echo "Пользователь ввел неверный вариант: '$choice'." >> "$log_file"
            ;;
    esac
done

# Завершение работы со скриптом
echo "Скрипт завершен." >> "$log_file"
