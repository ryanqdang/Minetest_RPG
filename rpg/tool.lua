--[[

This file adds skills to the tools for the RPG mod

Axes: Timber
Right-click trees with an axe to chop down the entire tree.
Higher skill level grants faster cooldowns.

Pickaxes: Miner's Luck
Right-click stone to turn it into a random ore.
Higher skill level grants better ores and faster cooldowns.

by Ryan Dang

]]--



rpg_tools = {}
rpg_tools.axeCDStart = 		minetest.get_us_time()
rpg_tools.miningCDStart = 	minetest.get_us_time()
rpg_tools.diggingCDStart =	minetest.get_us_time()



-- returns the leaves that accompany the tree type
local function leaves(name)
	if name == "default:tree" then
		return "default:leaves"
	elseif name == "default:jungletree" then
		return "default:jungleleaves"
	elseif name == "default:pine_tree" then
		return "default:pine_needles"
	elseif name == "default:acacia_tree" then
		return "default:acacia_leaves"
	elseif name == "default:aspen_tree" then
		return "default:aspen_leaves"
	end
end

-- returns the tree that accompany the leaves
local function trees(name)
	if name == "default:leaves" then
		return "default:tree"
	elseif name == "default:jungleleaves" then
		return "default:jungletree"
	elseif name == "default:pine_needles" then
		return "default:pine_tree"
	elseif name == "default:acacia_leaves" then
		return "default:acacia_tree"
	elseif name == "default:aspen_leaves" then
		return "default:aspen_tree"
	end	
end

-- recursive function to cut a tree upwards
-- returns a count of the number of pieces of wood cut and the leaves cut
local function cutWood(pos, count)
	local node = minetest.get_node(pos)
	local name = node.name
	
	if string.find(name, "tree") then
		count.wood = count.wood + 1
	else
		count.leaves = count.leaves + 1
	end
	
	minetest.dig_node(pos)
	
	local westNode = 	minetest.get_node({x = pos.x - 1, y = pos.y, z = pos.z})
	if (westNode.name == name) or (westNode.name == leaves(name)) or (westNode.name == trees(name)) then
		count = cutWood({x = pos.x - 1, y = pos.y, z = pos.z}, {wood = count.wood, leaves = count.leaves})
	end
	
	local eastNode =	minetest.get_node({x = pos.x + 1, y = pos.y, z = pos.z})
	if (eastNode.name == name) or (eastNode.name == leaves(name)) or (eastNode.name == trees(name)) then
		count = cutWood({x = pos.x + 1, y = pos.y, z = pos.z}, {wood = count.wood, leaves = count.leaves})
	end
	
	local northNode = 	minetest.get_node({x = pos.x, y = pos.y, z = pos.z + 1})
	if (northNode.name == name) or (northNode.name == leaves(name) or (northNode.name == trees(name))) then
		count = cutWood({x = pos.x, y = pos.y, z = pos.z + 1}, {wood = count.wood, leaves = count.leaves})
	end
	
	local southNode = 	minetest.get_node({x = pos.x, y = pos.y, z = pos.z - 1})
	if (southNode.name == name) or (southNode.name == leaves(name)) or (southNode.name == trees(name)) then
		count = cutWood({x = pos.x, y = pos.y, z = pos.z - 1}, {wood = count.wood, leaves = count.leaves})
	end
	
	local upNode = 		minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
	if (upNode.name == name) or (upNode.name == leaves(name)) or (upNode.name == trees(name)) then
		count = cutWood({x = pos.x, y = pos.y + 1, z = pos.z}, {wood = count.wood, leaves = count.leaves})
	end
	
	return count
end

-- axe skill
-- chops down an entire tree
local function axeRightclick(itemStack, player, pointed_thing)
	if pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local block = minetest.get_node(pos)
		if string.find(block.name, "tree") then
		
			local axeLvl = player:get_attribute("axeLvl")
			
			-- checks if axe level is eligible to cut down entire trees
			if tonumber(axeLvl) == 0 then
				minetest.chat_send_player(player:get_player_name(), "You must have at least 1 Axe level to use Timber.")
			else
				-- sets a timer for the cooldown of the skill
				rpg_tools.axeCDEnd = minetest.get_us_time()
				local timeElapsed = rpg_tools.axeCDEnd - rpg_tools.axeCDStart
					
				local cooldown = math.floor(120 / axeLvl + 1)
				if cooldown < 0 then
					cooldown = 0
				end
				
				if timeElapsed/1000000 >= cooldown then	
					rpg_tools.axeCDStart = minetest.get_us_time()
				
					local woodName = block.name
					local count = cutWood(pos, {wood = 0, leaves = 0})
					
					local woodStack = ItemStack(woodName .. " " .. count.wood)
					local leaveStack = ItemStack(leaves(woodName) .. " " ..count.leaves)
					pos.x = pos.x - .25
					minetest.add_item(pos, woodStack)
					pos.x = pos.x + .5
					minetest.add_item(pos, leaveStack)
					
					minetest.chat_send_player(player:get_player_name(), "Timber! " .. count.wood .. " pieces of wood cut. " .. count.leaves .. " leaves cut.")
					
					-- adds exp
					rpg.addXP(player, "axe", count.wood)
				else	
					minetest.chat_send_player(player:get_player_name(), "Your Timber skill is on cooldown: " .. (cooldown - math.floor(timeElapsed/1000000)) .. " seconds left")
				end
			end	
		else
			minetest.chat_send_player(player:get_player_name(), "You must rightclick on a tree to use Timber.")
		end

	end
