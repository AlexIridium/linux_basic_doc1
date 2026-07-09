# Инструкция по устранению неисправностей или аварийному восстановлению серверов "с нуля"

#### Данная инструкция предназначена для технического персонала. Подразумевается, что все необходимые пакеты-файлы, неогбходимые для установки, дополнительно хранятся отдельно на другом ПК. Технический персонал об этом знает.
#### Важно! Вся веб инфраструктура основана на работе двух серверов/двух виртуальных машин (ВМ). Данные сервера/ВМ находятся в одной сети и имеют доступ в интернет. Общая схема инфраструктуры:

*вставить картинку*

## Сервер №1 / Виртуальная машина №1

## Установка и конфигурирование frontend web сервера (NGINX)

Войдите в пользователя root, выполнив команду _sudo su_, и выполните следующие команды:

apt update

apt install nginx

systemctl status nginx

Проверить командами, что Nginx слушает 80 порт и находится в списке выполняемых процессов

ss -ntlp

ps afx

Если Nginx не запускается или запускается с ошибками, смотреть логи - выполнить команды

nginx -t

tail -n 10 /var/log/nginx/error.log

либо системный журнал

journalctl -u nginx --no-pager -n 10

*добавить информацию по реверс-прокси*


## Установка и конфигурирование backend web сервера (Apache2)

Войдите в пользователя root, выполнив команду _sudo su_, и выполните следующие команды:

apt update

apt install apache2

systemctl status apache2

При проверке логов командами

tail -n 10 /var/log/apache2/error.log

journalctl -u apache2.service --no-pager -n 10

Видно, что необходимо сментить порт для Apache2. Вводим

nano /etc/apache2/ports.conf и прописываем в конфиг с добавлением еще одного порта

Listen 8080

Listen 8081

Сохраняем Ctrl+O

apache2ctl configtest

systemctl start apache2 в случае перезапуска systemctl restart apache2 

systemctl status apache2

Выполнение балансировки (Round Robin)

Командой ss -ntlp убедится, что apache2 работает на двух портах, если нет прописать порт в конфигурации nano /etc/apache2/ports.conf

Настраиваем конфиг для работы apache2 на двух портах

nano /etc/apache2/sites-available/000-default.conf

*скопировать конфиг из вордпрес*

systemctl restart apache2



## Установка и конфигурировать базы данных MySQL

Войдите в пользователя root, выполнив команду _sudo su_, и выполните следующие команды:

apt install mysql-server-8.0

systemctl status mysql

Настройка конфига Мастер сервера/ВМ, выполнить команды и внести изменения в конфиг

cd /etc/mysql/mysql.conf.d/

nano mysqld.cnf

Изменить 

bind-address            = 0.0.0.0

Добавить

server-id = 1

log-bin = mysql-bin

binlog_format = row

gtid-mode=ON

enforce-gtid-consistency

log-replica-updates

Перезапустить БД

systemctl restart mysql

Добавим пользователя. После ввода команды mysql ввсети следующее

CREATE USER wp_test@'%' IDENTIFIED WITH 'caching_sha2_password' BY '0000';

Даём пользователю права на репликацию

GRANT REPLICATION SLAVE ON *.* TO wp_test@'%';

SELECT User, Host FROM mysql.user;

Смотрим мастер статус. Все транзакции должны перейти в Реплику

SHOW MASTER STATUS;

exit;

На втором сервере/ВМ установить БД MySQL. 

apt install mysql-server-8.0

systemctl status mysql

Настройка конфига Replica сервера/ВМ, выполнить команды и внести изменения в конфиг

cd /etc/mysql/mysql.conf.d/

nano mysqld.cnf

Изменить 

server-id = 2

log-bin = mysql-bin

relay-log = relay-log-server

read-only = ON

gtid-mode=ON

enforce-gtid-consistency

log-replica-updates

Перезапустить БД

systemctl restart mysql

Ip адрес Мастер сервера/ВМ посмотреть командой

ip -br a

Войти в БД командой mysql и прописать следующее

CHANGE REPLICATION SOURCE TO SOURCE_HOST='10.17.86.159', SOURCE_USER='wp_test', SOURCE_PASSWORD='0000', SOURCE_AUTO_POSITION = 1, GET_SOURCE_PUBLIC_KEY = 1;

START REPLICA;

Смотреть статус репликации командой

show replica status\G

Для теста репликации можно добавить БД командой на Мастер сервер

create database WP_db;

И проверить на Реплика сервере

show databases;

exit;



## Установка и конфигурирование WordPress

Войдите в пользователя root, выполнив команду _sudo su_, и выполните следующие команды:

