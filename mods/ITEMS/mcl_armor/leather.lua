
local C = core.colorize
local S = core.get_translator(core.get_current_modname())

local base_color = "#794100"

local function color_string_to_table(colorstring)
	if not colorstring or colorstring == "" then return {r=0, g=0, b=0} end
	return {
		r = tonumber(colorstring:sub(2,3), 16) or 0,
		g = tonumber(colorstring:sub(4,5), 16) or 0,
		b = tonumber(colorstring:sub(6,7), 16) or 0,
	}
end

local function av(a, b)
	return (a + b)/2
end

local function calculate_color(first, last)
	return {
		r = av(first.r, last.r),
		g = av(first.g, last.g),
		b = av(first.b, last.b),
	}
end

function mcl_armor.colorize_leather_armor(itemstack, colorstring)
	if not itemstack or core.get_item_group(itemstack:get_name(), "armor_leather") == 0 then
		return itemstack
	end
	local color = color_string_to_table(colorstring)
	colorstring = core.colorspec_to_colorstring(color)
	local meta = itemstack:get_meta()
	local old_color = meta:get_string("mcl_armor:color")
	if old_color == colorstring then return itemstack
	elseif old_color ~= "" then
		color = calculate_color(
			color_string_to_table(core.colorspec_to_colorstring(old_color)),
			color
		)
		colorstring = core.colorspec_to_colorstring(color)
	end
	meta:set_string("mcl_armor:color", colorstring)
	meta:set_string("inventory_image",
		itemstack:get_definition().inventory_image:gsub(".png$", "_desat.png") .. "^[multiply:" .. colorstring
	)
	if tt and tt.reload_itemstack_description then
		tt.reload_itemstack_description(itemstack)
	end
	return itemstack
end


function mcl_armor.wash_leather_armor(itemstack)
	if not itemstack or core.get_item_group(itemstack:get_name(), "armor_leather") == 0 then
		return itemstack
	end
	local meta = itemstack:get_meta()
	meta:set_string("mcl_armor:color", "")
	meta:set_string("inventory_image", "")
	if tt and tt.reload_itemstack_description then
		tt.reload_itemstack_description(itemstack)
	end
	return itemstack
end

mcl_armor.register_set({
	name = "leather",
	color = base_color,
	descriptions = {
		head = S("Leather Cap"),
		torso = S("Leather Tunic"),
		legs = S("Leather Pants"),
		feet = S("Leather Boots"),
	},
	durability = 80,
	enchantability = 15,
	points = {
		head = 1,
		torso = 3,
		legs = 2,
		feet = 1,
	},
	craft_material = "mcl_mobitems:leather",
	on_place = function(itemstack, placer, pointed_thing)
		if mcl_util.check_position_protection(pointed_thing.under, placer) then return itemstack end
		if core.get_item_group(core.get_node(pointed_thing.under).name, "cauldron_water") <= 0 then return end
		if mcl_cauldrons.add_level(pointed_thing.under, -1) then
			local outcome = mcl_armor.wash_leather_armor(itemstack)
			if outcome then
				core.sound_play("mcl_potions_bottle_pour", {pos=pointed_thing.under, gain=0.5, max_hear_range=16}, true)
				return outcome
			end
		end
	end,
})

tt.register_priority_snippet(function(_, _, itemstack)
	if not itemstack or core.get_item_group(itemstack:get_name(), "armor_leather") == 0 then
		return
	end
	local color = itemstack:get_meta():get_string("mcl_armor:color")
	if color and color ~= "" then
		local text = C(mcl_colors.GRAY, "Dyed: "..color)
		return text, false
	end
end)

-- Lógica de Crafting Dinâmica
local function colorizing_crafting(itemstack, player, old_craft_grid, craft_inv)
	local found_la = nil
	local dye_color = nil
	local items_count = 0

	for _, item in pairs(old_craft_grid) do
		local name = item:get_name()
		if name ~= "" then
			items_count = items_count + 1
			if core.get_item_group(name, "armor_leather") > 0 then
				if found_la then return nil end
				found_la = ItemStack(item)
			elseif core.get_item_group(name, "dye") > 0 then
				if dye_color then return nil end
				local def = core.registered_items[name]
				if def and def._color and mcl_dyes and mcl_dyes.colors[def._color] then
					dye_color = mcl_dyes.colors[def._color].rgb
				end
			else
				return nil
			end
		end
	end

	if items_count == 2 and found_la and dye_color then
		return mcl_armor.colorize_leather_armor(found_la, dye_color)
	end
	return nil
end

core.register_craft_predict(colorizing_crafting)
core.register_on_craft(colorizing_crafting)