end

-- returns the name of the random ore chosen
-- once skill reaches 100, ores do not get any better
local function getRandomOre(skill)
	if skill > 100 then 
		skill = 100
	end
	local lowTier = 30
	local midTier = 60
	local highTier = 90
	
	local blockTier = 90
	
	local randomNumber = math.random(0 + skill, 100)
	local blockChance = math.random(0 + skill/2, 100)
	
	if randomNumber >= highTier then
		local diamond_or_gold_or_mese = math.random(0, 4)
		if diamond_or_gold_or_mese <= 1 then
			if blockChance >= blockTier then
				return "default:diamondblock"
			else
				return "default:stone_with_diamond"
			end
		elseif diamond_or_gold_or_mese <= 3 then
			if blockChance >= blockTier then
				return "default:goldblock"
			else
				return "default:stone_with_gold"
			end
		else
			if blockChance >= blockTier then
				return "default:mese"
			else
				return "default:stone_with_mese"
			end
		end
	end
	
	if randomNumber >= midTier then
		if blockChance >= blockTier then
			return "default:steelblock"
		else
			return "default:stone_with_iron"
		end
	end
	
	if randomNumber >= lowTier then
		local copper_or_tin = math.random(0,1)
		if copper_or_tin == 0 then
			if blockChance >= blockTier then
				return "default:copperblock"
			else
				return "default:stone_with_copper"
			end
		else
			if blockChance >= blockTier then
				return "default:tinblock"
			else
				return "default:stone_with_tin"
			end
		end
	end
	
	if blockChance >= blockTier then
		return "default:coalblock"
	else
		return "default:stone_with_coal"
	end

end

-- mining skill
-- turns stone into a random ore
local function pickaxeRightClick(itemStack, player, pointed_thing)
	if pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local block = minetest.get_node(pos)
		if block.name == "default:stone" then
			local miningLvl = player:get_attribute("miningLvl")
			
			-- checks if mining level is eligible to cut down entire trees
			if tonumber(miningLvl) == 0 then
				minetest.chat_send_player(player:get_player_name(), "You must have at least 1 Mining level to use Miner's Luck.")
			else
				-- sets a timer for the cooldown of the skill
				rpg_tools.miningCDEnd = minetest.get_us_time()
				local timeElapsed = rpg_tools.miningCDEnd - rpg_tools.miningCDStart
					
				local cooldown = math.floor(120 / miningLvl + 1)
				if cooldown < 0 then
					cooldown = 0
				end
				
				if timeElapsed/1000000 >= cooldown then	
					rpg_tools.miningCDStart = minetest.get_us_time()
					
					local randomNode = getRandomOre(tonumber(miningLvl))
					if string.find(randomNode, "block") then
						minetest.chat_send_player(player:get_player_name(), "Miner's Luck! Your stone turned into a block!")
					else
						minetest.chat_send_player(player:get_player_name(), "Miner's Luck! Your stone turned into ore!")
					end
					
					minetest.set_node(pos, {name = randomNode})
					
				else	
					minetest.chat_send_player(player:get_player_name(), "Your Miner's Luck skill is on cooldown: " .. (cooldown - math.floor(timeElapsed/1000000)) .. " seconds left")
				end
			end	
		else
			minetest.chat_send_player(player:get_player_name(), "You must rightclick on stone to use Miner's Luck.")
		end		
	end
end

function rpg_tools.diggable(name)
	local diggableNodes = 
		"default:dirt" ..
		"default:dirt_with_grass" ..
		"default:dirt_with_grass_footsteps" ..
		"default:dirt_with_dry_grass" ..
		"default:dirt_with_snow" ..
		"default:dirt_with_rainforest_litter" ..

		"default:sand" ..
		"default:desert_sand" ..
		"default:silver_sand" ..

		"default:gravel" ..

		"default:clay"
		
	return string.find(diggableNodes, name)
end

