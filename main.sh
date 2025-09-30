#!/bin/bash

# Dungeon Crawler - главный файл
# Запуск: chmod +x main.sh && ./main.sh

source ./config.sh
source ./graphics.sh
source ./combat.sh
source ./events.sh
source ./map.sh

# Инициализация игрока
init_player() {
    HP=$MAX_HP
    GOLD=0
    WEAPON="Ржавый меч"
    WEAPON_DMG=5
    ROOMS_CLEARED=0
    POTIONS=2
}

# Главное меню
show_menu() {
    clear
    draw_title
    echo ""
    echo "  1) Начать новую игру"
    echo "  2) Правила игры"
    echo "  3) Выход"
    echo ""
    read -p "Выбери опцию: " choice
    
    case $choice in
        1) start_game ;;
        2) show_rules ;;
        3) echo "До встречи, авантюрист!"; exit 0 ;;
        *) show_menu ;;
    esac
}

# Правила
show_rules() {
    clear
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║              ПРАВИЛА ИГРЫ                         ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    echo "Цель: Пройти $ROOMS_TO_WIN комнат и найти выход из подземелья!"
    echo ""
    echo "Управление:"
    echo "  W/A/S/D - движение"
    echo "  E - взаимодействие с объектами"
    echo "  Q - выход в меню"
    echo ""
    echo "Символы на карте:"
    echo "  @ - твой персонаж"
    echo "  # - стены"
    echo "  ? - сундуки"
    echo "  M - монстры"
    echo "  B - боссы (окружены !)"
    echo "  E - выход из подземелья"
    echo "  + - двери (ведут в другие комнаты)"
    echo "  H - зелье лечения"
    echo ""
    echo "В комнатах:"
    echo "  • Избегай или сражайся с монстрами"
    echo "  • Открывай сундуки (могут быть ловушки)"
    echo "  • Собирай зелья для восстановления HP"
    echo "  • Используй двери для перехода в другие комнаты"
    echo ""
    echo "Параметры:"
    echo "  • HP - твоё здоровье (если 0 - конец игры)"
    echo "  • Золото - собирай для улучшений"
    echo "  • Оружие - чем лучше, тем больше урон"
    echo ""
    read -p "Нажми Enter для возврата в меню..."
    show_menu
}

# Начало игры
start_game() {
    init_player
    clear
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║          ДОБРО ПОЖАЛОВАТЬ В ПОДЗЕМЕЛЬЕ!           ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    echo "Ты просыпаешься в тёмном подземелье..."
    echo "Перед тобой расстилается мрачная комната."
    echo "Единственный путь к свободе - исследовать все комнаты!"
    echo ""
    echo "Используй W/A/S/D для движения и E для взаимодействия."
    echo ""
    read -p "Нажми Enter, чтобы начать приключение..."
    
    game_loop
}

# Основной игровой цикл
game_loop() {
    while [ $HP -gt 0 ] && [ $ROOMS_CLEARED -lt $ROOMS_TO_WIN ]; do
        # Определяем тип комнаты
        local room_type
        
        if [ $ROOMS_CLEARED -eq $((ROOMS_TO_WIN - 1)) ]; then
            room_type=4  # Последняя комната - выход
        elif [ $ROOMS_CLEARED -eq 5 ]; then
            room_type=3  # Босс на 6-й комнате
        else
            room_type=$((RANDOM % 3))  # 0-монстр, 1-сундук, 2-пустая
        fi
        
        # Исследуем комнату
        explore_room $room_type
        local result=$?
        
        case $result in
            99)  # Выход в меню
                clear
                echo "Ты покидаешь подземелье..."
                sleep 1
                show_menu
                return
                ;;
            1)  # Сундук
                handle_chest_in_room
                ;;
            2)  # Монстр
                handle_monster_in_room
                if [ $HP -le 0 ]; then
                    game_over
                    return
                fi
                ;;
            3)  # Босс
                handle_boss_in_room
                if [ $HP -le 0 ]; then
                    game_over
                    return
                fi
                ;;
            4)  # Выход
                ((ROOMS_CLEARED++))
                victory
                return
                ;;
            6)  # Дверь - переход в следующую комнату
                ((ROOMS_CLEARED++))
                clear
                echo ""
                echo "Ты проходишь через дверь в следующую комнату..."
                sleep 1
                ;;
        esac
    done
    
    if [ $HP -le 0 ]; then
        game_over
    elif [ $ROOMS_CLEARED -ge $ROOMS_TO_WIN ]; then
        victory
    fi
}

