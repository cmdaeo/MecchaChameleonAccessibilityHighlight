-- Mods/AccessibilityHighlight/Scripts/main.lua

print("[AccessibilityHighlighter] Script file started loading\n")

--------------------------------------------------------------------
-- CONFIGURATION: change this value and reload the mod to switch modes
-- Options: "light" | "chams" | "box"
--
--   "light" - Spawns a glowing point light above the whistled
--             character's head, making them easy to spot from a
--             distance or through foliage.
--
--   "chams" - Renders the character's mesh through walls and other
--             objects (X-ray/outline style), so you can see exactly
--             where they are even if they're out of direct line of
--             sight.
--
--   "box"   - Spawns a solid marker box at the character's location,
--             giving a clear, unmissable position indicator.
--------------------------------------------------------------------
local HIGHLIGHT_MODE = "chams"
--------------------------------------------------------------------

local WHISTLE_SOUND_KEYWORD = "provoaction"
local HIGHLIGHT_DURATION_MS = 2500
local WHISTLE_DEBOUNCE_MS = 500 -- ignore repeat whistle triggers within this window per pawn

-- All maps below are keyed by pawn NAME (string), not the pawn object itself.
-- UE4SS returns a new Lua wrapper object each time GetOwner() is called, even for
-- the same underlying UObject, so using the object as a table key never matches.
local highlightedPawns = {}   -- name -> expiry timestamp
local lastWhistleTime = {}    -- name -> last accepted whistle timestamp (for debounce)
local pawnRefs = {}           -- name -> latest valid pawn object reference
local pawnLightActors = {}    -- name -> light actor
local pawnBoxActors = {}      -- name -> box actor
local pawnChamsApplied = {}   -- name -> bool

local function GetTimeMs() return os.clock() * 1000 end

local function GetPawnKey(pawn)
    local okName, name = pcall(function() return pawn:GetFullName() end)
    if okName then return name end
    return nil
end

local function GetLocalPlayerController()
    local okAll, controllers = pcall(function() return FindAllOf("PlayerController") end)
    if not okAll or not controllers then return nil end
    for _, pc in pairs(controllers) do
        local okValid, isValid = pcall(function() return pc:IsValid() end)
        if okValid and isValid then return pc end
    end
    return nil
end

local function GetWorld()
    local pc = GetLocalPlayerController()
    if not pc then return nil end
    local okWorld, world = pcall(function() return pc:GetWorld() end)
    if okWorld and world and world:IsValid() then return world end
    return nil
end

-- ===== MODE 1: LIGHT =====

local function SpawnHighlightLight(key, pawn)
    if pawnLightActors[key] then return end
    local world = GetWorld()
    if not world then return end
    local okClass, lightClass = pcall(function() return StaticFindObject("/Script/Engine.PointLight") end)
    if not okClass or not lightClass or not lightClass:IsValid() then return end
    local okLoc, loc = pcall(function() return pawn:K2_GetActorLocation() end)
    if not okLoc or not loc then return end
    local spawnLoc = {X = loc.X, Y = loc.Y, Z = loc.Z + 100.0}
    local okSpawn, actor = pcall(function() return world:SpawnActor(lightClass, spawnLoc, {Pitch=0,Yaw=0,Roll=0}) end)
    if not okSpawn or not actor or not actor:IsValid() then return end
    local okComp, lightComp = pcall(function() return actor.LightComponent end)
    if okComp and lightComp and lightComp:IsValid() then
        pcall(function() lightComp.Intensity = 50000.0 end)
        pcall(function() lightComp.AttenuationRadius = 400.0 end)
        pcall(function() lightComp.LightColor = {R = 255, G = 220, B = 0} end)
        pcall(function() lightComp.CastShadows = false end)
    end
    pawnLightActors[key] = actor
    print(string.format("[AccessibilityHighlighter] [LIGHT] spawned for %s\n", key))
end

local function UpdateHighlightLight(key, pawn)
    local actor = pawnLightActors[key]
    if not actor or not actor:IsValid() then return end
    local okLoc, loc = pcall(function() return pawn:K2_GetActorLocation() end)
    if okLoc and loc then
        pcall(function() actor:K2_SetActorLocation({X=loc.X,Y=loc.Y,Z=loc.Z+100.0}, false, {}, false) end)
    end
end

local function RemoveHighlightLight(key)
    local actor = pawnLightActors[key]
    if actor then
        pcall(function() actor:K2_DestroyActor() end)
        pawnLightActors[key] = nil
    end
end

-- ===== MODE 2: CHAMS =====

local function ApplyChams(key, pawn)
    if pawnChamsApplied[key] then return end
    local okMeshClass, meshClass = pcall(function() return StaticFindObject("/Script/Engine.MeshComponent") end)
    if not okMeshClass or not meshClass or not meshClass:IsValid() then return end
    local okComps, comps = pcall(function() return pawn:K2_GetComponentsByClass(meshClass) end)
    if not okComps or not comps then return end
    local count = 0
    for _, rawComp in pairs(comps) do
        local okGet, comp = pcall(function() return rawComp:get() end)
        if okGet and comp then
            count = count + 1
            pcall(function() comp:SetRenderCustomDepth(true) end)
            pcall(function() comp:SetCustomDepthStencilValue(250) end)
        end
    end
    print(string.format("[AccessibilityHighlighter] [CHAMS] processed %d component(s) on %s\n", count, key))
    pawnChamsApplied[key] = true
end