apt install php php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip php-mysql -y

systemctl restart apache2

В БД задать следующие настройки

mysql

CREATE DATABASE wordpress_db DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

CREATE USER 'wp_test'@'localhost' IDENTIFIED BY '0000';

GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wp_test'@'localhost';

SET GLOBAL read_only = OFF;

SET GLOBAL super_read_only = OFF;

FLUSH PRIVILEGES;

EXIT;

cd /tmp && curl -L https://wordpress.org/latest.tar.gz -o latest.tar.gz

tar -xvf latest.tar.gz

sudo mkdir -p /var/www/wordpress

sudo cp -a /tmp/wordpress/. /var/www/wordpress/

sudo chown -R www-data:www-data /var/www/wordpress

sudo find /var/www/wordpress/ -type d -exec chmod 755 {} \;

sudo find /var/www/wordpress/ -type f -exec chmod 644 {} \;

cp -r wordpress/ wordpress1/

# nano wp-config.php сделать выписку из конфига

define( 'DB_NAME', 'db_name' );
define( 'DB_USER', 'db_user' );
define( 'DB_PASSWORD', 'password' );

Откройте браузер и перейдите к IP-адресу вашего сервера (команда ip -br a). Вы увидите экран приветствия WordPress. Заполните данные о сайте, создайте учетную запись администратора и нажмите «Установить WordPress».

Должна отобразится страница "Привет мир"


## Установка и конфигурирование GIT

Войдите в пользователя root, выполнив команду _sudo su_, и выполните следующие команды:

apt install git -y

git config --global user.name "Alex"

git config --global user.email "berdnikow.ksit@mail.ru"

git config --list

ssh-keygen -t ed25519

Скопировать ключ и занести в аккаунт гитхаба https://github.com/AlexIridium

cat  /root/.ssh/id_ed25519.pub 

(password Iridium_@1)

Далее выполняем

git clone git@github.com:AlexIridium/linux_project.git

git pull #запрос изменений с гитхаба

# Сюда вписать скрипт гита chmod +x backup_to_git.sh /home/berd/git_repo/linux_basic_doc1

Дополнительно для мебя можно проверить отправку файлов на гит

cat > file_from_server  (ctrl+D сохранить)

git add file_from_server

git commit -m 'file_from_server'

Отправка файла на гитхаб

git push

Список полезных команд:

git remote -v

git log

git branch

## Установка и конфигурирование мониторинга (Prometheus и Grafana)

Войдите в пользователя root, выполнив команду _sudo su_, и выполните следующие команды:

apt install prometheus

Проверка работы. Ввести каманду в терминале

curl localhost:9100/metrics

Должны появится метрики. Либо в браузере ввести

http://ip-адрес_сервера:9100/

Должна открыться страница "Node Exporter. Metrics"

Установка зависимостей

apt-get install -y adduser libfontconfig1 musl

Скопировать на сервер в папку /home/berd/grafana_dpkg файл grafana_12.3.3_21957728731_linux_amd64-224190-b33d09.deb

chmod -R +x /home/berd/grafana_dpkg

cd /home/berd/grafana_dpkg

dpkg -i grafana_12.3.3_21957728731_linux_amd64-224190-b33d09.deb

systemctl start grafana-server

По умолчанию Графана работает на 3000 порту. Проверить в браузере

http://ip-адрес_сервера:3000/

По умолчанию логин и пароль admin, admin

Перейти в Connetions --> Data sourses --> Выбрать "Prometheus". В строку Prometheus server URL ввести http://localhost:9090, остальное оставить по умолчанию. Save & test

Перейти в Dashboards --> Import Dashboard --> *пройти на сайт https://grafana.com/grafana/dashboards/ и выбрать необходимы дашборд, в наше случае ID Dashbord 1860* --> * скопировать ID Dashbord в строку Find and import dashboards и нажать Load * . Отобразится панель Node Exporter Full, моторая и является мониторингом состояния сервера/ВМ.

Тестрирование графаны

apt install stress

stress --cpu 1 --vm 2 --vm-bytes 512M --timeout 3600s

Увидим в браузере как изменяются характеристики сервера/ВМ.


## Сервер №2 / Виртуальная машина №2

## Установка и конфигурирование ELK Stack

Войдите в пользователя root, выполнив команду _sudo su_

Важно! Выполнять пункты строго в указанном порядке.

apt update

Перекопировать в папку /home/berd/elk следующие файлы-пакеты

- elasticsearch_8.17.1_amd64-224190-db972d.deb

- filebeat_8.17.1_amd64-224190-a5f894.deb

