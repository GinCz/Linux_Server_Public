# Инцидент: взлом gincz на сервере 109 — 01.08.2026

**Дата:** 01 августа 2026  
**Сервер:** 212.109.223.109 (RU, FastVDS)  
**Аккаунт:** gincz  
**Сайты:** voyage4u.ru, news-port.ru, prodvig-saita.ru  

## IP атакующих (заблокированы в iptables)
- 195.201.235.210
- 46.226.166.112
- 103.130.18.131
- 15.204.114.164

## Точка входа
Joomla 1.5 (2010) + com_extplorer — критически устаревший компонент.
Атакующий получил доступ к файловому менеджеру и загрузил шеллы.

## Удалённые бэкдоры
### voyage4u.ru
- /450449/ (директория)
- /3764d666/ (директория)
- /administrator/modules/index.php
- /administrator/components/com_extplorer/index.php

### prodvig-saita.ru
- /450449/ (директория)
- /49c9a63d/ (директория)
- wp-content/ngg/modules/photocrati-frame_communication/radio.php
- wp-content/uploads/2024/07/index.php
- wp-content/uploads/2023/07/wp-login.php
- wp-content/plugins/tinymce-advanced/mce/content.php
- wp-includes/mai.php
- wp-includes/blocks/term-count/index.php

### news-port.ru
- /450449/ (директория)
- /8fd0f2d0/ (директория)
- wp-content__113576e/uploads/2026/03/index.php
- wp-content__113576e/uploads/2025/11/content.php
- wp-content__113576e/languages/themes/index.php
- wp-includes__113576e/lock360.php
- wp-includes__113576e/js/dist/script-modules/interactivity-router/index.php
- wp-includes__113576e/js/jquery/index.php
- wp-includes__113576e/css/dist/list-reusable-blocks/radio.php
- wp-includes__113576e/SimplePie/src/Parse/wp-login.php
- wp-includes__113576e/customize/2index.php

## Восстановление
Все 3 сайта восстановлены из бэкапов FastPanel (февраль 2026).

## Дополнительная защита
- /administrator заблокирован для всех IP кроме белого списка
- PHP в uploads заблокирован через .htaccess
- com_extplorer заблокирован через chmod 000
- Пароль БД voyage4u изменён

## Итог
Вирус НЕ вышел за пределы аккаунта gincz.
Проверены все 28 аккаунтов FastPanel — чисто.

## Рекомендации
- Перевести voyage4u.ru на современную CMS (Joomla 4/5 или WordPress)
- Voyage4u работает на Joomla 1.5 (2010) — End of Life с 2012 года
