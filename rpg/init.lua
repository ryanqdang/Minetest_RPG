--[[

RPG Mod for Minetest

by Ryan Dang

]]--

-- dofiles
dofile(minetest.get_modpath("rpg").."/ChatCmdBuilder.lua")
dofile(minetest.get_modpath("rpg").."/tool.lua")
dofile(minetest.get_modpath("rpg").."/digging.lua")

-- namespace
rpg = {}
rpg.skills = 	{	"mining",
					"digging",
					"axe",
				}
rpg.skillCount = table.getn(rpg.skills)


-- keeps track of players
player_is_new = {}

-- hud storage and functions
hud = {}
local savedHuds = {}

-- rpg functions

-- adds xp to a player's skill and then calls hud update function
function rpg.addXP(player, skill, xp)
	local skillExists = false
	
	for i=1,rpg.skillCount do
		if skill == rpg.skills[i] then
			skillExists = true
		end
	end
	
	if not skillExists then
		return false
	end

	local p_xp = 	player:get_attribute(skill .. "Exp")
	local p_lvl = 	player:get_attribute(skill .. "Lvl")
	
	local upperSkill = skill:sub(1,1):upper()..skill:sub(2)
	
	minetest.chat_send_player(player:get_player_name(), "You have gained " .. xp .. " " .. upperSkill .. " XP!")
	
	local a_xp = xp
	while (p_xp + a_xp) >= (p_lvl + 1) * 10 do
		a_xp = (p_xp + a_xp) - ((p_lvl + 1) * 10)
		p_lvl = p_lvl + 1
		
		minetest.chat_send_player(player:get_player_name(), "You have gained a " .. upperSkill .. " level!")
		
		p_xp = 0
	end
	p_xp = p_xp + a_xp
	
	player:set_attribute(skill .. "Exp", p_xp)
	player:set_attribute(skill .. "Lvl", p_lvl)
	
	hud.updateStats(player, skill, p_xp, p_lvl)
	
	return true
end

-- hud functions

-- updates the player's skill stats
function hud.updateStats(player, skill, xp, level)
	local name = 	player:get_player_name()	
	local upperSkill = skill:sub(1,1):upper()..skill:sub(2)
	
	player:hud_change	(	savedHuds[name][skill .. "Lvl"], 
							"text",
							upperSkill .. " Level: " .. level
						)
	player:hud_change	(	savedHuds[name][skill .. "Bar"],
							"number",
							math.floor(10 * xp / ((level+1) * 10))
						)
	player:hud_change	(	savedHuds[name][skill .. "Exp"],
							"text",
							"XP: " .. xp .. "/" .. (level+1) * 10
						)
end

function hud.addBarAndLabel(player, skill, level, xp)
	local skillName = ""
	local name = player:get_player_name()
	local barPos = 		{x = -90, y = 58}
	local lvlPos = 		{x = -115, y = 50}
	local expPos = 		{x = -115, y = 67}
	
	for i=1,rpg.skillCount do
		if skill == rpg.skills[i] then
			barPos.y = 		barPos.y + (35 * (i-1))
			lvlPos.y = 		lvlPos.y + (35 * (i-1))
			expPos.y = 		expPos.y + (35 * (i-1))
			skillName = skill:sub(1,1):upper() .. skill:sub(2)
			i = rpg.skillCount
		end
		
	end
	
	savedHuds[name][skill .. "RedBar"] = player:hud_add({
		hud_elem_type = "statbar",
		text = "statRed.png",
		number = 10,
		direction = 0,
		position = {x = 1, y = 0},
		offset = barPos,
	})
	
	savedHuds[name][skill .. "Bar"] = player:hud_add({
		hud_elem_type = "statbar",
		text = "statGreen.png",
		number = math.floor(10 * xp / ((level+1) * 10)),
		direction = 0,
		position = {x = 1, y = 0},
		offset = barPos,
	})
	
	savedHuds[name][skill .. "Lvl"] = player:hud_add({
		hud_elem_type = "text",
		position = {x = 1, y = 0},
		offset = lvlPos,
		text = skillName .. " Level: " .. level,
		alignment = {x = 1, y = 0},
		scale = {x = 100, y = 100},
		number    = 0xFFFFFF,
	})
	savedHuds[name][skill .. "Exp"] = player:hud_add({
		hud_elem_type = "text",
		position = {x = 1, y = 0},
		offset = expPos,
		text = "XP: " .. xp .. "/" .. (level + 1) * 10,
		alignment = {x = 1, y = 0},
		scale = {x = 100, y = 100},
		number    = 0xFFFFFF,
	})
