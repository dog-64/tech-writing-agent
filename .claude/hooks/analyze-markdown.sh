#!/bin/bash

# Tech Writing Agent - Hook для анализа markdown файлов
# Срабатывает при создании/редактировании .md файлов

# Получаем JSON из stdin
input=$(cat)

# Парсим JSON - извлекаем путь и содержимое
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
content=$(echo "$input" | jq -r '.tool_input.content // empty' 2>/dev/null)

# Если файл не задан или это не markdown - выходим молча
if [ -z "$file_path" ] || [[ ! "$file_path" =~ \.md$ ]]; then
    exit 0
fi

# Если контент пустой - выходим
if [ -z "$content" ]; then
    exit 0
fi

# Минимальный размер файла (не проверяем очень маленькие)
if [ ${#content} -lt 100 ]; then
    exit 0
fi

# Выводим анализ по методологии "Пиши, сокращай"
echo "📝 Анализ файла $file_path по методологии 'Пиши, сокращай' Ильяхова:"
echo ""

# Проверяем стоп-слова
STOPWORDS=("безусловно" "разумеется" "как правило" "собственно говоря" "мягко говоря" "скажем так" "целый ряд" "определённый" "известный" "некоторый" "довольно" "достаточно" "весьма" "практически" "фактически" "те или иные" "так или иначе" "множество")

found_stopwords=0
for word in "${STOPWORDS[@]}"; do
    if echo "$content" | grep -qi "$word"; then
        if [ $found_stopwords -eq 0 ]; then
            echo "⚠️  СТОП-СЛОВА (удаляются без потери смысла):"
            found_stopwords=1
        fi
        echo "  • '$word' - ищите в тексте и удаляйте"
    fi
done

# Проверяем заумные слова
COMPLEX_WORDS=("осуществлять" "использовать" "реализовать" "функционировать" "произвести" "осуществить")

found_complex=0
for word in "${COMPLEX_WORDS[@]}"; do
    if echo "$content" | grep -qi "$word"; then
        if [ $found_complex -eq 0 ]; then
            echo "⚠️  ЗАУМНЫЕ СЛОВА (замените простыми):"
            found_complex=1
        fi
        case "$word" in
            "осуществлять") echo "  • 'осуществлять' → 'делать'" ;;
            "использовать") echo "  • 'использовать' → 'применять', 'брать'" ;;
            "реализовать") echo "  • 'реализовать' → 'сделать', 'создать'" ;;
            "функционировать") echo "  • 'функционировать' → 'работать'" ;;
        esac
    fi
done

# Проверяем лишние пробелы и переносы
multiple_newlines=$(echo "$content" | grep -c "^$" || true)
if [ "$multiple_newlines" -gt 3 ]; then
    echo "⚠️  ФОРМАТИРОВАНИЕ:"
    echo "  • Найдено много пустых строк подряд - уберите лишние"
fi

# Подсчитываем статистику
word_count=$(echo "$content" | wc -w)
line_count=$(echo "$content" | wc -l)

echo ""
echo "📊 СТАТИСТИКА:"
echo "  • Слов: $word_count"
echo "  • Строк: $line_count"
echo "  • Средняя длина строки: $(echo "scale=0; $word_count / $line_count" | bc) слов"

echo ""
echo "✅ Совет: Используйте эту информацию как guideline. Окончательное решение - ваше!"
echo ""

exit 0
