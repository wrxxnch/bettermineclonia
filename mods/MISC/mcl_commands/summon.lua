local S = core.get_translator(core.get_current_modname())

-- =====================================================
-- BASE
-- =====================================================
local base_cmd = core.registered_chatcommands["spawnentity"]
assert(base_cmd, "[summon] spawnentity não encontrado")

local cmd = table.copy(base_cmd)
cmd.params = S("<entidade> [param=valor] ...")
cmd.description = S("Invoca entidades com parâmetros avançados")

-- =====================================================
-- FUNÇÃO PRINCIPAL
-- =====================================================
cmd.func = function(name, param)
	if param == "" or not param then
		return false, S("Uso: /summon <entidade> [param=valor]...")
	end

	local args = param:split(" ")
	local entname = table.remove(args, 1)

	-- Resolve nome curto
	if not entname:find(":") then
		if core.registered_entities["mobs_mc:" .. entname] then
			entname = "mobs_mc:" .. entname
		end
	end

	local ent_def = core.registered_entities[entname]
	if not ent_def then
		return false, S("Entidade desconhecida: @1", entname)
	end

	if core.settings:get_bool("only_peaceful_mobs", false)
	and ent_def.is_mob
	and ent_def.type == "monster" then
		return false, S("Apenas mobs pacíficos são permitidos!")
	end

	local player = core.get_player_by_name(name)
	if not player then
		return false, S("Jogador não encontrado.")
	end

	local pos = vector.add(player:get_pos(), {x=0, y=1.5, z=0})

	local obj = core.add_entity(pos, entname)
	if not obj then
		return false, S("Falha ao criar a entidade: @1", entname)
	end

	local luaent = obj:get_luaentity()

	-- =====================================================
	-- PARÂMETROS
	-- =====================================================
	for _, arg in ipairs(args) do
		local key, value = arg:match("([^=]+)=(.+)")
		if not key then
			goto continue
		end

		local final = value
		if value == "true" then final = true end
		if value == "false" then final = false end
		if tonumber(value) then final = tonumber(value) end

		--------------------------------------------------
		-- CHILD
		--------------------------------------------------
		if key == "child" and luaent then
			luaent.child = final
			if luaent.set_child then
				luaent:set_child(final)
			end

		--------------------------------------------------
		-- PASSIVE
		--------------------------------------------------
		elseif key == "passive" and luaent then
			luaent.passive = final

		--------------------------------------------------
		-- TAMED
		--------------------------------------------------
		elseif key == "tamed" and luaent then
			luaent.tamed = final
			luaent.owner = final and name or nil

		--------------------------------------------------
		-- NAMETAG
		--------------------------------------------------
		elseif key == "nametag" then
			obj:set_nametag_attributes({ text = tostring(final) })

		--------------------------------------------------
		-- HP
		--------------------------------------------------
		elseif key == "hp" then
			obj:set_hp(tonumber(final) or obj:get_hp())

		--------------------------------------------------
		-- YAW
		--------------------------------------------------
		elseif key == "yaw" then
			obj:set_yaw(math.rad(tonumber(final) or 0))

		--------------------------------------------------
		-- HAND (FORÇADO – SEM EXCEÇÃO)
		--------------------------------------------------
		elseif key == "hand" and luaent then
			-- Mineclonia usa APENAS este método
			if mcl_mobs and mcl_mobs.set_wielded_item then
				mcl_mobs.set_wielded_item(luaent, ItemStack(final))
				luaent._summon_forced_item = final -- trava visual
			end

		--------------------------------------------------
		-- ARMOR
		--------------------------------------------------
		elseif key == "armor" and luaent and luaent.set_armor_groups then
			luaent:set_armor_groups({ fleshy = tonumber(final) or 100 })

		--------------------------------------------------
		-- RIDE
		--------------------------------------------------
		elseif key == "ride" then
			local ride_name = value

			if not ride_name:find(":") then
				if core.registered_entities["mobs_mc:" .. ride_name] then
					ride_name = "mobs_mc:" .. ride_name
				end
			end

			if core.registered_entities[ride_name] then
				local mount = core.add_entity(pos, ride_name)
				if mount then
					obj:set_attach(mount, "", vector.zero(), vector.zero())
				end
			end

		--------------------------------------------------
		-- FALLBACK
		--------------------------------------------------
		else
			pcall(function()
				obj:set_properties({ [key] = final })
			end)
		end

		::continue::
	end

	return true, S("Entidade invocada: @1", entname)
end

-- =====================================================
-- REGISTRO
-- =====================================================
if core.registered_chatcommands["spawnentity"] then
	core.unregister_chatcommand("spawnentity")
end
core.register_chatcommand("summon", cmd)

-- =====================================================
-- HELP
-- =====================================================
core.register_chatcommand("summon_help", {
	description = S("Ajuda completa do /summon"),
	func = function(name)
		core.chat_send_player(name, [[
/summon <entidade> [param=valor]

PARÂMETROS:
child=true|false
passive=true|false
tamed=true|false
nametag=Texto
hp=NUM
yaw=GRAUS
hand=itemstring   (FORÇADO)
armor=NUM
ride=entidade

EXEMPLOS:
/summon zombie hand=mcl_core:dirt
/summon skeleton hand=mcl_core:bow
/summon zombie ride=spider
/summon piglin hand=mcl_core:sword_gold
]])
		return true
	end
})
