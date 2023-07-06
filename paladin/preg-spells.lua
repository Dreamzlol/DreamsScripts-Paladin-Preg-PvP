local Unlocker, awful, dreamsscripts = ...
local preg = dreamsscripts.paladin.preg
local Spell = awful.Spell
local target = awful.target
local focus = awful.focus
local player = awful.player

awful.Populate({
    -- Denfensives
    turn_evil               = Spell(10326, { effect = "magic" }),
    divine_shield           = Spell(642, { ignoreCasting = true, ignoreControl = true }),
    divine_sacrifice        = Spell(64205, { beneficial = true }),
    divine_protection       = Spell(498, { beneficial = true }),
    hand_of_sacrifice       = Spell(6940, { beneficial = true }),
    flash_of_light          = Spell(48785, { beneficial = true }),
    hand_of_freedom         = Spell(1044, { beneficial = true, ignoreControl = true }),
    cleanse                 = Spell(4987, { beneficial = true }),
    hand_of_protection      = Spell(10278, { ignoreControl = true }),
    hammer_of_justice       = Spell(5588, { cc = "stun", effect = "magic", ignoreCasting = true }),
    repentance              = Spell(20066, { cc = "stun", effect = "magic", ignoreCasting = true }),
    hand_of_salvation       = Spell(1038, { beneficial = true }),

    -- Damage
    auto_attack             = Spell(6603),
    judgement_of_light      = Spell(20271),
    judgement_of_justice    = Spell(53407),
    holy_wrath              = Spell(48817),
    hammer_of_wrath         = Spell(48806),
    shield_of_righteousness = Spell(61411),
    consecration            = Spell(48819),
    exorcism                = Spell(48801),

    -- Buffs
    seal_of_vengeance       = Spell(31801, { beneficial = true }),
    blessing_of_kings       = Spell(20217, { beneficial = true }),
    avenging_wrath          = Spell(31884, { beneficial = true }),
    righteous_fury          = Spell(25780, { beneficial = true }),
    sacred_shield           = Spell(53601, { beneficial = true }),
    retribution_aura        = Spell(54043, { beneficial = true }),
    divine_plea             = Spell(54428, { beneficial = true }),

}, preg, getfenv(1))

local SpellStopCasting = awful.unlock("SpellStopCasting")

local function unitFilter(obj)
    return obj.exists and obj.los and not obj.dead
end

local preemptive = {
    ["Repentance"] = true,
    ["Blind"] = true,
    ["Gouge"] = true,
    ["Scatter Shot"] = true,
    ["Psychic Scream"] = true,
    ["Polymorph"] = true,
    ["Seduction"] = true,
    ["Hex"] = true
}

awful.onEvent(function(info, event, source, dest)
    local friend = awful.friends.within(40).filter(unitFilter).lowest
    if event == "SPELL_CAST_SUCCESS" then
        if not source.enemy then return end
        if not dest.isUnit(player) then return end
        if not friend then return end

        local _, spellName = select(12, unpack(info))
        if preemptive[spellName] then
            SpellStopCasting()
            HandOfSacrifice:Cast(friend)
            return
        end
    end
end)

auto_attack:Callback(function(spell)
    awful.totems.stomp(function(totem, uptime)
        if uptime < 0.3 then return end
        if totem.distance >= 5 then return end

        if spell:Cast(totem) then
            awful.alert("Destroying " .. totem.name, spell.id)
            return
        end
    end)

    if target.bcc and spell.current then
        StopAttack()
    elseif target.enemy and not target.bcc and not spell.current then
        StartAttack()
    end
end)

