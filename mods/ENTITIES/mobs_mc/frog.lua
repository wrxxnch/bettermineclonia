local S = core.get_translator("mobs_mc")

local textures = {
	cold   = 1,
	snowy = 1,
	medium = 2,
	hot    = 3,
}

-------------------------------------------------
-- FROG
-------------------------------------------------
mcl_mobs.register_mob("mobs_mc:frog", {
	description = S("Frog"),
	type = "animal",
	passive = false,

	-------------------------------------------------
	-- MOVIMENTO CONTROLADO
	-------------------------------------------------
	walk_velocity = 0,
	run_velocity  = 0,
	acceleration  = {x=0, y=-9.8, z=0}, -- gravidade normal

	-------------------------------------------------
	-- COMBATE
	-------------------------------------------------
	attack_type = "melee",
	damage = 1,
	reach = 1,
	attacks_monsters = true,
	specific_attack = {
		"mobs_mc:slime_tiny",
		"mobs_mc:magma_cube_tiny",
	},

	-------------------------------------------------
	-- VIDA
	-------------------------------------------------
	hp_min = 5,
	hp_max = 25,
	armor = 100,

	-------------------------------------------------
	-- VISUAL
	-------------------------------------------------
	collisionbox = {-0.268, -0.01, -0.268, 0.268, 0.35, 0.268},
	visual = "mesh",
	mesh = "mobs_mc_frog.b3d",
	visual_size = {x = 10, y = 10},

	texture_list = {
		{"mobs_mc_frog.png"},
		{"mobs_mc_frog_temperate.png"},
		{"mobs_mc_frog_warm.png"},
	},

	-------------------------------------------------
	-- ANIMAÇÕES
	-------------------------------------------------
	animation = {
		speed_normal = 3,
		stand_start = 1, stand_end = 80,
		walk_start  = 90, walk_end  = 105,
	},

	-------------------------------------------------
	-- TEXTURA POR BIOMA
	-------------------------------------------------
	on_spawn = function(self)
		local pos = self.object:get_pos()
		if not pos then return end

		local bd = core.get_biome_data(pos)
		if not bd then return end

		local bname = core.get_biome_name(bd.biome)
		local bdef = core.registered_biomes[bname]
		if not bdef then return end

		self.texture_selected =
			textures[bdef._mcl_biome_type] or textures.medium

		self:set_properties({
			textures = self.texture_list[self.texture_selected]
		})
	end,

	-------------------------------------------------
	-- IA CUSTOM: MOVIMENTO NORMAL + ENGOLIR
	-------------------------------------------------
	do_custom = function(self, dtime)
		if not self.object then return end

		local pos = self.object:get_pos()
		if not pos then return end

		-- pausa mínima entre passos
		self._timer = (self._timer or 0) - dtime
		if self._timer > 0 then
			self.state = "stand"
			return
		end
		self._timer = 0.2

		-- procurar alvo
		local target
		for _, obj in ipairs(core.get_objects_inside_radius(pos, 6)) do
			local ent = obj:get_luaentity()
			if ent and (
				ent.name == "mobs_mc:slime_tiny" or
				ent.name == "mobs_mc:magma_cube_tiny"
			) then
				target = obj
				break
			end
		end

		if not target then
			self.state = "stand"
			return
		end

		local tpos = target:get_pos()
		if not tpos then return end

		-- direção horizontal para o alvo
		local dir = vector.direction(pos, tpos)
		local speed = 0.15 -- velocidade normal

		-- virar suavemente
		local current_yaw = self.object:get_yaw() or 0
		local target_yaw = math.atan2(dir.x, dir.z)
		self.object:set_yaw(current_yaw + (target_yaw - current_yaw) * 0.2)

		-- mover horizontalmente, preservando gravidade
		local vel = self.object:get_velocity()
		self.object:set_velocity({
			x = dir.x * speed,
			y = vel.y,
			z = dir.z * speed
		})

		self.state = "walk"

		-- engolir alvo se perto
		if vector.distance(pos, tpos) <= 1.2 then
			local ent = target:get_luaentity()
			target:remove()

			if ent and ent.name == "mobs_mc:magma_cube_tiny" then
				local drops = {
					[textures.cold]   = "mcl_mobitems:froglight_verdant",
					[textures.medium] = "mcl_mobitems:froglight_pearlescent",
					[textures.hot]    = "mcl_mobitems:froglight_ochre",
				}
				local drop = drops[self.texture_selected]
				if drop then
					core.add_item(pos, drop)
				end
			end

			core.sound_play("frog_eat", {pos = pos, gain = 1.0})
			self._target = nil
			self.state = "stand"
		end
	end,
})

-------------------------------------------------
-- SPAWN
-------------------------------------------------
mcl_mobs.spawn_setup({
	name = "mobs_mc:frog",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	biomes = {"Swampland","MangroveSwamp"},
	chance = 30,
})

mcl_mobs.register_egg("mobs_mc:frog", S("Frog"), "#00AA00", "#db635f", 0)