local function RemoveChams(key, pawn)
    if not pawnChamsApplied[key] then return end
    local okMeshClass, meshClass = pcall(function() return StaticFindObject("/Script/Engine.MeshComponent") end)
    if okMeshClass and meshClass and pawn then
        local okComps, comps = pcall(function() return pawn:K2_GetComponentsByClass(meshClass) end)
        if okComps and comps then
            for _, rawComp in pairs(comps) do
                local okGet, comp = pcall(function() return rawComp:get() end)
                if okGet and comp then
                    pcall(function() comp:SetRenderCustomDepth(false) end)
                end
            end
        end
    end
    pawnChamsApplied[key] = nil
end

-- ===== MODE 3: BOX =====

local function SpawnHighlightBox(key, pawn)
    if pawnBoxActors[key] then return end
    local world = GetWorld()
    if not world then return end
    local okActorClass, actorClass = pcall(function() return StaticFindObject("/Script/Engine.StaticMeshActor") end)
    if not okActorClass or not actorClass or not actorClass:IsValid() then return end
    local okLoc, loc = pcall(function() return pawn:K2_GetActorLocation() end)
    if not okLoc or not loc then return end
    local okSpawn, actor = pcall(function() return world:SpawnActor(actorClass, loc, {Pitch=0,Yaw=0,Roll=0}) end)
    if not okSpawn or not actor or not actor:IsValid() then return end

    pcall(function() actor:SetMobility(2) end)

    local okCube, cubeMesh = pcall(function() return StaticFindObject("/Engine/BasicShapes/Cube.Cube") end)
    if not okCube or not cubeMesh or not cubeMesh:IsValid() then
        pcall(function() actor:K2_DestroyActor() end)
        return
    end

    local okMeshComp, meshComp = pcall(function() return actor.StaticMeshComponent end)
    if not okMeshComp or not meshComp or not meshComp:IsValid() then
        pcall(function() actor:K2_DestroyActor() end)
        return
    end

    pcall(function() meshComp:SetStaticMesh(cubeMesh) end)
    pcall(function() meshComp:SetWorldScale3D({X = 1.0, Y = 1.0, Z = 2.0}) end)
    pcall(function() meshComp:SetCollisionEnabled(0) end)
    pcall(function() meshComp:SetVisibility(true, true) end)
    pcall(function() meshComp:SetHiddenInGame(false) end)
    pcall(function() meshComp:MarkRenderStateDirty() end)

    pawnBoxActors[key] = actor
    print(string.format("[AccessibilityHighlighter] [BOX] spawned for %s\n", key))
end

local function UpdateHighlightBox(key, pawn)
    local actor = pawnBoxActors[key]
    if not actor or not actor:IsValid() then return end
    local okLoc, loc = pcall(function() return pawn:K2_GetActorLocation() end)
    if okLoc and loc then
        pcall(function() actor:K2_SetActorLocation(loc, false, {}, false) end)
    end
end

local function RemoveHighlightBox(key)
    local actor = pawnBoxActors[key]
    if actor then
        pcall(function() actor:K2_DestroyActor() end)
        pawnBoxActors[key] = nil
    end
end

-- ===== DISPATCH =====

local function ApplyHighlight(key, pawn)
    if HIGHLIGHT_MODE == "light" then
        SpawnHighlightLight(key, pawn); UpdateHighlightLight(key, pawn)
    elseif HIGHLIGHT_MODE == "chams" then
        ApplyChams(key, pawn)
    elseif HIGHLIGHT_MODE == "box" then
        SpawnHighlightBox(key, pawn); UpdateHighlightBox(key, pawn)
    end
end

local function ClearHighlight(key, pawn)
    RemoveHighlightLight(key)
    RemoveChams(key, pawn)
    RemoveHighlightBox(key)
end

-- ===== WHISTLE DETECTION (debounced, string-keyed) =====

RegisterHook("/Script/Engine.AudioComponent:Play", function(Context)
    local audioComp = Context:get()
    local okSound, sound = pcall(function() return audioComp.Sound end)
    if not okSound or not sound then return end
    local okName, soundName = pcall(function() return sound:GetFullName() end)
    if not okName then return end

    if string.find(string.lower(soundName), WHISTLE_SOUND_KEYWORD) then
        local okOwner, pawn = pcall(function() return audioComp:GetOwner() end)
        if not okOwner or not pawn or not pawn:IsValid() then return end

        local key = GetPawnKey(pawn)
        if not key then return end

        local now = GetTimeMs()
        local lastTime = lastWhistleTime[key]

        if lastTime and (now - lastTime) < WHISTLE_DEBOUNCE_MS then
            return -- ignore repeat trigger within debounce window
        end

        lastWhistleTime[key] = now
        pawnRefs[key] = pawn

        local wasAlreadyHighlighted = highlightedPawns[key] ~= nil
        highlightedPawns[key] = now + HIGHLIGHT_DURATION_MS

        if not wasAlreadyHighlighted then
            print(string.format("[AccessibilityHighlighter] Whistle detected on %s (mode=%s)\n", key, HIGHLIGHT_MODE))
        end
    end
end)

LoopAsync(100, function()
    ExecuteInGameThread(function()
        local now = GetTimeMs()
        for key, expiry in pairs(highlightedPawns) do
            local pawn = pawnRefs[key]
            if not pawn or not pawn:IsValid() or now > expiry then
                ClearHighlight(key, pawn)
                highlightedPawns[key] = nil
                lastWhistleTime[key] = nil
                pawnRefs[key] = nil
            else
                ApplyHighlight(key, pawn)
            end
        end
    end)
    return false
end)

print(string.format("[AccessibilityHighlighter] Loaded. Current mode: %s (edit HIGHLIGHT_MODE at top of script to change)\n", HIGHLIGHT_MODE))
