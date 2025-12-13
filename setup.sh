#!/bin/bash

# Tech Writing Agent - Setup Script
# Устанавливает агента в ~/.claude/agents/tech-writing-agent

set -e  # Остановка при ошибке

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      🤖 Tech Writing Agent - Installation                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Проверка, что скрипт запущен из корня репозитория
if [ ! -f "tech-writing-agent.md" ]; then
    echo -e "${RED}❌ Ошибка: tech-writing-agent.md не найден${NC}"
    echo -e "${YELLOW}Запустите скрипт из корня репозитория tech-writing-agent${NC}"
    exit 1
fi

# Определяем директорию установки
INSTALL_DIR="$HOME/.claude/agents/tech-writing-agent"

echo -e "${BLUE}📁 Директория установки:${NC} $INSTALL_DIR"
echo ""

# Создаём директорию если её нет
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  Директория $INSTALL_DIR уже существует${NC}"
    read -p "Перезаписать? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Установка отменена${NC}"
        exit 0
    fi
    echo -e "${BLUE}🗑️  Удаляю старую версию...${NC}"
    rm -rf "$INSTALL_DIR"
fi

echo -e "${BLUE}📦 Создаю директорию...${NC}"
mkdir -p "$INSTALL_DIR"

# Копируем файлы
echo -e "${BLUE}📋 Копирую файлы агента...${NC}"

# Основной файл агента
cp tech-writing-agent.md "$INSTALL_DIR/"
echo -e "${GREEN}  ✓${NC} tech-writing-agent.md"

echo ""
echo -e "${GREEN}✅ Установка завершена!${NC}"
echo ""

# Проверяем наличие Claude CLI
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude CLI обнаружен${NC}"
    echo ""
    echo -e "${BLUE}🚀 Использование:${NC}"
    echo ""
    echo -e "  ${YELLOW}claude --include ~/.claude/agents/tech-writing-agent/tech-writing-agent.md \"Отредактируй мой README\"${NC}"
    echo ""
    echo -e "${BLUE}💡 Рекомендация:${NC} Добавьте alias в ~/.zshrc или ~/.bashrc:"
    echo ""
    echo -e "  ${YELLOW}alias tech-writer='claude --include ~/.claude/agents/tech-writing-agent/tech-writing-agent.md'${NC}"
    echo ""
    echo -e "Затем используйте:"
    echo ""
    echo -e "  ${YELLOW}tech-writer \"Проверь этот документ на стоп-слова\"${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠️  Claude CLI не найден${NC}"
    echo -e "${BLUE}Установите Claude CLI:${NC} https://docs.anthropic.com/claude/docs/claude-code"
    echo ""
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      ✨ Tech Writing Agent готов к работе!                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
