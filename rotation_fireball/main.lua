-- Initialize variables
local fireball_spell_id = 165023  -- Fireball spell ID
local fireball_casted = false     -- Flag to check if Fireball has been cast at least once
local last_familiar_cast_time = 0 -- Stores the time when Familiar was last cast
local familiar_cooldown = 6.0     -- Cooldown for Familiar (6 seconds)
-- Get the local player object
local local_player = get_local_player();
-- If the local player is not found, exit the script
if local_player == nil then
    return
end

-- Get the character class ID of the local player
local character_id = local_player:get_character_class_id();
-- Check if the character is a sorcerer (assuming 0 is the ID for sorcerer)
local is_sorc = character_id == 0;
-- If the character is not a sorcerer, exit the script
if not is_sorc then
    return
end;

-- Require the menu module
local menu = require("menu");

-- Load various spell modules into a table
local spells =
{
    teleport_ench           = require("spells/teleport_ench"),
    teleport                = require("spells/teleport"),
    flame_shield            = require("spells/flame_shield"),           
    ice_blade               = require("spells/ice_blade"),               
    fireball                = require("spells/fireball"),
    familiar                = require("spells/familiar"),
    ice_armor               = require("spells/ice_armor")
}

-- Function to render the menu
on_render_menu (function ()
    -- Create the main menu tree for the sorcerer
    if not menu.main_tree:push("Fireball Sorcerer") then
        return;
    end;

    -- If the plugin is disabled, close the menu tree and return
    if menu.main_boolean:get() == false then
        menu.main_tree:pop();
        return;
    end;
    
    -- Render each spell's menu options
    spells.teleport_ench.menu();
    spells.fireball.menu();
    spells.flame_shield.menu();
    spells.teleport.menu();
    spells.ice_armor.menu();
    spells.familiar.menu();
    spells.ice_blade.menu();
    
    -- Close the main menu tree
    menu.main_tree:pop();
end)

-- Initialize variables for spell cooldown and casting times
local can_move = 0.0;
local cast_end_time = 0.0;

-- Require utility and target selector modules
local my_utility = require("my_utility/my_utility");
local my_target_selector = require("my_utility/my_target_selector");

