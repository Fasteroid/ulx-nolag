local CATEGORY_NAME = "NoLag Utilities"


function ulx.nolag(calling_ply)
	local amt = 0
	for k,v in pairs(ents.GetAll()) do
		local phys = v:GetPhysicsObject()
		if( phys:IsValid() ) then
			if( phys:IsMotionEnabled() ) then
				local class = v:GetClass()
				local not_freezable = v:IsWorld() or v:GetPos()==Vector(0,0,0) or string.StartWith(class,"func") or string.StartWith(class,"env") or string.StartWith(class,"npc")
				if not_freezable then continue end

				phys:EnableMotion(false)
				amt = amt + 1
			end
		end
	end
	ulx.fancyLogAdmin( calling_ply, "#A froze #i entities.", amt )
	return amt
end

local nolag = ulx.command( CATEGORY_NAME, "ulx nolag", ulx.nolag, "!nolag" )
nolag:defaultAccess( ULib.ACCESS_ADMIN )
nolag:help( "Freeze all freezable entities on the server." )


------------------------------ Average entity position ------------------------------
function ulx.entcenter(calling_ply)
	local center = Vector(0)
	local amt = 0

	for k,v in pairs(ents.GetAll()) do
		if(v:GetPhysicsObject():IsValid() and v:GetModel()!=nil and string.StartWith(v:GetModel(),"mod")) then
				center = center + v:GetPos()
				amt = amt + 1
		end
	end
	center = center / amt
	calling_ply:SetPos(center)
    calling_ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
	
	ulx.fancyLogAdmin( calling_ply, "#A teleported to the average global entity position" )
	return center
end

local entcenter = ulx.command( CATEGORY_NAME, "ulx entcenter", ulx.entcenter, "!entcenter" )
entcenter:defaultAccess( ULib.ACCESS_ADMIN )
entcenter:help( "Teleport to the average position of all physics entities on the server.  May reveal where spammed entities are." )

------------------------------ Find entity clusters ------------------------------
function ulx.entcluster(calling_ply,clumpcount,clumprad)
	local center = Vector(0)
	local amt = 0
	local entities = {}
	
	for k,v in pairs(ents.GetAll()) do
		if(v:GetPhysicsObject():IsValid() and v:GetModel()!=nil and string.StartWith(v:GetModel(),"mod")) then
				table.insert(entities,v) -- set up a table so we can do some high-efficiency memes
				amt = amt + 1
		end
	end
	
	local chain = 1
	local nolaglastpos = Vector(0)
	local nolaglastent = calling_ply
	
	for k,v in pairs(entities) do
		--assume entities with close ent ids are probably somewhere near each other
		if( k > 0 ) then
			if(chain < clumpcount) then
			
				if( v:GetPos():Distance(nolaglastent:GetPos()) < clumprad ) then
					chain = chain + 1
					nolaglastpos = nolaglastpos + v:GetPos()
				else
					chain = 1
					nolaglastpos = v:GetPos()
				end
			
			else
				calling_ply:SetPos(nolaglastpos/clumpcount)
				calling_ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
				ulx.fancyLogAdmin( calling_ply, "#A teleported to a cluster of #i entities within #i source units of each other", clumpcount, clumprad )
				return
			
			end
		else
			nolaglastpos = v:GetPos()
		end
		nolaglastent = v
		
	end
	ULib.tsayError( calling_ply, "Didn't find anything, try again with different parameters", true )
end

local entcluster = ulx.command( CATEGORY_NAME, "ulx entcluster", ulx.entcluster, "!entcluster" )
entcluster:addParam{ type=ULib.cmds.NumArg, min=2, max=1024, default=4, hint="Number of entities to find", ULib.cmds.round, ULib.cmds.optional }
entcluster:addParam{ type=ULib.cmds.NumArg, min=16, max=2048, default=512, hint="Max distance between entities", ULib.cmds.round, ULib.cmds.optional }
entcluster:defaultAccess( ULib.ACCESS_ADMIN )
entcluster:help( "Locate a cluster of entities and teleport to it" )


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
clean:help( "Cleans up a player's entities.  Ideal for panicked spam removal." )



------------------------------ Cleanup Disconnected ------------------------------
function ulx.nadclean( calling_ply )
	RunConsoleCommand( "nadmod_cdp" )
	ulx.fancyLogAdmin( calling_ply, "#A cleaned up disconnected player's props" )
end
local nadclean = ulx.command( CATEGORY_NAME, "ulx cleanupdiscon", ulx.nadclean, "!cleanupdiscon" )
nadclean:defaultAccess( ULib.ACCESS_ADMIN )
nadclean:help( "(NADMOD PP) Clears props of disconnected players." )



------------------------------ Gibs Cleanup ------------------------------
local GIB_TYPES = {"gib","item_*","debris","helicopter_chunk"}
function ulx.gibclean( calling_ply )
	local count = 0
	for _, class in ipairs(GIB_TYPES) do
		for k, v in ipairs( ents.FindByClass(class) ) do 
			v:Remove() 
			count = count + 1
		end
	end
	ulx.fancyLogAdmin( calling_ply, "#A cleaned up #i world entities", count )
	return count
end
local gibclean = ulx.command( CATEGORY_NAME, "ulx cleargibs", ulx.gibclean, "!cleargibs" )
gibclean:defaultAccess( ULib.ACCESS_ALL )
gibclean:help( "Removes gibs that might be cluttering the map." )

------------------------------ Class Cleanup ------------------------------
function ulx.classclean( calling_ply, target_class )
	local count = 0

	for k, v in ipairs( ents.FindByClass(target_class) ) do 
		if( v:IsWorld() ) then continue end -- sanity check
		v:Remove() 
		count = count + 1
	end
	ulx.fancyLogAdmin( calling_ply, "#A cleaned up #i entities matching the class #s", count, target_class )
	return count
end

local classclean = ulx.command( CATEGORY_NAME, "ulx clearclass", ulx.classclean, "!clearclass" )
classclean:addParam{ type=ULib.cmds.StringArg }
classclean:defaultAccess( ULib.ACCESS_SUPERADMIN )
classclean:help( "Cleans up all instances of a specific entity class.  Use * to match multiple classes." )