hand_of_freedom:Callback(function(spell)
    awful.fullGroup.within(30).filter(unitFilter).loop(function(friend)
        if not friend then return end

        if friend.stun or friend.slowed or friend.rooted then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

divine_shield:Callback(function(spell)
    if not player.combat then return end

    if player.hp < 40 then
        if spell:Cast(player) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

avenging_wrath:Callback(function(spell)
    if not player.combat then return end

    if not player.cooldown("Divine Shield") == 0 and target.hp < 60 then
        if spell:Cast() then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

hand_of_protection:Callback(function(spell)
    awful.friends.within(40).filter(unitFilter).loop(function(friend)
        if not friend then return end

        local total, melee, ranged, cooldowns = friend.v2attackers()
        if melee >= 1 and friend.hp < 40 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        elseif friend.disarm then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        elseif friend.disorient and friend.disorientRemains > 5 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

divine_protection:Callback(function(spell)
    if player.cooldown("Divine Shield") == 0 then return end
    if player.cooldown("Avenging Wrath") == 0 then return end

    if player.hp < 60 then
        if spell:Cast(player) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

divine_sacrifice:Callback("defensive", function(spell)
    local friend = awful.fullGroup.within(30).filter(unitFilter).lowest

    if not friend then return end
    if not friend.buff() then return end
    if friend.buff("Hand of Sacrifice") then return end
    if friend.buff("Hand of Salvation") then return end

    if friend.hp < 60 then
        if spell:Cast(friend) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

local ccSpells = {
    ["Polymorph"] = true,
    ["Seduction"] = true,
    ["Fear"] = true,
    ["Hex"] = true
}

divine_sacrifice:Callback("cc", function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.castTarget.isUnit(player) and ccSpells[enemy.casting] and enemy.castPct > 60 then
            SpellStopCasting()
            spell:Cast()
            return
        else
            if ccSpells[enemy.casting] and player.castRemains <= enemy.castRemains then
                SpellStopCasting()
            end
            if ccSpells[enemy.casting] and player.castRemains >= enemy.castRemains then
                SpellStopCasting()
            end
            if ccSpells[enemy.casting] and player.castRemains >= enemy.castRemains then
                SpellStopCasting()
            end
        end
    end)
end)

divine_sacrifice:Callback("seduction", function(spell)
    awful.enemyPets.loop(function(pet)
        if pet.castTarget.isUnit(player) and ccSpells[pet.casting] and pet.castPct > 60 then
            SpellStopCasting()
            spell:Cast()
            return
        else
            if ccSpells[pet.casting] and player.gcdRemains <= pet.castRemains then
                SpellStopCasting()
            end
            if ccSpells[pet.casting] and player.gcdRemains >= pet.castRemains then
                SpellStopCasting()
            end
            if ccSpells[pet.casting] and player.gcdRemains >= pet.castRemains then
                SpellStopCasting()
            end
        end
    end)
end)

hand_of_sacrifice:Callback("defensive", function(spell)
    local friend = awful.friends.within(40).filter(unitFilter).lowest

    if not friend then return end
    if not friend.buff then return end
    if friend.buff("Divine Sacrifice") then return end
    if friend.buff("Hand of Salvation") then return end

    if friend.hp < 70 then
        if spell:Cast(friend) then
            awful.alert(spell.name, spell.id)
        end
    end
end)

hand_of_salvation:Callback(function(spell)
    local friend = awful.fullGroup.within(40).filter(unitFilter).lowest

    if not friend then return end
    if not friend.buff then return end
    if friend.buff("Divine Sacrifice") then return end
    if friend.buff("Hand of Sacrifice") then return end

    if friend.hp < 60 then
        if spell:Cast(friend) then
            awful.alert(spell.name, spell.id)
        end
    end
end)

hand_of_sacrifice:Callback("cc", function(spell)
    local friend = awful.friends.within(40).filter(unitFilter).lowest

    awful.enemies.loop(function(enemy)
        if enemy.castTarget.isUnit(player) and ccSpells[enemy.casting] and enemy.castPct > 60 then
            SpellStopCasting()
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        else
            if ccSpells[enemy.casting] and (player.castRemains <= enemy.castRemains or player.castRemains >= enemy.castRemains or player.channelRemains >= enemy.castRemains) then
                SpellStopCasting()
            end
        end
    end)
end)

hand_of_sacrifice:Callback("seduction", function(spell)
    local friend = awful.friends.within(40).filter(unitFilter).lowest

    awful.enemyPets.loop(function(pet)
        if pet.castTarget.isUnit(player) and ccSpells[pet.casting] and pet.castPct > 60 then
            SpellStopCasting()
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        else
            if ccSpells[pet.casting] and (player.castRemains <= pet.castRemains or player.castRemains >= pet.castRemains or player.channelRemains >= pet.castRemains) then
                SpellStopCasting()
            end
        end
    end)
end)

flash_of_light:Callback(function(spell)
    local friend = awful.fullGroup.within(40).filter(unitFilter).lowest
    if not friend then return end

    if friend.hp < 80 then
        if spell:Cast(friend) then
            awful.alert(spell.name, spell.id)
        end
    end
end)

local dispelSpells = {
    -- Priest
    ["Psychic Horror"] = true,
    ["Psychic Scream"] = true,
    ["Silence"] = true,

    -- Warlock
    ["Howl of Terror"] = true,
    ["Seduction"] = true,
    ["Fear"] = true,
    ["Immolate"] = true,
    ["Shadowflame"] = true,
    ["Death Coil"] = true,
    ["Shadowfury"] = true,

    -- Shaman
    ["Earthbind"] = true,
    ["Earthgrab"] = true,
    ["Flame Shock"] = true,
    ["Frost Shock"] = true,

    -- Mage
    ["Deep Freeze"] = true,
    ["Cone of Cold"] = true,
    ["Frost Nova"] = true,
    ["Polymorph"] = true,
    ["Frostbolt"] = true,
    ["Dragon's Breath"] = true,
    ["Freeze"] = true,
    ["Frostbite"] = true,
    ["Slow"] = true,
    ["Shattered Barrier"] = true,

    -- Hunter
    ["Pin"] = true,
    ["Silencing Shot"] = true,
    ["Freezing Arrow Effect"] = true,
    ["Freezing Trap Effect"] = true,
    ["Viper Sting"] = true,
    ["Entrapment"] = true,

    -- Druid
    ["Faerie Fire"] = true,
    ["Entangling Roots"] = true,
    ["Hibernate"] = true,

    -- Deathknight
    ["Chains of Ice"] = true,
    ["Hungering Cold"] = true,
    ["Strangulate"] = true,

    -- Paladin
    ["Turn Evil"] = true,
    ["Repentance"] = true,
    ["Hammer of Justice"] = true,

    -- Rogue
    ["Wound Poison"] = true,
    ["Crippling Poison"] = true,
}

local dispelBlacklist = {
    ["Unstable Affliction"] = true
}

cleanse:Callback(function(spell)
    awful.fullGroup.within(40).filter(unitFilter).loop(function(friend)
        if not friend then return end
        if not friend.debuffs then return end
        if friend.hp < 40 then return end

        for _, debuff in ipairs(friend.debuffs) do
            local name, _, _, type = unpack(debuff)

            if dispelSpells[name] and not dispelBlacklist[name] then
                if spell:Cast(friend) then
                    awful.alert(spell.name, spell.id)
                    return
                end
            end
        end
    end)
end)

sacred_shield:Callback(function(spell)
    if player.used("Sacred Shield", 5) then return end

    local friend = awful.fullGroup.within(40).filter(unitFilter).lowest
    if friend.hp < 80 and not friend.buff("Sacred Shield") then
        if spell:Cast(friend) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

judgement_of_light:Callback(function(spell)
    if not target.enemy then return end
    if target.dead then return end

    if target.exists and not target.bcc then
        if spell:Cast(target) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

hammer_of_wrath:Callback(function(spell)
    local enemy = awful.enemies.within(30).filter(unitFilter).lowest
    if not enemy then return end
    if enemy.dead then return end
    if enemy.bcc then return end
    if not enemy.combat then return end

    if enemy.hp < 20 then
        if spell:Cast(enemy, { face = true }) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

exorcism:Callback(function(spell)
    if not target.enemy then return end
    if target.dead then return end
    if target.bcc then return end

    if target.exists and player.buff("The Art of War") then
        if spell:Cast(target) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

shield_of_righteousness:Callback(function(spell)
    if not target.enemy then return end
    if target.dead then return end
    if target.bcc then return end

    if target.exists then
        if spell:Cast(target) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

consecration:Callback(function(spell)
    if not target.enemy then return end
    if target.dead then return end

    if target.stealth then
        if spell:Cast() then
            awful.alert(spell.name, spell.id)
        end
    end
end)

divine_plea:Callback(function(spell)
    if player.manaPct < 20 then
        if spell:Cast() then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

hammer_of_justice:Callback(function(spell)
    awful.enemies.within(10).filter(unitFilter).loop(function(enemy)
        if not enemy then return end
        if enemy.bcc then return end

        if enemy.stealth or player.hp < 20 then
            if spell:Cast(enemy) then
                awful.alert(spell.name .. "(Stealth)", spell.id)
                return
            end
        end

        if target.hp < 60 then
            if spell:Cast(target) then
                awful.alert(spell.name .. "(Low HP)", spell.id)
                return
            end
        end
    end)
end)

local interruptCast = {
    -- Mage
    ["Polymorph"] = true,

    -- Warlock
    ["Seduction"] = true,
    ["Fear"] = true,
    ["Chaos Bolt"] = true,

    -- Paladin
    ["Holy Light"] = true,
    ["Flash of Light"] = true,

    -- Priest
    ["Flash Heal"] = true,
    ["Binding Heal"] = true,
    ["Greater Heal"] = true,
    ["Penance"] = true,
    ["Prayer of Healing"] = true,
    ["Vampiric Touch"] = true,

    -- Shaman
    ["Healing Wave"] = true,
    ["Lesser Healing Wave"] = true,
    ["Chain Heal"] = true,

    -- Druid
    ["Regrowth"] = true,
    ["Rejuvenation"] = true,
    ["Healing Touch"] = true,
    ["Nourish"] = true,
    ["Cyclone"] = true
}

local interruptChannel = {
    -- Priest
    ["Penance"] = true,
    ["Tranquility"] = true
}

repentance:Callback(function(spell)
    awful.enemies.within(40).filter(unitFilter).loop(function(unit)
        if not unit then return end
        if unit.bcc then return end

        if interruptCast[unit.cast] then
            SpellStopCasting()
            if spell:Cast(unit) then
                awful.alert(spell.name, spell.id)
                return
            end
        elseif interruptChannel[unit.channel] then
            SpellStopCasting()
            if spell:Cast(unit) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

turn_evil:Callback("gargoyle", function(spell)
    awful.enemyPets.within(20).filter(unitFilter).loop(function(pet)
        if not pet then return end
        if pet.bcc then return end

        if pet.id == 27829 and not (pet.debuff("Turn Evil") or pet.debuff("Holy Wrath")) then
            if spell:Cast(pet) then
                awful.alert(spell.name .. "(Gargoyle)", spell.id)
                return
            end
        end
    end)
end)

turn_evil:Callback("lichborne", function(spell)
    awful.enemies.within(20).filter(unitFilter).loop(function(enemy)
        if not enemy then return end
        if enemy.bcc then return end

        if enemy.buff("Lichborne") and not (enemy.debuff("Turn Evil") or enemy.debuff("Holy Wrath"))  then
            if spell:Cast(enemy) then
                awful.alert(spell.name .. "(Lichborne)", spell.id)
                return
            end
        end
    end)
end)

holy_wrath:Callback("gargoyle", function(spell)
    awful.enemyPets.within(10).filter(unitFilter).loop(function(pet)
        if player.hasGlyph("Turn Evil") then return end
        if not pet then return end
        if pet.bcc then return end

        if pet.id == 27829 and not (pet.debuff("Turn Evil") or pet.debuff("Holy Wrath")) then
            if spell:Cast(pet) then
                awful.alert(spell.name .. "(Gargoyle)", spell.id)
                return
            end
        end
    end)
end)

holy_wrath:Callback("lichborne", function(spell)
    awful.enemies.within(10).filter(unitFilter).loop(function(enemy)
        if player.hasGlyph("Turn Evil") then return end
        if not enemy then return end
        if enemy.bcc then return end

        if enemy.buff("Lichborne") and not (enemy.debuff("Turn Evil") or enemy.debuff("Holy Wrath")) then
            if spell:Cast(enemy) then
                awful.alert(spell.name .. "(Lichborne)", spell.id)
                return
            end
        end
    end)
end)

righteous_fury:Callback(function(spell)
    if player.buff("Righteous Fury") then return end

    if not player.used("Righteous Fury", 10) then
        if spell:Cast(player) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

blessing_of_kings:Callback(function(spell)
    awful.fullGroup.within(30).filter(unitFilter).loop(function(friend)
        if not friend then return end
        if friend.buff("Blessing of Kings") then return end
        if friend.buff("Greater Blessing of Kings") then return end

        if player.manaPct > 40 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

seal_of_vengeance:Callback(function(spell)
    if not player.buff("Seal of Vengeance") then
        if spell:Cast(player) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

retribution_aura:Callback(function(spell)
    if not player.buff("Retribution Aura", player) then
        if spell:Cast() then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)