# Обработка сундука в комнате
handle_chest_in_room() {
    clear
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║              📦 СУНДУК! 📦                        ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    draw_chest
    echo ""
    echo "Ты подходишь к сундуку..."
    echo ""
    echo "1) Открыть сундук"
    echo "2) Вернуться к исследованию"
    echo ""
    read -p "Твой выбор: " choice
    
    if [ "$choice" == "1" ]; then
        echo ""
        echo "Ты осторожно открываешь сундук..."
        sleep 1
        
        local chest_event=$((RANDOM % 100))
        
        if [ $chest_event -lt 60 ]; then
            local gold=$((20 + RANDOM % 50))
            GOLD=$((GOLD + gold))
            echo ""
            echo "✨ Внутри куча золотых монет!"
            echo "💰 Ты получаешь $gold золота!"
            
        elif [ $chest_event -lt 90 ]; then
            echo ""
            echo "💥 ЭТО ЛОВУШКА!"
            local trap_dmg=$((5 + RANDOM % 15))
            HP=$((HP - trap_dmg))
            echo "💔 Ты получаешь $trap_dmg урона от ловушки!"
            
            if [ $HP -le 0 ]; then
                echo ""
                echo "💀 Ловушка оказалась смертельной..."
                sleep 2
                game_over
                return
            fi
            
        else
            local w_idx=$((RANDOM % ${#WEAPONS[@]}))
            local new_weapon="${WEAPONS[$w_idx]}"
            local new_dmg="${WEAPON_DAMAGES[$w_idx]}"
            
            echo ""
            echo "⚔️  Ты находишь новое оружие: $new_weapon!"
            echo "Урон: $new_dmg (текущее: $WEAPON_DMG)"
            echo ""
            read -p "Забрать это оружие? (д/н): " take
            
            if [ "$take" == "д" ] || [ "$take" == "y" ]; then
                WEAPON="$new_weapon"
                WEAPON_DMG=$new_dmg
                echo "✅ Ты экипировал $new_weapon!"
            else
                echo "Ты оставляешь оружие в сундуке."
            fi
        fi
        
        echo ""
        read -p "Нажми Enter для продолжения исследования..."
    fi
}

# Обработка монстра в комнате
handle_monster_in_room() {
    clear
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║              👹 МОНСТР! 👹                        ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    
    local idx=$((RANDOM % ${#MONSTERS[@]}))
    local monster_name="${MONSTERS[$idx]}"
    local monster_hp="${MONSTER_HP[$idx]}"
    local monster_dmg="${MONSTER_DMG[$idx]}"
    
    draw_monster
    echo ""
    echo "Перед тобой появляется $monster_name!"
    echo "HP: $monster_hp | Урон: ~$monster_dmg"
    echo ""
    read -p "Нажми Enter, чтобы начать бой..."
    
    fight_monster $monster_hp $monster_dmg "$monster_name"
    local result=$?
    
    if [ $result -eq 0 ]; then
        local potion_drop=$((RANDOM % 100))
        if [ $potion_drop -lt 30 ]; then
            echo ""
            echo "🧪 Монстр выронил зелье лечения!"
            POTIONS=$((POTIONS + 1))
            sleep 1
        fi
    fi
    
    echo ""
    read -p "Нажми Enter для продолжения исследования..."
}

# Обработка босса в комнате
handle_boss_in_room() {
    clear
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║           💀 БОСС ПОДЗЕМЕЛЬЯ! 💀                  ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    echo "      .-."
    echo "     (O.O)"
    echo "      |=|      /\\___/\\"
    echo "     __|__    (  o.o  )"
    echo "   //.|.=\\\\    >  ^  <"
    echo "  //.=|=.\\\\  //|   |\\\\"
    echo "  \\\\=.|.=//  \\\\|   |//"
    echo "   \\\\_=_//    '-----'"
    echo ""
    echo "Огромное существо преграждает тебе путь!"
    echo "Это охранник подземелья!"
    echo ""
    read -p "Нажми Enter, чтобы начать эпичный бой..."
    
    fight_monster 80 15 "Страж Подземелья"
    local result=$?
    
    if [ $result -eq 0 ]; then
        echo ""
        echo "🏆 Ты победил босса!"
        local gold_reward=$((50 + RANDOM % 50))
        GOLD=$((GOLD + gold_reward))
        echo "💰 Ты получаешь $gold_reward золота!"
        POTIONS=$((POTIONS + 2))
        echo "🧪 Ты находишь 2 зелья лечения!"
        sleep 2
    fi
    
    echo ""
    read -p "Нажми Enter для продолжения..."
}

# Показ статуса игрока
show_status() {
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║  ❤️  HP: $HP/$MAX_HP  💰 Золото: $GOLD  🗡️  $WEAPON"
    echo "║  🧪 Зелья: $POTIONS  📍 Комната: $ROOMS_CLEARED/$ROOMS_TO_WIN"
    echo "╚════════════════════════════════════════════════════════╝"
}

# Победа
victory() {
    clear
    draw_victory
    echo ""
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║            🎉 ПОЗДРАВЛЯЕМ! 🎉                     ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    echo "Ты смог выбраться из подземелья!"
    echo "Пройдено комнат: $ROOMS_CLEARED"
    echo "Собрано золота: $GOLD"
    echo "Осталось HP: $HP/$MAX_HP"
    echo ""
    read -p "Нажми Enter для возврата в меню..."
    show_menu
}

# Конец игры
game_over() {
    clear
    draw_game_over
    echo ""
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║              💀 GAME OVER 💀                      ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    echo "Ты пал в бою..."
    echo "Пройдено комнат: $ROOMS_CLEARED/$ROOMS_TO_WIN"
    echo "Собрано золота: $GOLD"
    echo ""
    read -p "Нажми Enter для возврата в меню..."
    show_menu
}

# Запуск игры
show_menu