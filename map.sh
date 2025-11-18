#!/bin/bash


ROOM_WIDTH=40
ROOM_HEIGHT=15

# Позиция игрока
PLAYER_X=0
PLAYER_Y=0

# Текущая комната
declare -a CURRENT_ROOM

# Типы объектов на карте
EMPTY=" "
WALL="#"
PLAYER="@"
CHEST="?"
MONSTER="M"
BOSS="B"
EXIT="E"
DOOR="+"

# Генерация случайной комнаты
generate_room() {
    local room_type=$1  # 0-монстр, 1-сундук, 2-пустая, 3-босс, 4-выход
    
    CURRENT_ROOM=()
    
    # Создаём пустую комнату
    for ((y=0; y<ROOM_HEIGHT; y++)); do
        for ((x=0; x<ROOM_WIDTH; x++)); do
            if [ $y -eq 0 ] || [ $y -eq $((ROOM_HEIGHT-1)) ]; then
                # Верхняя и нижняя стены
                CURRENT_ROOM[$((y * ROOM_WIDTH + x))]="$WALL"
            elif [ $x -eq 0 ] || [ $x -eq $((ROOM_WIDTH-1)) ]; then
                # Левая и правая стены
                CURRENT_ROOM[$((y * ROOM_WIDTH + x))]="$WALL"
            else
                CURRENT_ROOM[$((y * ROOM_WIDTH + x))]="$EMPTY"
            fi
        done
    done
    
    # Добавляем двери
    # Верхняя дверь
    CURRENT_ROOM[$((0 * ROOM_WIDTH + ROOM_WIDTH/2))]="$DOOR"
    # Нижняя дверь
    CURRENT_ROOM[$(((ROOM_HEIGHT-1) * ROOM_WIDTH + ROOM_WIDTH/2))]="$DOOR"
    # Левая дверь
    CURRENT_ROOM[$((ROOM_HEIGHT/2 * ROOM_WIDTH + 0))]="$DOOR"
    # Правая дверь
    CURRENT_ROOM[$((ROOM_HEIGHT/2 * ROOM_WIDTH + (ROOM_WIDTH-1)))]="$DOOR"
    
    # Размещаем игрока в начальной позиции (снизу по центру)
    PLAYER_X=$((ROOM_WIDTH / 2))
    PLAYER_Y=$((ROOM_HEIGHT - 2))
    
    # Добавляем препятствия (стены внутри)
    local obstacles=$((RANDOM % 5 + 3))
    for ((i=0; i<obstacles; i++)); do
        local ox=$((RANDOM % (ROOM_WIDTH - 4) + 2))
        local oy=$((RANDOM % (ROOM_HEIGHT - 4) + 2))
        
        # Проверяем, что не на позиции игрока и не на двери
        if [ $ox -ne $PLAYER_X ] || [ $oy -ne $PLAYER_Y ]; then
            CURRENT_ROOM[$((oy * ROOM_WIDTH + ox))]="$WALL"
        fi
    done
    
    # Размещаем объекты в зависимости от типа комнаты
    case $room_type in
        0)  # Монстр
            local num_monsters=$((RANDOM % 3 + 1))
            for ((i=0; i<num_monsters; i++)); do
                place_object "$MONSTER"
            done
            ;;
        1)  # Сундук
            local num_chests=$((RANDOM % 2 + 1))
            for ((i=0; i<num_chests; i++)); do
                place_object "$CHEST"
            done
            ;;
        2)  # Пустая комната (может быть зелье)
            if [ $((RANDOM % 100)) -lt 30 ]; then
                place_object "H"  # Health potion
            fi
            ;;
        3)  # Босс
            # Размещаем босса в центре
            local bx=$((ROOM_WIDTH / 2))
            local by=$((ROOM_HEIGHT / 2))
            CURRENT_ROOM[$((by * ROOM_WIDTH + bx))]="$BOSS"
            CURRENT_ROOM[$(((by-1) * ROOM_WIDTH + bx-1))]="!"
            CURRENT_ROOM[$(((by-1) * ROOM_WIDTH + bx+1))]="!"
            ;;
        4)  # Выход
            local ex=$((ROOM_WIDTH / 2))
            local ey=$((ROOM_HEIGHT / 2))
            CURRENT_ROOM[$((ey * ROOM_WIDTH + ex))]="$EXIT"
            ;;
    esac
}

# Размещение объекта в случайном месте
place_object() {
    local obj=$1
    local placed=0
    local attempts=0
    
    while [ $placed -eq 0 ] && [ $attempts -lt 50 ]; do
        local ox=$((RANDOM % (ROOM_WIDTH - 4) + 2))
        local oy=$((RANDOM % (ROOM_HEIGHT - 4) + 2))
        
        local idx=$((oy * ROOM_WIDTH + ox))
        
        # Проверяем, что клетка пуста и не рядом с игроком
        if [ "${CURRENT_ROOM[$idx]}" == "$EMPTY" ]; then
            local dist=$(( (ox - PLAYER_X) * (ox - PLAYER_X) + (oy - PLAYER_Y) * (oy - PLAYER_Y) ))
            if [ $dist -gt 9 ]; then  # Минимальное расстояние от игрока
                CURRENT_ROOM[$idx]="$obj"
                placed=1
            fi
        fi
        
        attempts=$((attempts + 1))
    done
}

