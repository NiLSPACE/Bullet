--[[
Created by STR_Warrior
]]

BulletRange   = nil
BulletSpeed   = nil
BulletSize    = nil
HoldItem      = nil
ExplosionSize = nil





function Initialize(Plugin)
	PLUGIN = Plugin
	Plugin:SetName("Bullet")
	Plugin:SetVersion(1)
	
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_RIGHT_CLICK, OnPlayerRightClick)
	
	LoadSettings(PLUGIN:GetLocalFolder() .. "/Config.ini")
	
	LOG("Initialized Bullet v." .. PLUGIN:GetVersion())
	return true
end





function LoadSettings(Path)
	local IniFile = cIniFile()
	IniFile:ReadFile(Path)
	BulletRange = IniFile:GetValueSetI("General", "Range", 75)
	HoldItem = GetBlockTypeMeta(IniFile:GetValueSet("General", "Item", "arrow"))
	if not HoldItem then
		LOGWARN("[Bullet] Item set is not valid. Using arrow as item")
		HoldItem = E_ITEM_ARROW
	end
	
	BulletSpeed = IniFile:GetValueSetI("General", "BulletSpeed", 4)
	if BulletSpeed < 1 then
		LOGWARN("[Bullet] Bullet speed is too slow. It has to be 1 or higher.")
		BulletSpeed = 1
	end
	
	BulletSize = IniFile:GetValueSetI("General", "BulletSize", 1)
	if BulletSize < 1 then
		LOGWARN("[Bullet] Bullet size is too small. It has to be 1 or bigger.")
		BullsetSize = 1
	end
	
	ExplosionSize = IniFile:GetValueSetI("General", "ExplosionSize", 5)
	if ExplosionSize < 1 then
		LOGWARN("[Bullet] Explosion size is too smal. It has to be 1 or bigger.")
		ExplosionSize = 1
	end
	IniFile:WriteFile(Path)
end





function OnPlayerRightClick(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ)
	if BlockFace ~= BLOCK_FACE_NONE then
		return false
	end
	
	if Player:GetEquippedItem().m_ItemType ~= HoldItem then
		return false
	end
	
	if not Player:HasPermission("Bullet.laser") then
		return false
	end
	
	local EyePos = Player:GetEyePosition();
	local LookVector = Player:GetLookVector();
	LookVector:Normalize();
	
	local Start = EyePos + LookVector + LookVector;
	local End = EyePos + LookVector * BulletRange;
	
	local LastPos = Start
	local T = 0
	local World = Player:GetWorld()
	local Callbacks = {
	OnNextBlock = function(X, Y, Z, BlockType, BlockMeta)
		if BlockType ~= E_BLOCK_AIR then
			World:ScheduleTask(T, function()
				if World:GetBlock(X, Y, Z) ~= E_BLOCK_AIR then
					World:DoExplosionAt(ExplosionSize, X, Y, Z, true, 1, Player)
				end
			end)
			return true
		end
		local VectorPos = Vector3d(X, Y, Z)
		local Distance = (LastPos - VectorPos):Length()
		if Distance > BulletSpeed then
			LastPos = VectorPos
			World:QueueSetBlock(X, Y, Z, E_BLOCK_DIAMOND_BLOCK, 0, T)
			World:QueueSetBlock(X, Y, Z, E_BLOCK_AIR, 0, T + BulletSize)
			T = T + 1
		end
	end}

	cLineBlockTracer.Trace(World, Callbacks, Start.x, Start.y, Start.z, End.x, End.y, End.z);
	return true
end





function GetBlockTypeMeta(Blocks)
	local Tonumber = tonumber(Blocks)
	if Tonumber == nil then	
		local Item = cItem()
		if StringToItem(Blocks, Item) == false then
			return false
		else
			return Item.m_ItemType, Item.m_ItemDamage
		end
		local Items = StringSplit(Blocks, ":")		
		if tonumber(Items[1]) == nil then
			return false
		else
			if Items[2] == nil then
				return Items[1], 0
			else
				return Items[1], Items[2]
			end
		end
	else
		return Tonumber, 0, true
	end
end
