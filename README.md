RU
1. Заходим на сервер.
2. Переключаемся на пользователя root командой sudo su
3. Пункты 3, 4, 5, 6 делать не обязательно.
4. Если у вас не отображается кириллица, для удобства, проверяем и включаем нужные локализации.
5. Вводим sudo dpkg-reconfigure locales
6. Выбираем (пробелом) все локализации en_US (3шт) и ru_RU (4шт.). Жмем ОК.
7. По умолчанию, оставляем en_US.
8. Если команда wget не установлена на вашем сервере, выполняем команду sudo apt install wget
9. Выполняем команду wget https://raw.githubusercontent.com/ogermw/GUI-for-Ubuntu/master/setup_vnc.sh && chmod +x setup_vnc.sh && ./setup_vnc.sh
10. Вам будет предоставлено меню выбора вариантов установки. Полностью автоматический режим со стандартным паролем или ручная установка, с возможностью сразу ввести свой пароль. Так же, на ваш сервер будет установлена последняя версия браузера Google Chrome. Если выбрали полностью автоматическую установку, то пароль для пользователя vnc и пароль для подключения сеанса VNC - 172029.
11. Если во время выполнения скрипта, у вас все таки система будет выдавать сообщение о необходимости перезапуска некоторых компонентов, то нужно выбирать цифру, соответствующую значению NONE (никакие) или (в зависимости от вашей виртуализации), выбрать Cancel (Tab и стрелка вправо) и нажать Enter.
12. Чтобы изменить пароли, созданные во время установки, вводим в терминале команды:
13. vncpasswd - если просит текущий пароль, то вводим пароль (из п.10) и меняем пароль для подключения сеанса VNC (выполнять ТОЛЬКО!!! под пользователем vnc, чтобы перейти на пользователя vnc, вводим su - vnc)
14. passwd vnc - если просит текущий пароль, то вводим пароль (из п.10) и меняем пароль для пользователя vnc (можно выполнять под любым пользователем)
15. После установки, настоятельно рекомендуется добавить исключения в ваши Iptables, чтобы боты, атакующие ваш сервер, не уводили ваш сеанс VNC в режим блокировки (не сможете подключаться к нему от нескольких минут, до нескольких часов, в зависимости от частоты неудачных попыток подбора пароля к вашему серверу)
16. Вписываем команды:
17. iptables -I INPUT -p tcp -s ваш_ip_adress --dport 5901 -j ACCEPT  (заходим на 2ip.ru, смотрим свой адрес, меняем в строке на ваш)
18. iptables -A INPUT -p tcp -s 0.0.0.0/0 --dport 5901 -j DROP  (тут ничего не меняем, вводим прямо так, эта команда блокирует подключения со всех IP, кроме вашего)
19. Чтобы правила, внесенные в Iptables, сохранялись после перезагрузки сервера, введите команду sudo apt-get install iptables-persistent -y , на запрос сохранить ли внесенные в Iptables изменения для IpV4 и IpV6, нажмите Yes (для каждого запроса).
20. Подключаетесь к вашему рабочему столу с помощью любого VNC клиента, используя выданный вам IP вашего сервера и порт 5901.
    
______________________________________________________________________________________________________________________________________________________________________________________________________________________________

EN
1. Log in to the server.
2. Switch to the root user using the command sudo su.
3. Steps 3, 4, 5, and 6 are optional.
4. If Cyrillic characters are not displaying properly, for convenience, check and enable the required localizations.
5. Enter sudo dpkg-reconfigure locales.
6. Select (with the spacebar) all en_US (3 items) and ru_RU (4 items) localizations. Click OK.
7. Leave en_US as the default.
8. If the wget command is not installed on your server, execute the command sudo apt install wget.
9. Execute the command wget https://raw.githubusercontent.com/ogermw/GUI-for-Ubuntu/master/setup_vnc.sh && chmod +x setup_vnc.sh && ./setup_vnc.sh.
10. A menu of installation options will be provided. Choose between fully automated mode with a standard password or manual installation, allowing you to set your own password immediately. The latest version of the Google 11 Chrome browser will also be installed on your server. If you selected fully automated installation, the password for the vnc user and the VNC session connection password are both 172029.
11. If during script execution, your system prompts you to restart some components, select the number corresponding to NONE (no components) or, depending on your virtualization, choose Cancel (press Tab and the right arrow key) and hit Enter.
12. To change the passwords created during installation, enter the following commands in the terminal:
13. vncpasswd – if it requests the current password, enter the password (from step 10) and change the password for the VNC session connection (must be performed ONLY under the vnc user; to switch to the vnc user, enter su - vnc).
14. passwd vnc – if it requests the current password, enter the password (from step 10) and change the password for the vnc user (can be performed by any user).
15. After installation, it is highly recommended to add exceptions to your Iptables to prevent bots attacking your server from putting your VNC session into lockout mode (preventing you from connecting for several minutes to several hours, depending on the frequency of failed password attempts on your server).
16. Enter the following commands:
17. iptables -I INPUT -p tcp -s your_ip_address --dport 5901 -j ACCEPT (visit 2ip.ru, find your IP address, and replace your_ip_address in the command).
18. iptables -A INPUT -p tcp -s 0.0.0.0/0 --dport 5901 -j DROP (do not modify anything here, enter this command as-is; it blocks connections from all IPs except yours).
19. To ensure the rules added to Iptables persist after a server reboot, enter the command sudo apt-get install iptables-persistent -y, and when asked whether to save the changes made to Iptables for IPv4 and IPv6, click Yes for each request.