-- Function that runs on each game update
on_update(function ()
    -- Get the local player object
    local local_player = get_local_player();
    -- If the local player is not found, exit the function
    if not local_player then
        return;
    end
    
    -- Check if the plugin is enabled
    if menu.main_boolean:get() == false then
        -- If plugin is disabled, do not perform any logic
        return;
    end;

    -- Get the current time since the script was injected
    local current_time = get_time_since_inject()
    -- If the current time is less than the spell cast end time, exit
    if current_time < cast_end_time then
        return;
    end;

      -- Check if Fireball was cast
      local last_spell_id = local_player:get_active_spell_id()
      if last_spell_id == fireball_spell_id then
          fireball_casted = true
      end

    -- Check if any action is allowed (utility function)
    if not my_utility.is_action_allowed() then
        return;
    end  

    -- Define screen range and player position for target selection
    local screen_range = 12.0;
    local player_position = get_player_position();

    -- Collision and angle settings for target selection
    local collision_table = { true, 1.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    -- Get the list of potential targets within range
    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    -- Select the best target based on the player's position and the entity list
    local target_selector_data = my_target_selector.get_target_selector_data(
        player_position, 
        entity_list);

    -- Check if there are enemies nearby
    local enemies_nearby = target_selector_data.is_valid or 
        (best_target_position and best_target_position:squared_dist_to_ignore_z(player_position) > (8 * 8));

    -- Teleport enchantment logic
    if spells.teleport_ench.menu_elements_teleport_ench.enchant_jmr_logic:get() then
        if local_player:is_spell_ready(959728) then
            if current_orb_mode == orb_mode.none then
                return;
            end
            if current_orb_mode ~= orb_mode.none then
                cast_spell.position(959728, valid_height_cursor_pos, 0.0);
                return;
            end
        end
    end

    -- If there are no valid targets, exit the function
    if not target_selector_data.is_valid then
        return;
    end

    -- Determine maximum range based on autoplay status
    local is_auto_play_active = auto_play.is_active();
    local max_range = 12.0;
    if is_auto_play_active then
        max_range = 12.0;
    end

    -- Get the closest enemy target
    local best_target = target_selector_data.closest_unit;

    -- Check for elite enemies
    if target_selector_data.has_elite then
        local unit = target_selector_data.closest_elite;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end        
    end

    -- Check for boss enemies
    if target_selector_data.has_boss then
        local unit = target_selector_data.closest_boss;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end

    -- Check for champion enemies
    if target_selector_data.has_champion then
        local unit = target_selector_data.closest_champion;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end   

    -- If there is no best target, exit the function
    if not best_target then
        return;
    end

    -- Get the best target's position
    local best_target_position = best_target:get_position();
    local distance_sqr = best_target_position:squared_dist_to_ignore_z(player_position);

    -- Check if the target is within maximum range
    if distance_sqr > (max_range * max_range) then            
        best_target = target_selector_data.closest_unit;
        local closer_pos = best_target:get_position();
        local distance_sqr_2 = closer_pos:squared_dist_to_ignore_z(player_position);
        if distance_sqr_2 > (max_range * max_range) then
            return;
        end
    end

-- Spell logic execution begins here

if spells.flame_shield.logics() then
    cast_end_time = current_time;
    return;
end;

if spells.ice_armor.logics() then
    cast_end_time = current_time + 0.2;
    return;
end;

if spells.teleport_ench.logics(best_target) then
    cast_end_time = current_time;
    return;
end;

if spells.teleport.logics(entity_list, target_selector_data, best_target) then
    cast_end_time = current_time;
    return;
end;

if spells.ice_blade.logics(best_target) then
    cast_end_time = current_time + 0.3;
    return;
end;

-- Check if Familiar should be cast (give Familiar priority over Fireball if it's ready)
if fireball_casted and (current_time > (last_familiar_cast_time + familiar_cooldown)) then
    if spells.familiar.logics() then
        console.print("Familiar cast successfully.")
        last_familiar_cast_time = current_time;
        cast_end_time = current_time + 0.3; -- Set a small delay to prevent rapid casting
        return;
    end;
end;

-- Only cast Fireball if Familiar isn't ready to be cast
if spells.fireball.logics(best_target) then
    cast_end_time = current_time;
    return;
end;

-- Autoplay logic to engage distant monsters
    local move_timer = get_time_since_inject()
    if move_timer < can_move then
        return;
    end;

    -- Check if autoplay is enabled and move to a closer target
    local is_auto_play = my_utility.is_auto_play_enabled();
    if is_auto_play then
        local player_position = local_player:get_position();
        local is_dangerous_evade_position = evade.is_dangerous_position(player_position);
        if not is_dangerous_evade_position then
            local closer_target = target_selector.get_target_closer(player_position, 15.0);
            if closer_target then
                local closer_target_position = closer_target:get_position();
                local move_pos = closer_target_position:get_extended(player_position, 4.0);
                if pathfinder.move_to_cpathfinder(move_pos) then
                    can_move = move_timer + 1.5;
                end
            end
        end
    end
end)

-- Flags for drawing circles around player and enemies
local draw_player_circle = false;
local draw_enemy_circles = false;

-- Function to handle rendering on the screen
on_render(function ()
    -- Check if the plugin is enabled
    if menu.main_boolean:get() == false then
        return;
    end;

    -- Get the local player object
    local local_player = get_local_player();
    if not local_player then
        return;
    end

    -- Get the player's screen position
    local player_position = local_player:get_position();
    local player_screen_position = graphics.w2s(player_position);
    if player_screen_position:is_zero() then
        return;
    end

    -- Draw circles around the player and enemies if the flags are set
    if draw_player_circle then
        graphics.circle_3d(player_position, 8, color_white(85), 3.5, 144)
        graphics.circle_3d(player_position, 6, color_white(85), 2.5, 144)
    end    

    if draw_enemy_circles then
        local enemies = actors_manager.get_enemy_npcs()

        for i, obj in ipairs(enemies) do
            local position = obj:get_position();
            local distance_sqr = position:squared_dist_to_ignore_z(player_position);
            local is_close = distance_sqr < (8.0 * 8.0);
            graphics.circle_3d(position, 1, color_white(100));

            local future_position = prediction.get_future_unit_position(obj, 0.4);
            graphics.circle_3d(future_position, 0.5, color_yellow(100));
        end;
    end

    -- Glow target rendering for selected targets
    local screen_range = 12.0;
    local player_position = get_player_position();

    local collision_table = { true, 1.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    local target_selector_data = my_target_selector.get_target_selector_data(
        player_position, 
        entity_list);

    if not target_selector_data.is_valid then
        return;
    end

    local is_auto_play_active = auto_play.is_active();
    local max_range = 12.0;
    if is_auto_play_active then
        max_range = 12.0;
    end

    local best_target = target_selector_data.closest_unit;

    if target_selector_data.has_elite then
        local unit = target_selector_data.closest_elite;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end        
    end

    if target_selector_data.has_boss then
        local unit = target_selector_data.closest_boss;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end

    if target_selector_data.has_champion then
        local unit = target_selector_data.closest_champion;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end   

    if not best_target then
        return;
    end

    -- If the best target is an enemy, draw a line and circle around it
    if best_target and best_target:is_enemy() then
        local glow_target_position = best_target:get_position();
        local glow_target_position_2d = graphics.w2s(glow_target_position);
        graphics.line(glow_target_position_2d, player_screen_position, color_red(180), 2.5)
        graphics.circle_3d(glow_target_position, 0.80, color_red(200), 2.0);
    end
end);

-- Print to console that the Lua Plugin for Sorcerer Base is loaded
console.print("Lua Plugin - Fireball Sorcerer - Version 1.5");
