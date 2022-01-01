local CATEGORY_NAME = "NoLag Utilities"

local function isImportant(ent) -- is messing with the provided entity unsafe?
    local class = ent:GetClass()
    local model = ent:GetModel()
    return  
		ent:IsWorld() or
		string.StartWith(class, "func") or 
		string.StartWith(class, "env") or
		(model == nil) or
		(not string.StartWith(model,"mod"))
end

------------------------------ Nolag ------------------------------
function ulx.nolag(calling_ply)
	local amt = 0
	for k,v in pairs(ents.GetAll()) do
		local phys = v:GetPhysicsObject()
		if( phys:IsValid() ) then
			if( phys:IsMotionEnabled() ) then
				local not_freezable = isImportant(v) or string.StartWith(v:GetClass(),"npc")
				if not_freezable then continue end

				phys:EnableMotion(false)
				amt = amt + 1
			end
		end
	end
	ulx.fancyLogAdmin( calling_ply, "#A froze #i physics entities", amt )
	return amt
end

local nolag = ulx.command( CATEGORY_NAME, "ulx nolag", ulx.nolag, "!nolag" )
nolag:defaultAccess( ULib.ACCESS_ADMIN )
nolag:help( "Freeze all freezable entities on the server." )


------------------------------ Gibs Cleanup ------------------------------
local GIB_TYPES = {"gib","item_*","debris","helicopter_chunk"}
function ulx.nogibs( calling_ply )
	local count = 0
	for _, class in ipairs(GIB_TYPES) do
		for k, v in ipairs( ents.FindByClass(class) ) do 
			v:Remove() 
			count = count + 1
		end
	end
	ulx.fancyLogAdmin( calling_ply, "#A cleaned up #i gib entities", count )
	return count
end
local nogibs = ulx.command( CATEGORY_NAME, "ulx nogibs", ulx.nogibs, "!nogibs" )
nogibs:defaultAccess( ULib.ACCESS_ALL )
nogibs:help( "Removes gibs, acf debris, helicopter chunks, and more." )


------------------------------ Class Cleanup ------------------------------
function ulx.noclass( calling_ply, target_class, force )
	local count = 0
    if( #target_class < 3 ) then -- sanity check 1
        ULib.tsayError( calling_ply, "Sanity check failed; please use a longer class name!", true )
        return 0
    end
	for k, v in ipairs( ents.FindByClass(target_class) ) do 
		print(v)
		if( (force==0) and isImportant(v) ) then continue end -- sanity check 2
		v:Remove() 
		count = count + 1
	end
	if( (force==0) ) then
		ulx.fancyLogAdmin( calling_ply, "#A cleaned up #i entities matching the class #s", count, target_class )
	else
		ulx.fancyLogAdmin( calling_ply, "#A forcibly cleaned up #i entities matching the class #s", count, target_class )
	end
	return count
end

local noclass = ulx.command( CATEGORY_NAME, "ulx noclass", ulx.noclass, "!noclass" )
noclass:addParam{ type=ULib.cmds.StringArg, hint="class" }
noclass:addParam{ type=ULib.cmds.BoolArg, default=0, hint="force" }
noclass:defaultAccess( ULib.ACCESS_SUPERADMIN )
noclass:help( "Removes entities that match the provided class." )


------------------------------ Cleanup Player ------------------------------
function ulx.cleanup( calling_ply, target_ply )
	local count = 0
	if( NADMOD ) then -- make sure nadmod has initialized first
		count = NADMOD.CleanupPlayerProps(target_ply:SteamID())
	end

	ulx.fancyLogAdmin( calling_ply, "#A removed #i entities owned by #T", count, target_ply  )
	return count
end

local clean = ulx.command( CATEGORY_NAME, "ulx cleanup", ulx.cleanup, "!cleanup" )
clean:addParam{ type=ULib.cmds.PlayerArg }
clean:defaultAccess( ULib.ACCESS_ADMIN )
clean:help( "(NADMOD PP) Cleans up a player's entities.  Ideal for panicked spam removal." )


------------------------------ Cleanup Disconnected ------------------------------
function ulx.nadcleanupdiscon( calling_ply )
	RunConsoleCommand( "nadmod_cdp" )
	ulx.fancyLogAdmin( calling_ply, "#A cleaned up disconnected player's props" )
end
local nadcleanupdiscon = ulx.command( CATEGORY_NAME, "ulx cleanupdiscon", ulx.nadcleanupdiscon, "!cleanupdiscon" )
nadcleanupdiscon:defaultAccess( ULib.ACCESS_ADMIN )
nadcleanupdiscon:help( "(NADMOD PP) Clears props of disconnected players." )
