# Инструкция по устранению неисправностей или аварийному восстановлению серверов "с нуля"

#### Данная инструкция предназначена для технического персонала
#### Важно! Вся веб инфраструктура основана на работе двух серверов/двух виртуальных машин (ВМ). Данные сервера/ВМ находятся в одной сети и имеют доступ в интернет. Общая схема инфраструктуры:

*вставить картинку*

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














