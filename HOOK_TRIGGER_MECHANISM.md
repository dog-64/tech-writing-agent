# Механизм триггеризации глобальных hooks

## Быстрый ответ

**Hooks триггеруются как в вашем случае:**

```
Claude выполняет Write/Edit инструмент
         ↓
PostToolUse событие срабатывает
         ↓
type: "command" выполняет bash-скрипт
         ↓
Скрипт получает JSON через stdin
         ↓
Скрипт анализирует файл и выводит результат
         ↓
Claude видит результат анализа
```

## Детально: как работают hooks

### 1. Событие PostToolUse

PostToolUse срабатывает **сразу после** того, как инструмент **успешно завершил** свою работу.

```json
{
  "matcher": "Write|Edit",        // ← Какие инструменты отслеживать
  "hooks": [
    {
      "type": "command",          // ← Выполнить bash-команду
      "command": "скрипт.sh"      // ← Какой скрипт запустить
    }
  ]
}
```

### 2. Передача контекста через stdin

Когда hook срабатывает, Claude передаёт информацию о событии в JSON через stdin:

```json
{
  "session_id": "abc123",
  "cwd": "/Users/dog/Projects/my-project",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",          // ← Какой инструмент вызвал hook
  "tool_input": {
    "file_path": "/path/to/file.md",     // ← Путь к файлу
    "content": "Содержимое файла..."     // ← Весь текст файла
  },
  "tool_response": {
    "success": true
  }
}
```

### 3. Анализ в bash-скрипте

Скрипт парсит JSON и выполняет анализ:

```bash
#!/bin/bash
input=$(cat)                    # Читаем JSON из stdin
file_path=$(echo "$input" | jq -r '.tool_input.file_path')
content=$(echo "$input" | jq -r '.tool_input.content')

# Только markdown файлы
if [[ ! "$file_path" =~ \.md$ ]]; then
    exit 0
fi

# Проверяем стоп-слова
if echo "$content" | grep -qi "безусловно"; then
    echo "⚠️  Найдено стоп-слово: 'безусловно'"
fi
```

### 4. Вывод результата

Всё что скрипт выводит в stdout, Claude **видит и может на это отреагировать**:

```bash
echo "📝 Анализ файла $file_path"
echo "⚠️  Найдено стоп-слово: 'безусловно'"
```

Claude увидит:
```
📝 Анализ файла README.md
⚠️  Найдено стоп-слово: 'безусловно'
```

И может пояснить это пользователю или предложить исправления.

## Важные ограничения

### ❌ Что НЕ работает

- `type: "prompt"` **не поддерживается** для PostToolUse (только для Stop/SubagentStop)
- Hooks **не могут блокировать** выполнение инструмента (в отличие от PreToolUse)
- Hooks **не могут напрямую вызвать** агента
- Hook **не может автоматически редактировать** файл (это сделает Claude после анализа)

### ✅ Что работает

- `type: "command"` - выполнение bash-скриптов
- Передача контекста через stdin
- Вывод информации в stdout (Claude это увидит)
- Условная обработка (только .md, только больше 100 байт и т.д.)

## Процесс в действии

### Пример: Создание README.md

```
Вы пишете:
> claude "Создай README.md с описанием проекта"

Claude создаёт README.md через Write инструмент
         ↓
📌 PostToolUse event срабатывает
         ↓
🔔 Hook вызывает ~/.claude/hooks/analyze-markdown.sh
         ↓
analyze-markdown.sh получает через stdin:
{
  "tool_input": {
    "file_path": "README.md",
    "content": "# My Project\nБезусловно, это отличный проект..."
  }
}
         ↓
Скрипт анализирует:
- Ищет стоп-слова: ✅ найдено "безусловно"
- Ищет заумные слова: ✅ найдено "использовать"
- Подсчитывает статистику
         ↓
Скрипт выводит:
⚠️  СТОП-СЛОВА:
  • 'безусловно' - ищите в тексте и удаляйте

📊 СТАТИСТИКА:
  • Слов: 47
         ↓
Claude видит вывод и показывает результат пользователю
         ↓
Пользователь видит результат и решает применять ли изменения
```

## Как работает ваша текущая конфигурация

**Ваш settings.json:**

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "~/.claude/hooks/analyze-markdown.sh"
        }
      ]
    }
  ]
}
```

**Это означает:**
1. После Write или Edit инструмента
2. Запустить скрипт ~/.claude/hooks/analyze-markdown.sh
3. Скрипт получит JSON с информацией о файле через stdin
4. Скрипт выполнит анализ
5. Claude увидит результат анализа

## Отладка

### Проверить что hook срабатывает

Добавьте логирование в скрипт:

```bash
#!/bin/bash
echo "$(date): Hook triggered" >> ~/.claude/hooks.log

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
echo "$(date): Processing $file_path" >> ~/.claude/hooks.log
```

Потом посмотрите лог:
```bash
tail -f ~/.claude/hooks.log
```

### Убедиться что скрипт исполняемый

```bash
ls -la ~/.claude/hooks/analyze-markdown.sh
# Должны быть права: -rwx--x--x
```

### Протестировать скрипт вручную

```bash
cat <<'JSON' | ~/.claude/hooks/analyze-markdown.sh
{
  "tool_input": {
    "file_path": "test.md",
    "content": "Безусловно, это тест"
  }
}
JSON
```

## Часто задаваемые вопросы

**Q: Может ли hook вызвать агента?**
A: Нет напрямую. Но hook может вывести информацию, которая подскажет Claude вызвать агента.

**Q: Может ли hook автоматически отредактировать файл?**
A: Нет, но hook может предложить Claude отредактировать файл.

**Q: Работает ли hook для всех файлов?**
A: Только для файлов которые match'ат matcher ("Write|Edit" в вашем случае).

**Q: Как отключить hook?**
A: Удалите или закомментируйте секцию "hooks" в settings.json.

**Q: Почему hook не работает?**
A: Проверьте:
- Есть ли скрипт в ~/.claude/hooks/
- Является ли скрипт исполняемым (chmod +x)
- Установлена ли jq (для парсинга JSON)
- Получает ли скрипт правильный JSON (попробуйте тестовый вызов)

## Дополнительные ресурсы

- [GLOBAL_SETUP_EXPLANATION.md](./GLOBAL_SETUP_EXPLANATION.md) - о глобальной настройке
- [HOOKS_SETUP.md](./HOOKS_SETUP.md) - полная документация
- [QUICK_START_HOOKS.md](./QUICK_START_HOOKS.md) - быстрый старт
