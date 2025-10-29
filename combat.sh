#!/bin/bash

# Боевая система

fight_monster() {
    local m_hp=$1
    local m_dmg=$2
    local m_name=$3
    
    echo ""
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║              ⚔️  Защита лабы! ⚔️                         ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    
    while [ $m_hp -gt 0 ] && [ $HP -gt 0 ]; do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  👤 Твоё HP: $HP/$MAX_HP"
        echo "  👹 $m_name HP: $m_hp"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "1) Защищать"
        echo "2) Попытаться сбежать"
        if [ $POTIONS -gt 0 ]; then
            echo "3) Использовать кофе (осталось: $POTIONS)"
        fi
        echo ""
        read -p "Твоё действие: " action
        
        case $action in
            1)
                # Атака игрока
                local hit_chance=$((RANDOM % 100))
                if [ $hit_chance -lt 75 ]; then
                    local dmg=$((WEAPON_DMG + RANDOM % 5))
                    m_hp=$((m_hp - dmg))
                    echo ""
                    echo "⚔️  Ты наносишь $dmg убеждения! ($WEAPON)"
                    
                    if [ $m_hp -le 0 ]; then
                        echo ""
                        echo "✅ $m_name убежден!"
                        local gold_reward=$((10 + RANDOM % 20))
                        GOLD=$((GOLD + gold_reward))
                        echo "💰 Ты получаешь $gold_reward золота!"
                        sleep 2
                        return 0
                    fi
                else
                    echo ""
                    echo "❌ Промах! Твой довод не достиг цели!"
                fi
                
                sleep 1
                
                # Атака монстра
                local m_hit=$((RANDOM % 100))
                if [ $m_hit -lt 70 ]; then
                    local m_damage=$((m_dmg + RANDOM % 3))
                    HP=$((HP - m_damage))
                    echo "💥 $m_name наносит тебе $m_damage урона!"
                    
                    if [ $HP -le 0 ]; then
                        echo ""
                        echo "💀 Ты пал на лабе..."
                        sleep 2
                        return 1
                    fi
                else
                    echo "🛡️  $m_name промахивается!"
                fi
                
                sleep 2
                ;;
                
            2)
                # Попытка побега
                local escape=$((RANDOM % 100))
                if [ $escape -lt 40 ]; then
                    echo ""
                    echo "🏃 Тебе удалось сбежать!"
                    sleep 1
                    return 2
                else
                    echo ""
                    echo "❌ Побег не удался!"
                    
                    # Монстр атакует
                    local m_damage=$((m_dmg + RANDOM % 3))
                    HP=$((HP - m_damage))
                    echo "💥 $m_name наносит тебе $m_damage урона!"
                    
                    if [ $HP -le 0 ]; then
                        echo ""
                        echo "💀 Ты пал на лабе..."
                        sleep 2
                        return 1
                    fi
                    
                    sleep 2
                fi
                ;;
                
            3)
                if [ $POTIONS -gt 0 ]; then
                    local heal=$((20 + RANDOM % 15))
                    HP=$((HP + heal))
                    if [ $HP -gt $MAX_HP ]; then
                        HP=$MAX_HP
                    fi
                    POTIONS=$((POTIONS - 1))
                    echo ""
                    echo "🧪 Ты выпиваешь кофе и восстанавливаешь $heal HP!"
                    
                    # Монстр атакует
                    sleep 1
                    local m_damage=$((m_dmg + RANDOM % 3))
                    HP=$((HP - m_damage))
                    echo "💥 $m_name пользуется возможностью и наносит $m_damage урона!"
                    
                    if [ $HP -le 0 ]; then
                        echo ""
                        echo "💀 Ты пал в бою..."
                        sleep 2
                        return 1
                    fi
                    
                    sleep 2
                else
                    echo "У тебя нет кофе!"
                    sleep 1
                fi
                ;;
                
            *)
                echo "Неверный выбор!"
                sleep 1
                ;;
        esac
        
        clear
        echo "╔═══════════════════════════════════════════════════╗"
        echo "║              ⚔️  Защита лабы! ⚔️                 ║"
        echo "╚═══════════════════════════════════════════════════╝"
    done
}