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
local GIB_TYPES  = {"gib","item_.*","debris","helicopter_chunk"}
local GIB_MODELS = {"models/gibs/.*"}

local function HasNoOwner(ent)
	if not ent.CPPIGetOwner then return true end
	local own = ent:CPPIGetOwner()
	if own and own:IsPlayer() then return false end
	return true
end

function ulx.nogibs( calling_ply )

	local count = 0
	for k, v in ipairs( ents.GetAll(class) ) do 

		local ourClass = v:GetClass()
		for _, gibClass in ipairs(GIB_TYPES) do
			if string.match(ourClass, gibClass) then
				v:Remove() 
				count = count + 1
				goto exit
			end
		end

		if HasNoOwner(v) then
			local ourModel = v:GetModel()
			if not ourModel or ourModel == "" then goto exit end
			for _, gibModel in ipairs(GIB_MODELS) do
				if string.match(ourModel, gibModel) then
					v:Remove() 
					count = count + 1
					goto exit
				end
			end			
		end

		::exit::

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
		if( not force and isImportant(v) ) then continue end -- sanity check 2
		v:Remove() 
		count = count + 1
	end
	if( not force ) then
		ulx.fancyLogAdmin( calling_ply, "#A cleaned up #i entities matching the class #s", count, target_class )
	else
		ulx.fancyLogAdmin( calling_ply, "#A forcibly cleaned up #i entities matching the class #s", count, target_class )
	end
	return count
end

local noclass = ulx.command( CATEGORY_NAME, "ulx noclass", ulx.noclass, "!noclass" )
noclass:addParam{ type=ULib.cmds.StringArg, hint="class" }
noclass:addParam{ type=ULib.cmds.BoolArg, default=0, hint="force", ULib.cmds.optional }
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

------------------------------ Freeze Props ------------------------------
function ulx.freezeprops( calling_ply, target_ply )
	local count = 0

	for _, ent in ipairs( ents.GetAll() ) do
		local phys_obj = ent:GetPhysicsObject()

		if phys_obj:IsValid() and phys_obj:IsMotionEnabled() and ( ent:GetCreator() == target_ply or ent.SPPOwner == target_ply ) then
			phys_obj:EnableMotion( false )
			count = count + 1
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A froze #i physics entities owned by #T", count, target_ply )
end

local freezeprops = ulx.command( CATEGORY_NAME, "ulx freezeprops", ulx.freezeprops, "!freezeprops" )
freezeprops:addParam{ type = ULib.cmds.PlayerArg }
freezeprops:defaultAccess( ULib.ACCESS_ADMIN )
freezeprops:help( "Freezes all entities owned by the target" )

-- pass in kilobytes amount, get nicely formatted memory amount
local function memStr(amt)

    units = " KB"

    if amt > 1024 then
        amt = amt / 1024
        units = " MB"
    end

    if amt > 1024 then
        amt = amt / 1024
        units = " GB"
    end

    return math.Round(amt,1) .. units
end

------------------------------ Collect Garbage ------------------------------
function ulx.collectgarbage(calling_ply)

    local old = collectgarbage("count")
    collectgarbage()
    ulx.fancyLogAdmin( calling_ply, "#A freed #s of memory on the server", memStr( old - collectgarbage("count") ) )

end
local gc = ulx.command( CATEGORY_NAME, "ulx collectgarbage", ulx.collectgarbage, {"!gc","!collectgarbage"} )
gc:defaultAccess( ULib.ACCESS_ADMIN )
gc:help( "Attempts to free some memory on the server." )


------------------------------ Count Memory ------------------------------
function ulx.ramusage(calling_ply)
    ULib.tsay( calling_ply, "The server is currently using " .. memStr( collectgarbage('count') ) .. " of memory.", true )
end
local ramusage = ulx.command( CATEGORY_NAME, "ulx ramusage", ulx.ramusage, {"!mem","!memusage"} )
ramusage:defaultAccess( ULib.ACCESS_ADMIN )
ramusage:help( "Prints server memory usage in chat." )