# PIDD.ORG — Полезные ссылки и сообщества
<p align="center">🌐 <a href="https://pidd.org"><b>Перейти на сайт</b></a></p>

<p align="center">
  <img src="https://i.imgur.com/kdjYnEJ.png" alt="Описание" />
</p>


# 📄 Инструкция по заполнению `links.json`

Данный файл используется для хранения списка ссылок, их категорий, значков и отображаемых цветов.

## Структура файла

JSON содержит 3 основных блока:

1. **`links`** – массив объектов со ссылками.
2. **`presetBadges`** – предустановленные бейджи (текст и цвет).
3. **`categoryNames`** и **`categoryColors`** – названия и цвета категорий.

---

## 1. Массив `links`

Каждый объект внутри `links` описывает одну ссылку.

### Пример объекта:

```json
{
    "id": 1,
    "title": "PIDD.ORG - Канал",
    "desc": "Пенис?",
    "icon": "bi-telegram",
    "url": "https://t.me/piddorg",
    "category": "contact",
    "pinned": true,
    "badges": [
        "primary",
        "community"
    ]
}
```

### Поля:

| Поле        | Тип           | Обяз. | Описание |
|-------------|--------------|-------|----------|
| `id`        | number       | ✅    | Уникальный числовой идентификатор ссылки. |
| `title`     | string       | ✅    | Заголовок ссылки. |
| `desc`      | string       | ✅    | Краткое описание. |
| `icon`      | string / SVG | ✅    | Иконка Bootstrap Icons (например, `bi-telegram`) или SVG-код. |
| `url`       | string       | ✅    | Полная ссылка (http/https). |
| `category`  | string       | ✅    | Категория ссылки (из списка `categoryNames`). |
| `pinned`    | boolean      | ❌    | Закреплена ли ссылка (отображается выше остальных). |
| `badges`    | array[string]| ❌    | Список бейджей (ключи из `presetBadges`). |

---

## 2. Объект `presetBadges`

Содержит предустановленные бейджи, которые можно использовать в `badges`.

### Пример:

```json
"primary": {
    "text": "Основной",
    "color": "#f59e0b"
}
```

| Поле   | Тип     | Описание |
|--------|--------|----------|
| `text` | string | Текст, отображаемый на бейдже. |
| `color`| string | Цвет бейджа в HEX-формате. |

---

## 3. Объекты `categoryNames` и `categoryColors`

Определяют доступные категории ссылок и их цвета.

### Пример:

```json
"categoryNames": {
    "wiki": "Wiki",
    "git": "GitHub",
    "contact": "Сообщества",
    "monitoring": "Мониторинг"
},
"categoryColors": {
    "contact": "#f59e0b",
    "git": "#6f42c1",
    "wiki": "#0ea5e9",
    "all": "var(--brand)",
    "monitoring": "#d6336c"
}
```

- **`categoryNames`** – ключ (ID категории) и читаемое название.
- **`categoryColors`** – цвет категории в HEX или CSS-переменной.

---

## 4. Правила заполнения

1. **`id` уникален** – не повторяйте значения.
2. **`category`** должно существовать в `categoryNames`.
3. **`badges`** должны быть ключами из `presetBadges`.
4. **`icon`**:
   - Можно использовать Bootstrap Icons: `"bi-telegram"`, `"bi-github"`, и т.д.
   - Либо вставить SVG-код в виде строки.
5. При добавлении новых бейджей:
   - Добавьте их в `presetBadges`.
   - Используйте уникальный ключ.
6. Цвета в `presetBadges` и `categoryColors` указываются в HEX-формате (`#rrggbb`) или как CSS-переменная.

---

## 5. Минимальный пример нового элемента

```json
{
    "id": 200,
    "title": "Новый ресурс",
    "desc": "Описание ресурса.",
    "icon": "bi-link",
    "url": "https://example.com",
    "category": "wiki",
    "pinned": false,
    "badges": ["wiki", "community"]
}
```

---

## 6. Рекомендации по ведению файла

- Держите JSON в **валидном формате** (проверяйте через [jsonlint.com](https://jsonlint.com/)).
- Используйте **двойные кавычки** для ключей и строк.
- Сортируйте `links` по `id` или по категориям для удобства.
- Не вставляйте слишком длинные описания – до **150 символов**.
