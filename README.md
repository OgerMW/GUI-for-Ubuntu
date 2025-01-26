1. Заходим на сервер.
2. Если у вас не отображается кириллица, для удобства, проверяем и включаем нужные локализации.
3. Вводим sudo dpkg-reconfigure locales
4. Выбираем (пробелом) все локализации en_US (3шт) и ru_RU (3шт.). Жмем ОК.
5. По умолчанию, оставляем en_US.
6. Если команда wget не установлена на вашем сервере, выполняем команду sudo apt install wget
7. Выполняем команду wget -qO- https://raw.githubusercontent.com/ogermw/GUI-for-Ubuntu/master/setup_vnc.sh | bash -
8. Установка происходит в полностью автоматическом режиме. Так же, на ваш сервер будет установлена последняя версия браузера Google Chrome. Ждём окончания установки скрипта. Пароль для пользователя vnc и пароль для подключения сеанса VNC - 172029.
9. Если во время выполнения скрипта, у вас все таки система будет выдавать сообщение о необходимости перезапуска некоторых компонентов, то нужно выбирать цифру, соответствующую значению NONE (никакие) или (в зависимости от вашей виртуализации), выбрать Cancel (Tab и стрелка вправо) и нажать Enter.
10. Чтобы изменить пароли, созданные во время установки, вводим в терминале команды:
11. vncpasswd - вводим старый пароль (из п.8) и меняем пароль для подключения сеанса VNC (выполнять ТОЛЬКО!!! под пользователем vnc, чтобы перейти на пользователя vnc, вводим su - vnc)
12. passwd vnc - вводим старый пароль (из п.8) и меняем пароль для пользователя vnc (можно выполнять под любым пользователем)
13. После установки, настоятельно рекомендуется добавить исключения в ваши Iptables, чтобы боты, атакующие ваш сервер, не уводили ваш рабочий стол в режим блокировки.
14. Вписываем команды:
15. iptables -I INPUT -p tcp -s ваш_ip_adress --dport 5901 -j ACCEPT  (заходим на 2ip.ru, смотрим свой адрес, меняем в строке на ваш)
16. iptables -A INPUT -p tcp -s 0.0.0.0/0 --dport 5901 -j DROP  (тут ничего не меняем, вводим прямо так, эта команда блокирует подключения со всех IP, кроме вашего)
17. Чтобы правила, внесенные в Iptables, сохранялись после перезагрузки сервера, введите команду sudo apt-get install iptables-persistent -y , на запрос сохранить ли внесенные в Iptables изменения для IpV4 и IpV6, нажмите Yes (для каждого запроса).
