#!/bin/bash

# Tech Writing Agent - Hook для проверки и исправления markdown файлов
# Срабатывает при создании или изменении файлов

# Получаем путь файла из stdin (JSON от Claude Code)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Если файл не задан или это не markdown - выходим
if [ -z "$FILE_PATH" ] || [[ ! "$FILE_PATH" =~ \.md$ ]]; then
    exit 0
fi

# Проверяем существование файла
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Получаем размер файла (не проверяем очень маленькие файлы)
FILE_SIZE=$(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null)
if [ "$FILE_SIZE" -lt 100 ]; then
    exit 0
fi

# Определяем директорию проекта
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Логируем проверку
LOG_FILE="$PROJECT_DIR/.claude/tech-writing-checks.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Проверка: $FILE_PATH" >> "$LOG_FILE"

# Здесь можно добавить дополнительную логику
# например: сохранение баланса обновлений, чтобы не срабатывать на каждое изменение

exit 0
