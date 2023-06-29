local Unlocker, awful, dreamsscripts = ...
local preg = dreamsscripts.paladin.preg
local player = awful.player

if awful.player.class2 ~= "PALADIN" then return end

awful.print("|cffFFFFFFDreams{ |cff00B5FFScripts |cffFFFFFF} - Preg PvP Loaded!")
awful.print("|cffFFFFFFDreams{ |cff00B5FFScripts |cffFFFFFF} - Version: 1.0.3")

preg:Init(function()

	if player.mounted then return end
    if player.buff("Drink") then return end

    -- OnEvent
    hand_of_sacrifice("cc")
    divine_sacrifice("cc")
    hand_of_sacrifice("seduction")
    divine_sacrifice("seduction")

    -- Defensives
    divine_shield()
    divine_protection()
    hand_of_salvation()
    hand_of_sacrifice("defensive")
    divine_sacrifice("defensive")

    -- Dispels
    hand_of_freedom()
    cleanse()

    -- Heals / Support
    flash_of_light()
    sacred_shield()
    divine_plea()
    auto_attack()

    -- Interrupts / CC
    hammer_of_justice()
    repentance()
    holy_wrath("gargoyle")
    turn_evil("gargoyle")
    holy_wrath("lichborne")
    turn_evil("lichborne")

    -- Damage
    avenging_wrath()
    exorcism()
    hammer_of_wrath()
    judgement_of_light()
    shield_of_righteousness()
    consecration()

    -- Buffs
    seal_of_vengeance()
    righteous_fury()
    retribution_aura()
    blessing_of_kings()

end, 0.05)