# Отрисовка комнаты
draw_room() {
    echo "╔════════════════════════════════════════════════════════╗"
    
    for ((y=0; y<ROOM_HEIGHT; y++)); do
        echo -n "║ "
        for ((x=0; x<ROOM_WIDTH; x++)); do
            if [ $x -eq $PLAYER_X ] && [ $y -eq $PLAYER_Y ]; then
                echo -n "$PLAYER"
            else
                local idx=$((y * ROOM_WIDTH + x))
                echo -n "${CURRENT_ROOM[$idx]}"
            fi
        done
        echo " ║"
    done
    
    echo "╚════════════════════════════════════════════════════════╝"
}

# Проверка столкновения
check_collision() {
    local x=$1
    local y=$2
    local idx=$((y * ROOM_WIDTH + x))
    
    local tile="${CURRENT_ROOM[$idx]}"
    
    # Стены блокируют движение
    if [ "$tile" == "$WALL" ]; then
        return 1
    fi
    
    return 0
}

# Проверка взаимодействия с объектом
check_interaction() {
    local idx=$((PLAYER_Y * ROOM_WIDTH + PLAYER_X))
    local tile="${CURRENT_ROOM[$idx]}"
    
    case "$tile" in
        "$CHEST")
            CURRENT_ROOM[$idx]="$EMPTY"
            return 1  # Сундук
            ;;
        "$MONSTER")
            CURRENT_ROOM[$idx]="$EMPTY"
            return 2  # Монстр
            ;;
        "$BOSS")
            CURRENT_ROOM[$idx]="$EMPTY"
            # Убираем восклицательные знаки вокруг
            local by=$((PLAYER_Y))
            local bx=$((PLAYER_X))
            CURRENT_ROOM[$(((by-1) * ROOM_WIDTH + bx-1))]="$EMPTY"
            CURRENT_ROOM[$(((by-1) * ROOM_WIDTH + bx+1))]="$EMPTY"
            return 3  # Босс
            ;;
        "$EXIT")
            return 4  # Выход
            ;;
        "H")
            CURRENT_ROOM[$idx]="$EMPTY"
            return 5  # Зелье
            ;;
        "$DOOR")
            return 6  # Дверь (переход в другую комнату)
            ;;
    esac
    
    return 0  # Ничего
}

# Движение игрока
move_player() {
    local input=$1
    local new_x=$PLAYER_X
    local new_y=$PLAYER_Y
    
    case "$input" in
        w|W|ц|Ц)  # Вверх
            new_y=$((PLAYER_Y - 1))
            ;;
        s|S|ы|Ы)  # Вниз
            new_y=$((PLAYER_Y + 1))
            ;;
        a|A|ф|Ф)  # Влево
            new_x=$((PLAYER_X - 1))
            ;;
        d|D|в|В)  # Вправо
            new_x=$((PLAYER_X + 1))
            ;;
        *)
            return 0
            ;;
    esac
    
    # Проверяем столкновение
    if check_collision $new_x $new_y; then
        PLAYER_X=$new_x
        PLAYER_Y=$new_y
        return 1
    fi
    
    return 0
}


# Основной цикл исследования комнаты
explore_room() {
    local room_type=$1
    
    generate_room $room_type
    
    local exploring=1
    
    while [ $exploring -eq 1 ]; do
        clear
        show_status
        draw_room
        
        
        read -n1 -s input
        
        case "$input" in
            q|Q|й|Й)
                exploring=0
                return 99  # Выход в меню
                ;;
            e|E|у|У)
                check_interaction
                local interaction=$?
                
                case $interaction in
                    1)  # Сундук
                        return 1
                        ;;
                    2)  # Монстр
                        return 2
                        ;;
                    3)  # Босс
                        return 3
                        ;;
                    4)  # Выход
                        return 4
                        ;;
                    5)  # Зелье
                        POTIONS=$((POTIONS + 1))
                        echo ""
                        echo "🧪 Ты подобрал кофе!"
                        sleep 1
                        ;;
                    6)  # Дверь
                        return 6
                        ;;
                esac
                ;;
            *)
                move_player "$input"
                
                check_interaction
                local auto_interact=$?
                
                if [ $auto_interact -ne 0 ]; then
                    case $auto_interact in
                        1|2|3|4|6)
                            return $auto_interact
                            ;;
                        5)  # Зелье
                            POTIONS=$((POTIONS + 1))
                            echo ""
                            echo "🧪 Ты подобрал кофе!"
                            sleep 1
                            ;;
                    esac
                fi
                ;;
        esac
    done
    
    return 0
}