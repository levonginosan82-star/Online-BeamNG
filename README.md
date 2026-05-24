# Online BeamNG.drive — Multiplayer Mod

Клиент-серверный мод для мультиплеера в BeamNG.drive на Node.js/TypeScript.

## Архитектура

```
Online_BeamNG.drive/
├── server/                  # Node.js/TypeScript сервер + веб-админка
│   ├── src/
│   │   ├── index.ts         # Точка входа (запуск веб-админки)
│   │   ├── App.ts           # Express + API + управление game-сервером
│   │   ├── Server.ts        # WebSocket game-сервер (синхр. машин и т.д.)
│   │   ├── Client.ts        # Управление клиентами
│   │   ├── Room.ts          # Комната/игровая сессия
│   │   ├── protocol.ts      # Типы сообщений WebSocket
│   │   ├── config.ts        # Конфигурация
│   │   ├── logger.ts        # Логирование
│   │   ├── api/             # REST API (статус, конфиг, старт/стоп, логи)
│   │   └── web/             # Веб-админка (HTML/CSS/JS)
│   ├── dist/                # Скомпилированный JS
│   └── package.json
├── client/                  # Lua мод для BeamNG.drive
│   └── mods/OnlineBeamNG/
│       ├── info.json
│       ├── scripts/         # Точка входа мода
│       ├── lua/ge/extensions/   # GE-расширения
│       ├── lua/vehicle/extensions/ # Vehicle-расширения
│       ├── ui/              # HTML/CSS/JS интерфейс
│       └── settings/        # Настройки
├── scripts/
│   ├── install_mod.bat      # Установка мода (cmd)
│   └── install_mod.ps1      # Установка мода (PowerShell)
├── launcher/
│   ├── start_server.bat     # Запуск сервера
│   └── start_all.bat        # Запуск сервера + игры
└── README.md
```

## Запуск

```bash
cd server
npm install
npm run build
npm start
```

После запуска открыть в браузере: **http://localhost:30815**

В веб-админке доступно:
- **Dashboard** — статус сервера, статистика (игроки, машины, аптайм)
- **Configuration** — настройка порта, имени, пароля, карты, лимитов
- **Start / Stop / Restart** — управление game-сервером
- **Players** — список подключённых игроков
- **Logs** — живые логи сервера

Game-сервер запускается на порту 30814 (WebSocket для клиентов).

### Переменные окружения

| Переменная | Описание | По умолч. |
|-----------|----------|-----------|
| `ADMIN_PORT` | Порт веб-админки | 30815 |
| `BEMP_PORT` | Порт game-сервера | 30814 |
| `BEMP_HOST` | Хост | 0.0.0.0 |
| `BEMP_SERVER_NAME` | Название сервера | BeamNG Online Server |
| `BEMP_PASSWORD` | Пароль | (пусто) |
| `BEMP_MAX_PLAYERS` | Макс. игроков | 16 |
| `BEMP_LOG_LEVEL` | Уровень логов | info |

### Установка клиента (мод) — автоматическая

**Способ 1 — скрипт установки:**
```powershell
# PowerShell (администратор не требуется)
.\scripts\install_mod.ps1
```

**Способ 2 — вручную:**
1. Скопировать папку `client/mods/OnlineBeamNG` в `%USERPROFILE%/Documents/BeamNG.drive/mods/`
2. Запустить BeamNG.drive
3. В главном меню появится кнопка "Online BeamNG"

### Быстрый старт (лаунчер)

Просто запустить `launcher/start_all.bat` — он сам:
1. Установит зависимости (`npm install`)
2. Соберёт сервер (`npm run build`)
3. Запустит сервер и игру
4. Откроет админку `http://localhost:30815`

Или по отдельности:
- `launcher/start_server.bat` — только сервер
- `scripts/install_mod.bat` — установка мода + создание ярлыка на рабочем столе

## REST API

| Endpoint | Метод | Описание |
|----------|-------|----------|
| `/api/status` | GET | Статус сервера |
| `/api/config` | GET | Текущая конфигурация |
| `/api/config` | PUT | Обновить конфигурацию |
| `/api/start` | POST | Запустить game-сервер |
| `/api/stop` | POST | Остановить game-сервер |
| `/api/restart` | POST | Перезапустить game-сервер |
| `/api/logs?count=N` | GET | Последние N логов |
| `/api/players` | GET | Список игроков |

## TODO

- [ ] Голосовой чат
- [ ] Синхронизация модов
- [ ] Погода/время
- [ ] Админ-команды из чата
- [ ] Бан-лист
