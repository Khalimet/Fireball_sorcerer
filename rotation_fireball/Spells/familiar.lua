local my_utility = require("my_utility/my_utility")

-- Define Familiar menu elements
local menu_elements_sorc_base = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_familiar"))
}

-- Render Familiar options in the menu
local function menu()
    if menu_elements_sorc_base.tree_tab:push("Familiar Summon") then
        menu_elements_sorc_base.main_boolean:render("Enable Familiar Summon", "")
        menu_elements_sorc_base.tree_tab:pop()
    end 
end

-- Define Familiar spell ID
local spell_id_familiar_summon = 1627075  -- Replace with the actual Familiar spell ID
local next_time_allowed_cast = 0.0

-- Logic for casting Familiar
local function logics()
    -- Check if Familiar is enabled and allowed to cast
    local menu_boolean = menu_elements_sorc_base.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean,
                next_time_allowed_cast,
                spell_id_familiar_summon)

    if not is_logic_allowed then
        return false
    end

    -- Cast Familiar on self
    if cast_spell.self(spell_id_familiar_summon, 0.0) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + 5.5  -- Cast Familiar every 5-6 seconds

        -- Update the last spell ID to track that Familiar was cast
        last_spell_id = spell_id_familiar_summon

        console.print("Sorcerer Plugin, Casted Familiar")
        return true
    end

    return false
end

return {
    menu = menu,
    logics = logics
}
