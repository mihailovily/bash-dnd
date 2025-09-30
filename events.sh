#!/bin/bash

# События в комнатах

# Встреча с монстром
monster_encounter() {
    clear
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║              👹 МОНСТР! 👹                        ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    
    # Генерация случайного монстра
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
        # Победа - шанс найти зелье
        local potion_drop=$((RANDOM % 100))
        if [ $potion_drop -lt 30 ]; then
            echo ""
            echo "🧪 Ты находишь зелье лечения!"
            POTIONS=$((POTIONS + 1))
            sleep 1
        fi
    elif [ $result -eq 2 ]; then
        echo ""
        echo "Ты отступаешь в предыдущую комнату..."
        ROOMS_CLEARED=$((ROOMS_CLEARED - 1))
        if [ $ROOMS_CLEARED -lt 0 ]; then
            ROOMS_CLEARED=0
        fi
    fi
    
    echo ""
    read -p "Нажми Enter для продолжения..."
}

# Сундук
chest_encounter() {
    clear
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║              📦 СУНДУК! 📦                        ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    draw_chest
    echo ""
    echo "Ты обнаруживаешь старинный сундук!"
    echo ""
    echo "1) Открыть сундук"
    echo "2) Обойти стороной"
    echo ""
    read -p "Твой выбор: " choice
    
    case $choice in
        1)
            echo ""
            echo "Ты осторожно открываешь сундук..."
            sleep 1
            
            # 60% - сокровище, 30% - ловушка, 10% - оружие
            local chest_event=$((RANDOM % 100))
            
            if [ $chest_event -lt 60 ]; then
                # Золото
                local gold=$((20 + RANDOM % 50))
                GOLD=$((GOLD + gold))
                echo ""
                echo "✨ Внутри куча золотых монет!"
                echo "💰 Ты получаешь $gold золота!"
                
            elif [ $chest_event -lt 90 ]; then
                # Ловушка
                echo ""
                echo "💥 ЭТО ЛОВУШКА!"
                local trap_dmg=$((5 + RANDOM % 15))
                HP=$((HP - trap_dmg))
                echo "💔 Ты получаешь $trap_dmg урона от ловушки!"
                
                if [ $HP -le 0 ]; then
                    echo ""
                    echo "💀 Ловушка оказалась смертельной..."
                fi
                
            else
                # Новое оружие
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
            ;;
            
        2)
            echo ""
            echo "Ты решаешь не рисковать и проходишь мимо."
            ;;
            
        *)
            echo "Ты в замешательстве... лучше пойти дальше."
            ;;
    esac
    
    echo ""
    read -p "Нажми Enter для продолжения..."
}

# Пустая комната
empty_room() {
    clear
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║            🕯️  ПУСТАЯ КОМНАТА 🕯️                 ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    draw_empty_room
    echo ""
    echo "В этой комнате никого нет..."
    echo "Факелы на стенах тускло освещают коридор."
    echo ""
    
    # Маленький шанс найти что-то
    local find_chance=$((RANDOM % 100))
    
    if [ $find_chance -lt 20 ]; then
        echo "🔍 Ты замечаешь что-то в углу..."
        sleep 1
        
        local find_type=$((RANDOM % 3))
        case $find_type in
            0)
                local gold=$((5 + RANDOM % 15))
                GOLD=$((GOLD + gold))
                echo "💰 Несколько золотых монет! (+$gold золота)"
                ;;
            1)
                if [ $HP -lt $MAX_HP ]; then
                    local rest_heal=$((10 + RANDOM % 10))
                    HP=$((HP + rest_heal))
                    if [ $HP -gt $MAX_HP ]; then
                        HP=$MAX_HP
                    fi
                    echo "💤 Ты решаешь немного отдохнуть. (+$rest_heal HP)"
                else
                    echo "🍞 Ты находишь чёрствый хлеб, но есть не хочется."
                fi
                ;;
            2)
                echo "🧪 Зелье лечения лежит у стены!"
                POTIONS=$((POTIONS + 1))
                ;;
        esac
    else
        echo "Можно немного отдохнуть и набраться сил."
        
        if [ $HP -lt $MAX_HP ]; then
            echo ""
            read -p "Отдохнуть? (д/н): " rest
            if [ "$rest" == "д" ] || [ "$rest" == "y" ]; then
                local heal=$((5 + RANDOM % 10))
                HP=$((HP + heal))
                if [ $HP -gt $MAX_HP ]; then
                    HP=$MAX_HP
                fi
                echo "💤 Ты отдыхаешь несколько минут. (+$heal HP)"
            fi
        fi
    fi
    
    echo ""
    read -p "Нажми Enter для продолжения..."
}