end

-- initializes exp and levels for each player
minetest.register_on_joinplayer(function(player)
	
	-- creates the nested hud array for the player
	local name = player:get_player_name()
	savedHuds[name] = {}
	
	savedHuds[name]["title"] = player:hud_add({
		hud_elem_type = "text",
		position = {x = 1, y = 0},
		offset = {x = -60, y = 30},
		text = "Stats",
		alignment = 0,
		scale = {x = 100, y = 100},
		number    = 0xFFFFFF,
	})

	local levels  = {}
	local exps = {}
	
	-- if player is new, then he is assigned new values for levels and xp
	-- then the hud is initialized
	for i=1,rpg.skillCount do
		levels[i] = player:get_attribute(rpg.skills[i] .. "Lvl")
		exps[i] = 	player:get_attribute(rpg.skills[i] .. "Exp")
		
		if levels[i] == nil then
			player:set_attribute(rpg.skills[i] .. "Lvl", 0)
			levels[i] = 0
		end
		if exps[i] == nil then
			player:set_attribute(rpg.skills[i] .. "Exp", 0)
			exps[i] = 0
		end
		
		hud.addBarAndLabel(player, rpg.skills[i], levels[i], exps[i])
	end
	 
	minetest.chat_send_player(player:get_player_name(), "To see help with the RPG mod, use /rpg help.")
end)

-- rpg privileges
minetest.register_privilege("rpg_cheat", {
    description = "Can use cheat commands for rpg",
    give_to_singleplayer = false
})

-- rpg commands using ChatCmdBuilder
ChatCmdBuilder.new("rpg", function(cmd)
	cmd:sub("help", function(name)
		return true,	"Use tools to increase exp and gain levels. Unlock skills and use them with right-click with a tool equipped.\n" ..
						"Pickaxes can turn stone into ores and sometimes even blocks of ore.\n" ..
						"Axes can cut down entire trees.\n" ..
						"Shovels can dig wide open areas."
	end)
	
	-- adds xp to player's skill
	-- skill name is not case sensitive
	cmd:sub("xp :skill:word :xp:int", function(name, skill, xp)
		local player = minetest.get_player_by_name(name)
		
		skill = skill:lower()

		if player then
			if minetest.check_player_privs(name, {rpg_cheat = true}) then
				if rpg.addXP(player, skill, xp) then
					return true
				else
					return false,	"Invalid skill name."
				end
			else
				return false,	"Player does not have the rpg_cheat privilege."
			end
		else
			return false,	"Error. Player is currently not in game."
		end
	
	end)
	
	cmd:sub("reset", function(name)
		local player = minetest.get_player_by_name(name)
		
		if player then	
			if minetest.check_player_privs(name, {rpg_cheat = true}) then
				for i=1,rpg.skillCount do
					player:set_attribute(rpg.skills[i] .. "Exp", 0)
					player:set_attribute(rpg.skills[i] .. "Lvl", 0)
					hud.updateStats(player, rpg.skills[i], 0, 0)
				end
				return true,	"Successfully reset all stats."
			else
				return false, 	"Player does not have the rpg_cheat privilege."
			end
		else
			return false,	"Error. Player is currently not in game."
		end
	end)
end, {
	description = "RPG commands",
	privs = {
		interact = true
	}
})