-- digs a 3 x 3 x 3 area
local function bulldozer(pos)
	local count = 0
	for x=1,3 do
		for z=1,3 do
			for y=1,3 do
				local pos2 = {x = pos.x + x - 2, y = pos.y + y - 2, z = pos.z + z - 2}
				local node = minetest.get_node(pos2)
				
				if rpg_tools.diggable(node.name) then
					minetest.dig_node(pos2)
					count = count + 1
				end
			end
		end
	end
	return count
end

-- digging skill
-- digs a large area
local function shovelRightClick(itemStack, player, pointed_thing)
	if pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local block = minetest.get_node(pos)
		if rpg_tools.diggable(block.name) then
			local diggingLvl = player:get_attribute("diggingLvl")
			
			-- checks if digging level is eligible use skill
			if tonumber(diggingLvl) == 0 then
				minetest.chat_send_player(player:get_player_name(), "You must have at least 1 Digging level to use Bulldozer.")
			else
				-- sets a timer for the cooldown of the skill
				rpg_tools.diggingCDEnd = minetest.get_us_time()
				local timeElapsed = rpg_tools.diggingCDEnd - rpg_tools.diggingCDStart
					
				local cooldown = math.floor(20 - diggingLvl)
				if cooldown < 0 then
					cooldown = 0
				end
				
				if timeElapsed/1000000 >= cooldown then	
					rpg_tools.diggingCDStart = minetest.get_us_time()
					local dirtDug = bulldozer(pos)
					
					minetest.chat_send_player(player:get_player_name(), "Bulldozer! " .. dirtDug .. " pieces of dirt dug up.")
					rpg.addXP(player, "digging", dirtDug)
				else	
					minetest.chat_send_player(player:get_player_name(), "Your Bulldozer skill is on cooldown: " .. (cooldown - math.floor(timeElapsed/1000000)) .. " seconds left")
				end
			end	
		else
			minetest.chat_send_player(player:get_player_name(), "You must rightclick on dirt to use Bulldozer.")
		end		
	end
end




-- overrides

--
-- Axes
--

minetest.override_item("default:axe_wood", {
	description = "Wooden Axe",
	inventory_image = "default_tool_woodaxe.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=0,
		groupcaps={
			choppy = {times={[2]=3.00, [3]=1.60}, uses=10, maxlevel=1},
		},
		damage_groups = {fleshy=2},
	},
	groups = {flammable = 2, axe = 1},
	sound = {breaks = "default_tool_breaks"},
	on_place = axeRightclick,
})

