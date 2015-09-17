-- Copyright 2015 Eduardo Mezêncio

-----------------------
-- Node Registration --
-----------------------

local rocks_variants = 2

local function register_nodes(index, desert)
	local rocks_groups = {oddly_breakable_by_hand = 3, attached_node = 1}
	if index == 1 then
		rocks_groups.not_in_creative_inventory = 0
	else
		rocks_groups.not_in_creative_inventory = 1
	end

	local desert_str_1 = ""
	local desert_str_2 = ""
	if desert then
		desert_str_1 = "desert_"
		desert_str_2 = "Desert "
	end

	minetest.register_node("loose_rocks:loose_"..desert_str_1.."rocks_"..index, {
		description = "Loose "..desert_str_2.."Rocks",
		drawtype = "mesh",
		drop = "loose_rocks:loose_"..desert_str_1.."rocks_1",
		groups = rocks_groups,
		inventory_image = "loose_"..desert_str_1.."rocks_inv.png",
		mesh = "loose_rocks_" .. index ..".obj",
		on_place = function(itemstack, placer, pointed_thing)
			local pointed_pos = minetest.get_pointed_thing_position(pointed_thing, true)
			local return_value = minetest.item_place(itemstack, placer, pointed_thing, math.random(0,3))
			if minetest.get_node(pointed_pos).name == "loose_rocks:loose_"..desert_str_1.."rocks_1" then
				minetest.set_node(pointed_pos, {name = "loose_rocks:loose_"..desert_str_1.."rocks_"..math.random(1,rocks_variants),
				                                param2 = math.random(0,3)})
			end
			return return_value
		end,
		paramtype = "light",
		paramtype2 = "facedir",
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -0.3125, 0.5},
		},
		sunlight_propagates = true,
		tiles = {"default_"..desert_str_1.."stone.png"},
		walkable = false,
	})
end

for i = 1, rocks_variants do
	register_nodes(i, false)
	register_nodes(i, true)
end

------------
-- Crafts --
------------

local function register_crafts(desert)

	local desert_str
	if desert then
		desert_str = "desert_"
	else
		desert_str = ""
	end

	local cobble_str = "default:"..desert_str.."cobble"
	local loose_str = "loose_rocks:loose_"..desert_str.."rocks_1"

	minetest.register_craft({
		output = cobble_str,
		recipe = {
			{loose_str, loose_str, ""},
			{loose_str, loose_str, ""},
			{"", "", ""},
		}
	})

	minetest.register_craft({
		output = "loose_rocks:loose_"..desert_str.."rocks_1 4",
		recipe = {
			{cobble_str, "", ""},
			{"", "", ""},
			{"", "", ""},
		}
	})

end

register_crafts(false)
register_crafts(true)

--------------------
-- Map Generation --
--------------------

minetest.register_on_generated(function(minp, maxp, seed)

	if maxp.y < 0 then return end

	-- Check mapgen
	local mgname = minetest.get_mapgen_params().mgname

	math.randomseed(seed)
	local perlin = minetest.get_perlin(666, 3, 0.6, 100)
	local heightmap = minetest.get_mapgen_object("heightmap")
	local biomemap = nil
	if mgname == 'v5' or mgname == 'v7' then
		biomemap = minetest.get_mapgen_object("biomemap")
	end

	-- Assume X and Z lengths are equal
	local chunk = (maxp.x-minp.x+1) -- Probably 80
	local divs = 5
	local divlen = chunk / divs -- 16, if chunk is 80
	for divx = 0, divs - 1 do
	for divz = 0, divs - 1 do
		local x0 = minp.x + math.floor((divx) * divlen)
		local z0 = minp.z + math.floor((divz) * divlen)
		local x1 = minp.x + math.floor((divx+1) * divlen) - 1
		local z1 = minp.z + math.floor((divz+1) * divlen) - 1

		-- Determine amount of rocks from perlin noise
		local amount = math.floor((perlin:get2d({x=x0, y=z0}) + 1) ^ 3)

		-- Find positions for rocks
		for i=1,amount do
			local target_x = math.random(x0, x1)
			local target_z = math.random(z0, z1)
			local ground_y = heightmap[(target_x-minp.x) + (target_z-minp.z)*chunk + 1]
			local ground_name = minetest.get_node({x=target_x, y=ground_y, z=target_z}).name

			if ground_y < maxp.y and ground_y >= minp.y
			                     and ground_name ~= "air" then
			-- I check if the node underneath is not air because apparently the ground level
			-- provided by heightmap does not account for cave genetarion.
				local target_coord = {x=target_x, y=ground_y + 1, z=target_z}
				local target_name = minetest.get_node(target_coord).name

				-- Check if the node can be replaced
				if minetest.registered_nodes[target_name].buildable_to and
				  (minetest.get_item_group(target_name, "liquid") == 0) then

				  	local generate_desert = false

				  	-- For v5 and v7
				  	if biomemap then
				  		generate_desert = (biomemap[(target_x-minp.x) + (target_z-minp.z)*chunk + 1] == 15)
				  	-- For v6
				  	else
				  		generate_desert = (ground_name == "default:desert_sand" or
						                   ground_name == "default:desert_stone")
					end

					if generate_desert then
						minetest.set_node(target_coord,{name = "loose_rocks:loose_desert_rocks_"..math.random(1,rocks_variants),
							                        param2 = math.random(0,3)})
					else
						minetest.set_node(target_coord,{name = "loose_rocks:loose_rocks_"..math.random(1,rocks_variants),
							                        param2 = math.random(0,3)})
					end
				end
			end
		end
	end
	end
end)
