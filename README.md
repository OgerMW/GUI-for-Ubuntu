1. Заходим на сервер.
2. Проверяем и включаем нужные локализации.
3. Вводим sudo dpkg-reconfigure locales
4. Выбираем (пробелом) все локализации en_US (3шт) и ru_RU (3шт.). Жмем ОК.
5. По умолчанию, оставляем en_US.
6. Выполняем команду sudo apt install wget
7. Выполняем команду wget -qO- https://raw.githubusercontent.com/ogermw/GUI-for-Ubuntu/master/setup_vnc.sh | bash -