minetest.override_item("default:axe_stone", {
	description = "Stone Axe",
	inventory_image = "default_tool_stoneaxe.png",
	tool_capabilities = {
		full_punch_interval = 1.2,
		max_drop_level=0,
		groupcaps={
			choppy={times={[1]=3.00, [2]=2.00, [3]=1.30}, uses=20, maxlevel=1},
		},
		damage_groups = {fleshy=3},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = axeRightclick,
	groups = {axe = 1}
})


minetest.override_item("default:axe_steel", {
	description = "Steel Axe",
	inventory_image = "default_tool_steelaxe.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			choppy={times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=20, maxlevel=2},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = axeRightclick,
	groups = {axe = 1}
})

minetest.override_item("default:axe_bronze", {
	description = "Bronze Axe",
	inventory_image = "default_tool_bronzeaxe.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			choppy={times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=30, maxlevel=2},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = axeRightclick,
	groups = {axe = 1}
})

minetest.override_item("default:axe_mese", {
	description = "Mese Axe",
	inventory_image = "default_tool_meseaxe.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level=1,
		groupcaps={
			choppy={times={[1]=2.20, [2]=1.00, [3]=0.60}, uses=20, maxlevel=3},
		},
		damage_groups = {fleshy=6},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = axeRightclick,
	groups = {axe = 1}
})

minetest.override_item("default:axe_diamond", {
	description = "Diamond Axe",
	inventory_image = "default_tool_diamondaxe.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level=1,
		groupcaps={
			choppy={times={[1]=2.10, [2]=0.90, [3]=0.50}, uses=30, maxlevel=2},
		},
		damage_groups = {fleshy=7},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = axeRightclick,
	groups = {axe = 1}
})


--
-- Picks
--

minetest.override_item("default:pick_wood", {
	description = "Wooden Pickaxe",
	inventory_image = "default_tool_woodpick.png",
	tool_capabilities = {
		full_punch_interval = 1.2,
		max_drop_level=0,
		groupcaps={
			cracky = {times={[3]=1.60}, uses=10, maxlevel=1},
		},
		damage_groups = {fleshy=2},
	},
	groups = {flammable = 2, pickaxe = 1},
	sound = {breaks = "default_tool_breaks"},
	on_place = pickaxeRightClick
})

minetest.override_item("default:pick_stone", {
	description = "Stone Pickaxe",
	inventory_image = "default_tool_stonepick.png",
	tool_capabilities = {
		full_punch_interval = 1.3,
		max_drop_level=0,
		groupcaps={
			cracky = {times={[2]=2.0, [3]=1.00}, uses=20, maxlevel=1},
		},
		damage_groups = {fleshy=3},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = pickaxeRightClick,
	groups = {pickaxe = 1}
})

minetest.override_item("default:pick_steel", {
	description = "Steel Pickaxe",
	inventory_image = "default_tool_steelpick.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=20, maxlevel=2},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = pickaxeRightClick,
	groups = {pickaxe = 1}
})

minetest.override_item("default:pick_bronze", {
	description = "Bronze Pickaxe",
	inventory_image = "default_tool_bronzepick.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=30, maxlevel=2},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = pickaxeRightClick,
	groups = {pickaxe = 1}
})

minetest.override_item("default:pick_mese", {
	description = "Mese Pickaxe",
	inventory_image = "default_tool_mesepick.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level=3,
		groupcaps={
			cracky = {times={[1]=2.4, [2]=1.2, [3]=0.60}, uses=20, maxlevel=3},
		},
		damage_groups = {fleshy=5},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = pickaxeRightClick,
	groups = {pickaxe = 1}
})

minetest.override_item("default:pick_diamond", {
	description = "Diamond Pickaxe",
	inventory_image = "default_tool_diamondpick.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level=3,
		groupcaps={
			cracky = {times={[1]=2.0, [2]=1.0, [3]=0.50}, uses=30, maxlevel=3},
		},
		damage_groups = {fleshy=5},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = pickaxeRightClick,
	groups = {pickaxe = 1}
})

--
-- Shovels
--

minetest.override_item("default:shovel_wood", {
	description = "Wooden Shovel",
	inventory_image = "default_tool_woodshovel.png",
	wield_image = "default_tool_woodshovel.png^[transformR90",
	tool_capabilities = {
		full_punch_interval = 1.2,
		max_drop_level=0,
		groupcaps={
			crumbly = {times={[1]=3.00, [2]=1.60, [3]=0.60}, uses=10, maxlevel=1},
		},
		damage_groups = {fleshy=2},
	},
	groups = {flammable = 2 , shovel = 1},
	sound = {breaks = "default_tool_breaks"},
	on_place = shovelRightClick
})

minetest.override_item("default:shovel_stone", {
	description = "Stone Shovel",
	inventory_image = "default_tool_stoneshovel.png",
	wield_image = "default_tool_stoneshovel.png^[transformR90",
	tool_capabilities = {
		full_punch_interval = 1.4,
		max_drop_level=0,
		groupcaps={
			crumbly = {times={[1]=1.80, [2]=1.20, [3]=0.50}, uses=20, maxlevel=1},
		},
		damage_groups = {fleshy=2},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = shovelRightClick,
	groups = {shovel = 1}
})

minetest.override_item("default:shovel_steel", {
	description = "Steel Shovel",
	inventory_image = "default_tool_steelshovel.png",
	wield_image = "default_tool_steelshovel.png^[transformR90",
	tool_capabilities = {
		full_punch_interval = 1.1,
		max_drop_level=1,
		groupcaps={
			crumbly = {times={[1]=1.50, [2]=0.90, [3]=0.40}, uses=30, maxlevel=2},
		},
		damage_groups = {fleshy=3},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = shovelRightClick,
	groups = {shovel = 1}
})

minetest.override_item("default:shovel_bronze", {
	description = "Bronze Shovel",
	inventory_image = "default_tool_bronzeshovel.png",
	wield_image = "default_tool_bronzeshovel.png^[transformR90",
	tool_capabilities = {
		full_punch_interval = 1.1,
		max_drop_level=1,
		groupcaps={
			crumbly = {times={[1]=1.50, [2]=0.90, [3]=0.40}, uses=40, maxlevel=2},
		},
		damage_groups = {fleshy=3},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = shovelRightClick,
	groups = {shovel = 1}
})

minetest.override_item("default:shovel_mese", {
	description = "Mese Shovel",
	inventory_image = "default_tool_meseshovel.png",
	wield_image = "default_tool_meseshovel.png^[transformR90",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=3,
		groupcaps={
			crumbly = {times={[1]=1.20, [2]=0.60, [3]=0.30}, uses=20, maxlevel=3},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = shovelRightClick,
	groups = {shovel = 1}
})

minetest.override_item("default:shovel_diamond", {
	description = "Diamond Shovel",
	inventory_image = "default_tool_diamondshovel.png",
	wield_image = "default_tool_diamondshovel.png^[transformR90",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			crumbly = {times={[1]=1.10, [2]=0.50, [3]=0.30}, uses=30, maxlevel=3},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	on_place = shovelRightClick,
	groups = {shovel = 1}
})