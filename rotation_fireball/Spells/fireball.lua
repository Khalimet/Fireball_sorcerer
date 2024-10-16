local my_utility = require("my_utility/my_utility")

-- Define Fireball menu elements
local fireball_menu_elements = {
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "fire_ball_main_boolean")),
}

-- Render Fireball options in the menu
local function menu()
    if fireball_menu_elements.tree_tab:push("Fireball") then
        fireball_menu_elements.main_boolean:render("Enable Spell", "")
        fireball_menu_elements.tree_tab:pop()
    end
end

-- Define Fireball spell ID and data
local spell_id_fireball = 165023
local fireball_spell_data = spell_data:new(
    0.7,                       -- radius
    12.0,                      -- range
    1.6,                       -- cast_delay
    2.0,                       -- projectile_speed
    true,                      -- has_collision
    spell_id_fireball,          -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    -- targeting_type
)

local next_time_allowed_cast = 0.0

-- Logic for casting Fireball
local function logics(target)
    -- Check if Fireball is enabled and allowed to cast
    local menu_boolean = fireball_menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_fireball)

    if not is_logic_allowed then
        return false
    end

    -- Get the local player and their current mana
    local player_local = get_local_player()
    local current_mana = player_local:get_primary_resource_current()
    local max_mana = player_local:get_primary_resource_max()
    local mana_percentage = current_mana / max_mana

    -- Mana check (requires at least 80% mana to cast Fireball)
    if mana_percentage < 0.8 then
        return false
    end  

    -- Cast Fireball at the target if it's a valid enemy
    if cast_spell.target(target, fireball_spell_data, false) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time

        -- Update the last spell ID to track that Fireball was cast
        last_spell_id = spell_id_fireball

        console.print("Sorcerer Plugin, Casted Fireball")
        return true
    end

    return false
end

return {
    menu = menu,
    logics = logics,   
}