- kibana_8.17.1_amd64-224190-42bf22.deb

- logstash_8.17.1_amd64-224190-40c12c.deb

cd /home/berd/elk

Установка набора инструментов для разработки программ на языке Java

apt install default-jdk

Установка elasticsearch

dpkg -i elasticsearch_8.17.1_amd64-224190-db972d.deb

Устанавливаем лимиты памяти для виртуальной машины Java

-Xms1g

-Xmx1g

(Ctrl+D чтобы сохранить в выйти)

Настраиваем конфигурацию 


nano /etc/elasticsearch/elasticsearch.yml

#######################################

path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

xpack.security.enabled: false
xpack.security.enrollment.enabled: false

xpack.security.http.ssl:
  enabled: false
  keystore.path: certs/http.p12

xpack.security.transport.ssl:
  enabled: false
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
cluster.initial_master_nodes: ["elk"]

http.host: 0.0.0.0

############################################

Перезагружаем демоны и устанавливаем elasticsearch в автозагрузку 

systemctl daemon-reload

systemctl enable --now elasticsearch.service

systemctl status elasticsearch.service

Проверка

curl http://localhost:9200

## Установка и конфигурирование kibana

Войдите в пользователя root, выполнив команду _sudo su_ и выполните следующие команды:

dpkg -i kibana_8.17.1_amd64-224190-42bf22.deb

systemctl daemon-reload

systemctl enable --now kibana.service

nano /etc/kibana/kibana.yml

#######################################

server.port: 5601

server.host: "0.0.0.0"

#######################################

systemctl restart kibana

## Установка и конфигурирование logstash

Войдите в пользователя root, выполнив команду _sudo su_ и выполните следующие команды:

dpkg -i logstash_8.17.1_amd64-224190-40c12c.deb

systemctl enable --now logstash.service

Внесем изменения в кофигурацию:

nano /etc/logstash/logstash.yml

########################################

path.config: /etc/logstash/conf.d

#######################################

создадим конфиг

cat > /etc/logstash/conf.d/logstash-nginx-es.conf

####################################################

input {
    beats {
        port => 5400
    }
}

filter {
 grok {
   match => [ "message" , "%{COMBINEDAPACHELOG}+%{GREEDYDATA:extra_fields}"]
   overwrite => [ "message" ]
 }
 mutate {
   convert => ["response", "integer"]
   convert => ["bytes", "integer"]
   convert => ["responsetime", "float"]
 }
 date {
   match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
   remove_field => [ "timestamp" ]
 }
 useragent {
   source => "agent"
 }
}

output {
 elasticsearch {
   hosts => ["http://localhost:9200"]
   #cacert => '/etc/logstash/certs/http_ca.crt'
   #ssl => true
   index => "weblogs-%{+YYYY.MM.dd}"
   document_type => "nginx_logs"
 }
 stdout { codec => rubydebug }
}

########################################################

systemctl restart logstash.service

## Установка и конфигурирование filebeat

Войдите в пользователя root, выполнив команду _sudo su_ и выполните следующие команды:

dpkg -i filebeat_8.17.1_amd64-224190-a5f894.deb

Изменим конфиг 

nano /etc/filebeat/filebeat.yml

##########################################

filebeat.inputs:
- type: filestream
  paths:
    - /var/log/nginx/*.log

  enabled: true
  exclude_files: ['.gz$']
  prospector.scanner.exclude_files: ['.gz$']

Закомментарить блок output.elasticsearch и прописать там

output.logstash:
  hosts: ["localhost:5400"]
  
###########################################

systemctl restart filebeat

Открыть в браузере http://ip-адрес_сервера:5601/ Убедится, что страница открылась.

Пройти Stack Management --> Index Management --> убедится, что в списке имеется файл с логами 'weblogs'

Пройти Analytics --> Discover --> Create Data View --> Придумываем название, вводим шаблон weblogs-* --> Save data view

Убедится, что Кибана подгрузила события с логами. Отправить запросы и посмотреть логи nginx

curl http://localhost:80/ - без ошибки

curl http://localhost:80/abababab - c ошибкой

curl http://localhost:80/123123123 - c ошибкой

Для запуска визуализации пройти Analytics --> Dashboards --> Create dashboard --> Create visualization --> Добавить Bar-график (по вертикали Count of records, по горизонтали host.ip.keyword или url.oroginal.keyword) --> Save

Протестировать

curl http://localhost:80/ - без ошибки

curl http://localhost:80/abababab - c ошибкой

Важно! Настройку Mysql Replica смотреть в первом блоке, после настройки Mysql Master




