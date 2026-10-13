local UEHelpers = require("UEHelpers")

print("[Movement & Stamina] Superclass-Reflected Locomotion + BPC_Stamina Component Sync Loaded.\n")

-- cache stuff
local cachedPC = nil
local cachedPawn = nil
local cachedMoveComp = nil
local cachedSpringArm = nil
local baseArmLength = nil
local hasDumpedReflection = false
local hasHookedSprint = false

local currentArchetypeKey = nil
local currentProfile = nil
local activeMaxStamina = 85.0
local currentStamina = 85.0
local groundedStamina = 85.0
local isExhausted = false
local initialVanillaWalk = nil
local initialVanillaCrouch = nil
local initialVanillaMaxStamina = nil
local initialVanillaStaggerThreshold = nil
local initialVanillaHitInvulnWindow = nil
local skillSpeedMultiplier = 1.0
local sprintSkillMultiplier = 1.0
local isOverhaulActive = true

local knownCurNames = {"Current Stamina", "CurrentStamina", "Stamina", "CurrentStanima", "Stanima", "PlayerStamina"}
local knownMaxNames = {"Max Stamina", "MaxStamina", "MaxStanima", "MaximumStamina", "MaximumStanima"}

local function InvalidatePawnCache()
    cachedPC = nil
    cachedPawn = nil
    cachedMoveComp = nil
    cachedSpringArm = nil
    baseArmLength = nil
    hasDumpedReflection = false
    hasHookedSprint = false
    cachedIsInInnards = nil
    currentArchetypeKey = nil
    currentProfile = nil
    initialVanillaWalk = nil
    initialVanillaCrouch = nil
    initialVanillaMaxStamina = nil
    initialVanillaStaggerThreshold = nil
    initialVanillaHitInvulnWindow = nil
    skillSpeedMultiplier = 1.0
    sprintSkillMultiplier = 1.0
end

-- safe number parsing
local function ParseNumeric(val)
    if val == nil then return nil end
    if type(val) == "number" then return val end
    local n = nil
    pcall(function()
        if type(val.CurrentValue) == "number" then n = val.CurrentValue
        elseif type(val.BaseValue) == "number" then n = val.BaseValue
        elseif type(val.Value) == "number" then n = val.Value end
    end)
    return n
end

-- boolean check
local function IsPropertyTruthy(val)
    if val == nil then return false end
    if val == true then return true end
    if val == false then return false end
    local num = ParseNumeric(val)
    if num ~= nil then return num > 0.5 end
    local str = tostring(val)
    return str == "true" or str == "True" or str == "1"
end

-- check host auth
local function IsLocalAuthority(Pawn)
    if not Pawn or not Pawn:IsValid() then return true end
    local hasAuth = true
    pcall(function()
        if Pawn.HasAuthority then
            hasAuth = Pawn:HasAuthority()
        elseif Pawn.Role ~= nil then
            local r = ParseNumeric(Pawn.Role) or Pawn.Role
            hasAuth = (r == 3) -- 3 = ROLE_Authority
        end
    end)
    return hasAuth
end

-- char stats
local CHARACTER_PROFILES = {
    ["SHAMAN"] = {
        DisplayName = "Shaman",
        WalkSpeed = 310.0,
        SprintSpeed = 960.0,
        InnardsJog = 500.0,
        CrouchSpeed = 240.0,
        SurgeSpeed = 1050.0,
        JumpZ = 710.0,
        DefaultMaxStamina = 85.0,
        SprintDrainRate = 5.5,
    },
    ["SCAV_GIRL"] = {
        DisplayName = "Scav Girl",
        WalkSpeed = 330.0,         -- Nimble, light on her feet
        SprintSpeed = 1040.0,       -- Apex infiltrator rocket sprint
        InnardsJog = 530.0,        -- Brisk, effortless scout jog
        CrouchSpeed = 255.0,       -- Fast stealth traversal
        SurgeSpeed = 1120.0,       -- Maximum overdrive evasion
        JumpZ = 740.0,             -- Light, high ballistic launch
        DefaultMaxStamina = 80.0,  -- Moderate native stamina
        SprintDrainRate = 5.2,     -- Efficient runner
    },
    ["OLD_MAN"] = {
        DisplayName = "Old Man",
        WalkSpeed = 305.0,         -- Disciplined tactical pace
        SprintSpeed = 950.0,       -- Solid, reliable combat sprint
        InnardsJog = 495.0,        -- Consistent hub jog
        CrouchSpeed = 235.0,
        SurgeSpeed = 1040.0,
        JumpZ = 705.0,
        DefaultMaxStamina = 85.0,  -- Balanced stamina
        SprintDrainRate = 5.5,
    },
    ["BAG_MAN"] = {
        DisplayName = "Bag Man",
        WalkSpeed = 285.0,         -- Heavy, grounded stride
        SprintSpeed = 870.0,       -- Kinetic freight train charge
        InnardsJog = 450.0,        -- Sturdy hauler jog
        CrouchSpeed = 220.0,
        SurgeSpeed = 970.0,
        JumpZ = 680.0,             -- Weighted, punchy launch
        DefaultMaxStamina = 105.0, -- Massive heavy stamina pool
        SprintDrainRate = 6.2,     -- Heavy body mass drain
    },
    ["MASK_MAN"] = {
        DisplayName = "Mask Man",
        WalkSpeed = 310.0,         -- Precise marksman movement
        SprintSpeed = 940.0,       -- Focused sprint
        InnardsJog = 500.0,
        CrouchSpeed = 240.0,
        SurgeSpeed = 1030.0,
        JumpZ = 700.0,
        DefaultMaxStamina = 75.0,  -- Leaner stamina pool
        SprintDrainRate = 5.8,
    },
    ["GUNHEAD"] = {
        DisplayName = "Gunhead",
        WalkSpeed = 300.0,
        SprintSpeed = 930.0,
        InnardsJog = 490.0,
        CrouchSpeed = 230.0,
        SurgeSpeed = 1020.0,
        JumpZ = 700.0,
        DefaultMaxStamina = 90.0,
        SprintDrainRate = 5.6,
    },
    ["DEFAULT"] = {
        DisplayName = "Survivor",
        WalkSpeed = 310.0,
        SprintSpeed = 960.0,
        InnardsJog = 500.0,
        CrouchSpeed = 240.0,
        SurgeSpeed = 1050.0,
        JumpZ = 710.0,
        DefaultMaxStamina = 85.0,
        SprintDrainRate = 5.5,
    },
}

currentProfile = CHARACTER_PROFILES["SHAMAN"]
currentArchetypeKey = "SHAMAN"

local function ResolveCharacterArchetype(Pawn)
    if not Pawn or not Pawn:IsValid() then return "DEFAULT" end
    local str = ""
    pcall(function()
        local cName = Pawn:GetClass():GetFName():ToString()
        local fName = Pawn:GetFullName()
        str = string.lower(cName .. " " .. fName)
    end)
    if string.find(str, "scav") or string.find(str, "girl") then
        return "SCAV_GIRL"
    elseif string.find(str, "bag") or string.find(str, "heavy") then
        return "BAG_MAN"
    elseif string.find(str, "old") then
        return "OLD_MAN"
    elseif string.find(str, "mask") then
        return "MASK_MAN"
    elseif string.find(str, "shaman") then
        return "SHAMAN"
    elseif string.find(str, "gunhead") or string.find(str, "gun") then
        return "GUNHEAD"
    else
        return "DEFAULT"
    end
end


local function ApplyStaggerImmunity(Pawn)
    if not Pawn or not Pawn:IsValid() then return end
    pcall(function()
        Pawn["Hit Reaction Invuln?"] = true
        Pawn["Hit Reaction Invuln Window"] = 999999.0
        Pawn.StaggerDamageThreshold = 9999999.0
        Pawn.StaggerDamageThreshhold = 9999999.0
        Pawn.CurrentStaggerDamage = 0.0
        Pawn.TinyDamageHitReaction = false
        Pawn.HitReactsPreventFire = false
        Pawn.UpgradeHitReacts = false
    end)
end

local function ApplyModdedPhysics(MoveComp)
    if not MoveComp or not MoveComp:IsValid() then return end
    MoveComp.GravityScale = 1.45
    MoveComp.JumpZVelocity = currentProfile.JumpZ
    MoveComp.AirControl = 0.50
    MoveComp.FallingLateralFriction = 0.0
    MoveComp.MaxAcceleration = 3800.0
    MoveComp.BrakingDecelerationWalking = 2500.0
    MoveComp.GroundFriction = 7.0
end

local function UpdateCharacterProfile(Pawn)
    if not Pawn or not Pawn:IsValid() then return end

    local key = ResolveCharacterArchetype(Pawn)
    if key ~= currentArchetypeKey or not currentProfile or initialVanillaWalk == nil then
        currentArchetypeKey = key
        currentProfile = CHARACTER_PROFILES[key] or CHARACTER_PROFILES["DEFAULT"]

        -- Sample initial vanilla values for this character Pawn
        pcall(function()
            local mc = Pawn.CharacterMovement
            if mc and mc:IsValid() then
                if initialVanillaWalk == nil and mc.MaxWalkSpeed and mc.MaxWalkSpeed > 50.0 and mc.MaxWalkSpeed < 600.0 then
                    initialVanillaWalk = mc.MaxWalkSpeed
                end
                if initialVanillaCrouch == nil and mc.MaxWalkSpeedCrouched and mc.MaxWalkSpeedCrouched > 50.0 then
                    initialVanillaCrouch = mc.MaxWalkSpeedCrouched
                end
            end
            local bpc = Pawn.BPC_Stamina
            if bpc and bpc:IsValid() then
                local sMax = ParseNumeric(bpc["Max Stamina"]) or ParseNumeric(bpc.MaxStamina)
                if sMax and sMax > 20.0 and sMax < 500.0 then
                    initialVanillaMaxStamina = sMax
                end
            end
            if initialVanillaStaggerThreshold == nil and Pawn.StaggerDamageThreshold ~= nil then
                local st = ParseNumeric(Pawn.StaggerDamageThreshold)
                if st and st > 0.0 and st < 10000.0 then
                    initialVanillaStaggerThreshold = st
                end
            end
            if initialVanillaHitInvulnWindow == nil and Pawn["Hit Reaction Invuln Window"] ~= nil then
                local hw = ParseNumeric(Pawn["Hit Reaction Invuln Window"])
                if hw and hw > 0.0 and hw < 100.0 then
                    initialVanillaHitInvulnWindow = hw
                end
            end
        end)

        -- Skill Tree Dynamic Multiplier: Compares native walk speed against baseline vanilla (299.09)
        local baselineWalk = 299.09
        if initialVanillaWalk and initialVanillaWalk > baselineWalk + 1.0 then
            skillSpeedMultiplier = initialVanillaWalk / baselineWalk
        else
            skillSpeedMultiplier = 1.0
        end

        sprintSkillMultiplier = skillSpeedMultiplier
        pcall(function()
            local sm = ParseNumeric(Pawn.SprintingSpeedModifier)
            if sm and sm > 2.0 then
                sprintSkillMultiplier = sprintSkillMultiplier * (sm / 2.0)
            end
        end)

        -- Authoritative dynamic max stamina: respects skills, prestige & rigs
        local dynMax = nil
        pcall(function()
            local bpc = Pawn.BPC_Stamina
            if bpc and bpc:IsValid() then
                dynMax = ParseNumeric(bpc["Max Stamina"]) or ParseNumeric(bpc.MaxStamina)
            end
        end)
        if dynMax and dynMax > 30.0 and dynMax < 500.0 then
            activeMaxStamina = dynMax
        else
            activeMaxStamina = currentProfile.DefaultMaxStamina
        end

        -- Ensure current stamina is bounded
        if currentStamina > activeMaxStamina then
            currentStamina = activeMaxStamina
        end

        print(string.format("[MovementPlus] Character Profile: %s [%s] (Max Stamina: %.1f | Sprint: %.0f cm/s [x%.2f] | Walk: %.0f cm/s [x%.2f] | JumpZ: %.0f)",
            currentProfile.DisplayName, currentArchetypeKey, activeMaxStamina, currentProfile.SprintSpeed * sprintSkillMultiplier, currentProfile.WalkSpeed * skillSpeedMultiplier, sprintSkillMultiplier, skillSpeedMultiplier, currentProfile.JumpZ))
    end
end

local function GetPawnAndComp()
    if cachedPC and cachedPC:IsValid() and cachedPawn and cachedPawn:IsValid() and cachedMoveComp and cachedMoveComp:IsValid() then
        local currentPawn = cachedPC.AcknowledgedPawn or cachedPC.Pawn
        if currentPawn == cachedPawn then
            UpdateCharacterProfile(cachedPawn)
            return cachedMoveComp, cachedPawn, cachedPC
        end
    end

    local Controllers = FindAllOf("PlayerController") or FindAllOf("Controller")
    local PC = nil

    if Controllers then
        for _, Controller in ipairs(Controllers) do
            if Controller:IsValid() then
                local isLocal = false
                pcall(function()
                    if Controller.IsLocalPlayerController and Controller:IsLocalPlayerController() then
                        isLocal = true
                    elseif Controller.IsLocalController and Controller:IsLocalController() then
                        isLocal = true
                    end
                end)
                if isLocal then
                    PC = Controller
                    break
                end
            end
        end
    end

    if not PC or not PC:IsValid() then
        PC = UEHelpers.GetPlayerController()
    end

    if not PC or not PC:IsValid() then return nil, nil, nil end
    local Pawn = PC.AcknowledgedPawn or PC.Pawn
    if not Pawn or not Pawn:IsValid() then return nil, nil, nil end

    local isLocalPawn = true
    pcall(function()
        if Pawn.IsLocallyControlled then
            isLocalPawn = Pawn:IsLocallyControlled()
        end
    end)
    if not isLocalPawn then return nil, nil, nil end

    local MoveComp = Pawn.CharacterMovement
    if not MoveComp or not MoveComp:IsValid() then return nil, Pawn, PC end

    cachedPC = PC
    cachedPawn = Pawn
    cachedMoveComp = MoveComp
    UpdateCharacterProfile(Pawn)
    return MoveComp, Pawn, PC
end

-- reset on death or level change
pcall(function()
    RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, newPawn)
        InvalidatePawnCache()
    end)
end)

-- sprint detection
local isNativeSprintActive = false

-- find the camera arm
local function GetSpringArm(Pawn)
    if cachedSpringArm and cachedSpringArm:IsValid() then
        return cachedSpringArm
    end
    pcall(function()
        local arms = FindAllOf("SpringArmComponent")
        if arms then
            local pawnName = Pawn:GetFullName()
            for _, arm in ipairs(arms) do
                if arm and arm:IsValid() then
                    local owner = arm:GetOwner()
                    if owner and owner:IsValid() and owner:GetFullName() == pawnName then
                        cachedSpringArm = arm
                        return
                    end
                end
            end
            if #arms == 1 and arms[1]:IsValid() then
                cachedSpringArm = arms[1]
            end
        end
    end)
    return cachedSpringArm
end

-- are we in the hub
local function IsInInnards(Pawn)
    if cachedIsInInnards ~= nil then
        return cachedIsInInnards
    end
    if not Pawn or not Pawn:IsValid() then return false end

    local inHub = false
    pcall(function()
        local name = string.lower(Pawn:GetFullName())
        if string.find(name, "innard") or string.find(name, "hub") then
            inHub = true
            return
        end

        local world = Pawn:GetWorld()
        if world and world:IsValid() then
            local wName = string.lower(world:GetFullName())
            if string.find(wName, "innard") or string.find(wName, "hub") then
                inHub = true
                return
            end
        end
    end)

    cachedIsInInnards = inHub
    local curJog = currentProfile and currentProfile.InnardsJog or 500.0
    local curWalk = currentProfile and currentProfile.WalkSpeed or 310.0
    print(string.format("[MovementPlus] Zone Detected: %s (Base Speed: %.0f cm/s)", 
        inHub and "INNARDS HUB" or "MISSION MAP", inHub and curJog or curWalk))
    return inHub
end


local SyncStamina

-- hooks
local function SetupSprintHooksAndProperties(Pawn, MoveComp)
    if hasHookedSprint or not Pawn or not Pawn:IsValid() then return end
    hasHookedSprint = true

    -- 1. BPC_Stamina tweak
    pcall(function()
        local bpcStamina = Pawn.BPC_Stamina
        if bpcStamina and bpcStamina:IsValid() then
            -- zero out jump costs so we don't lose stamina
            bpcStamina["Stamina Cost: Jumping"] = 0.0
            bpcStamina["Stamina Cost: Sprint"] = 0.0
            bpcStamina["Out of Stamina"] = false
            bpcStamina["Report Out of Stamina"] = false
            print("[BPC_Stamina] Zeroed Stamina Cost: Jumping & Cost: Sprint on BPC_Stamina component.")
        end
    end)

    -- 2. hooking shift keys
    pcall(function()
        -- 28 = Started (Shift pressed down) -> Sprint ON
        RegisterHook("/Game/FW/Player/BP_PlayerBase.BP_PlayerBase_C:InpActEvt_IA_Sprint_K2Node_EnhancedInputActionEvent_28", function(self)
            isNativeSprintActive = true
        end)
        -- 27 = Triggered (Shift held) -> Sprint ON
        RegisterHook("/Game/FW/Player/BP_PlayerBase.BP_PlayerBase_C:InpActEvt_IA_Sprint_K2Node_EnhancedInputActionEvent_27", function(self)
            isNativeSprintActive = true
        end)
        -- 26 = Completed / Cancelled (Shift released) -> Sprint OFF
        RegisterHook("/Game/FW/Player/BP_PlayerBase.BP_PlayerBase_C:InpActEvt_IA_Sprint_K2Node_EnhancedInputActionEvent_26", function(self)
            isNativeSprintActive = false
        end)
        -- Disable Sprint Check Timer -> Sprint OFF
        RegisterHook("/Game/FW/Player/BP_PlayerBase.BP_PlayerBase_C:Disable Sprint Check Timer", function(self)
            isNativeSprintActive = false
        end)
    end)

    -- 3. hook jumps
    pcall(function()
        local function ZeroJumpStaminaHook(self)
            if not isOverhaulActive then return end
            pcall(function()
                currentStamina = math.max(currentStamina, groundedStamina)
                local mComp, pChar = GetPawnAndComp()
                if pChar and pChar:IsValid() and SyncStamina then
                    SyncStamina(pChar, mComp, currentStamina, activeMaxStamina)
                end
            end)
        end

        RegisterHook("/Game/FW/Player/BP_PlayerBase.BP_PlayerBase_C:SERVER Jump Stamina", ZeroJumpStaminaHook, ZeroJumpStaminaHook)
        RegisterHook("/Game/FW/Player/BPC_Stamina.BPC_Stamina_C:Jump Stamina", ZeroJumpStaminaHook, ZeroJumpStaminaHook)
        RegisterHook("/Game/FW/Player/BPC_Stamina.BPC_Stamina_C:Sprint Adjust for Jump", ZeroJumpStaminaHook, ZeroJumpStaminaHook)

        for i = 8, 12 do
            local fnPath = string.format("/Game/FW/Player/BP_PlayerBase.BP_PlayerBase_C:InpActEvt_IA_Jump_K2Node_EnhancedInputActionEvent_%d", i)
            pcall(function()
                RegisterHook(fnPath, ZeroJumpStaminaHook, ZeroJumpStaminaHook)
            end)
        end
    end)

    -- 4. ignore hit reactions
    pcall(function()
        RegisterHook("/Game/FW/Player/BP_PlayerBase.BP_PlayerBase_C:Hit Reaction Logic", function(self)
            if not isOverhaulActive then return end
            local mComp, pChar = GetPawnAndComp()
            if pChar and pChar:IsValid() and self == pChar then
                return true -- Bypass BP Hit Reaction Logic on local player!
            end
        end)
        RegisterHook("/Game/FW/Player/BP_PlayerBase.BP_PlayerBase_C:Event Hit Reaction Cooldown", function(self)
            if not isOverhaulActive then return end
            local mComp, pChar = GetPawnAndComp()
            if pChar and pChar:IsValid() and self == pChar then
                return true
            end
        end)
    end)

    -- 5. clear stagger damage
    ApplyStaggerImmunity(Pawn)
    pcall(function()
        print("[StaggerImmunity] Configured Hit Reaction Invulnerability and zeroed Stagger Accumulators.")
    end)
end

-- check if sprinting
local function DetermineSprintState(Pawn, MoveComp)
    -- Check 1: Hooked Enhanced Input sprint actions (Shift pressed/held)
    if isNativeSprintActive then
        return true, "NATIVE_SHIFT_HOOK"
    end

    -- Check 2: Native FWGameCharacter bWantsToRun (The primary native sprint boolean)
    if Pawn and Pawn:IsValid() then
        if Pawn.bWantsToRun == true then
            return true, "PAWN_bWantsToRun"
        end
    end

    -- Check 3: BPC_Stamina Sprint Tag
    if Pawn and Pawn:IsValid() then
        local bpc = Pawn.BPC_Stamina
        if bpc and bpc:IsValid() and bpc["Sprint Tag Present"] == true then
            return true, "BPC_SprintTagPresent"
        end
    end

    -- Check 4: Camera SpringArm pullback (Must be moving and >= 30 units longer than baseline)
    local vel = MoveComp and MoveComp.Velocity or nil
    local hSpeed = vel and math.sqrt((vel.X * vel.X) + (vel.Y * vel.Y)) or 0.0
    local arm = GetSpringArm(Pawn)
    if arm and arm:IsValid() and arm.TargetArmLength then
        if baseArmLength == nil and arm.TargetArmLength > 50.0 then
            baseArmLength = arm.TargetArmLength
        end
        if baseArmLength and (arm.TargetArmLength > baseArmLength + 30.0) and hSpeed > 350.0 then
            return true, string.format("CAMERA_PULLBACK (%.0f > %.0f)", arm.TargetArmLength, baseArmLength)
        end
    end

    return false, "WALKING"
end

-- variables for jump and stamina
local wasFalling = false
local jumpPhase = 0       -- 0 = Grounded, 1 = First Jump, 2 = Double Jump Consumed
local timeInAir = 0.0
local lastVelZ = 0.0
local timeSinceLastAction = 0.0

-- Adrenal Surge (Automatic Clutch Passive)
local isAmplifyActive = false
local amplifyTimer = 0.0
local hasSurgeTriggered = false

-- helper to safely set stamina values
local function SetStaminaOnObject(obj, propName, val)
    if not obj or not obj:IsValid() then return end
    pcall(function()
        local cur = obj[propName]
        if cur ~= nil and type(cur) == "number" then
            obj[propName] = val
        end
    end)
end

-- sync stamina to everywhere
SyncStamina = function(Pawn, MoveComp, staminaVal, maxVal)
    if not Pawn or not Pawn:IsValid() then return end

    -- 1. BPC_Stamina Component (THE TRUE GAME STAMINA COMPONENT!)
    pcall(function()
        local bpcStamina = Pawn.BPC_Stamina
        if bpcStamina and bpcStamina:IsValid() then
            bpcStamina["Current Stamina"] = staminaVal
            bpcStamina["Max Stamina"] = maxVal
            bpcStamina["Stamina Cost: Jumping"] = 0.0
            bpcStamina["Stamina Cost: Sprint"] = 0.0
            bpcStamina["Out of Stamina"] = isExhausted
            bpcStamina["Report Out of Stamina"] = isExhausted
        end
    end)

    -- 2. Pawn numeric properties

    for _, name in ipairs(knownCurNames) do
        SetStaminaOnObject(Pawn, name, staminaVal)
    end
    for _, name in ipairs(knownMaxNames) do
        SetStaminaOnObject(Pawn, name, maxVal)
    end

    -- 3. MovementComponent properties (if present)
    if MoveComp and MoveComp:IsValid() then
        for _, name in ipairs(knownCurNames) do
            SetStaminaOnObject(MoveComp, name, staminaVal)
        end
        for _, name in ipairs(knownMaxNames) do
            SetStaminaOnObject(MoveComp, name, maxVal)
        end
    end
end

-- hook jumps
pcall(function()
    RegisterHook("/Script/Engine.Character:Jump", function(self)
        if not isOverhaulActive then return end
        pcall(function()
            local MoveComp, Pawn = GetPawnAndComp()
            if Pawn and Pawn:IsValid() then
                currentStamina = math.max(currentStamina, groundedStamina)
                SyncStamina(Pawn, MoveComp, currentStamina, activeMaxStamina)
            end
        end)
    end)
    RegisterHook("/Script/Engine.Character:OnJumped", function(self)
        if not isOverhaulActive then return end
        pcall(function()
            local MoveComp, Pawn = GetPawnAndComp()
            if Pawn and Pawn:IsValid() then
                currentStamina = math.max(currentStamina, groundedStamina)
                SyncStamina(Pawn, MoveComp, currentStamina, activeMaxStamina)
            end
        end)
    end)
end)

-- helper to find our health
local function GetHealthValues(Pawn)
    if not Pawn or not Pawn:IsValid() then return nil, nil end
    local cur, max = nil, nil
    pcall(function()
        if Pawn.GetHealth then cur = Pawn:GetHealth() end
        if Pawn.GetMaxHealth then max = Pawn:GetMaxHealth() end
        if Pawn.GetHealthPercent then
            local p = Pawn:GetHealthPercent()
            if type(p) == "number" then cur = p * 100.0; max = 100.0 end
        end
    end)
    if type(cur) == "number" and type(max) == "number" then return cur, max end

    pcall(function()
        local hList = {"Health", "CurrentHealth", "HP"}
        for _, name in ipairs(hList) do
            local val = Pawn[name]
            if type(val) == "number" then cur = val; break end
        end
        local mList = {"MaxHealth", "MaxHP"}
        for _, name in ipairs(mList) do
            local val = Pawn[name]
            if type(val) == "number" then max = val; break end
        end
    end)
    return cur, max
end

-- trigger surge
local function TriggerAdrenalSurge(reason)
    isAmplifyActive = true
    amplifyTimer = 8.0
    currentStamina = activeMaxStamina
    isExhausted = false
    local surgeSpd = currentProfile and (currentProfile.SurgeSpeed * (sprintSkillMultiplier or 1.0)) or 1050.0
    print(string.format("[Surge] >>> CRITICAL HEALTH (%s)! ADRENAL SURGE: Overdrive %.0f cm/s & Costs -80%% <<<", reason, surgeSpd))
end

-- main loop
local lastTickTime = nil

LoopAsync(5, function()
    local loopStatus, loopErr = pcall(function()
        if not isOverhaulActive then return end

        local MoveComp, Pawn, PC = GetPawnAndComp()
        if not MoveComp or not MoveComp:IsValid() or not Pawn or not Pawn:IsValid() then 
            return 
        end

        -- Configure BPC_Stamina and register hooks on valid Pawn
        SetupSprintHooksAndProperties(Pawn, MoveComp)

        local now = os.clock()
        local dt = 0.005
        if lastTickTime ~= nil then
            local delta = now - lastTickTime
            if delta > 0.0005 and delta < 0.1 then
                dt = delta
            end
        end
        lastTickTime = now

        local vel = MoveComp.Velocity
        local hSpeed = math.sqrt((vel.X * vel.X) + (vel.Y * vel.Y))

        -- Auto-reset native sprint if character completely stops moving
        if hSpeed < 40.0 and isNativeSprintActive then
            isNativeSprintActive = false
        end

        -- Step A: jump and physics
        ApplyModdedPhysics(MoveComp)

        -- double jump check
    	local isFalling = false
        pcall(function() isFalling = MoveComp:IsFalling() end)

        -- Detect early jump intention on frame 0 to lock grounded stamina
    	local isJumpIntent = false
        pcall(function()
            if Pawn.bPressedJump == true or MoveComp.bPressedJump == true or Pawn.bIsJumping == true then
                isJumpIntent = true
            end
        end)

    	if not isFalling then
            -- Character is firmly grounded: Reset jump state
            timeInAir = 0.0
            jumpPhase = 0
            -- Only update groundedStamina if character is NOT in the middle of launching a jump
            if not isJumpIntent then
                groundedStamina = currentStamina
            end
        else
            -- Character is airborne
            timeInAir = timeInAir + dt

            if jumpPhase == 0 then
                -- Transition from ground to airborne (1st jump launch)
                jumpPhase = 1
                -- Continuously enforce that first jump costs 0.0 stamina!
                currentStamina = math.max(currentStamina, groundedStamina)
                SyncStamina(Pawn, MoveComp, currentStamina, activeMaxStamina)
            elseif jumpPhase == 1 and timeInAir > 0.15 then
                -- In the air after initial ground launch:
                -- Detect when double-jump (air jump) occurs via upward vertical impulse
                local velDeltaZ = vel.Z - lastVelZ
                if vel.Z > 250.0 and velDeltaZ > 200.0 then
                    jumpPhase = 2 -- Double jump executed!
                    currentStamina = math.max(currentStamina, groundedStamina)
                    SyncStamina(Pawn, MoveComp, currentStamina, activeMaxStamina)
                else
                    currentStamina = math.max(currentStamina, groundedStamina)
                    SyncStamina(Pawn, MoveComp, currentStamina, activeMaxStamina)
                end
            elseif jumpPhase == 2 then
                -- Double jump already consumed! Clamp any further spacebar spam impulses
                local velDeltaZ = vel.Z - lastVelZ
                if vel.Z > 150.0 and velDeltaZ > 150.0 then
                    vel.Z = math.min(lastVelZ, 0.0)
                    MoveComp.Velocity = vel
                end
            end
        end
        wasFalling = isFalling
        lastVelZ = vel.Z

        -- Only allow JumpMaxCount = 2 if not exhausted and double-jump has not been consumed
        local targetJumpCount = (isExhausted or jumpPhase >= 2) and 1 or 2
        pcall(function() Pawn.JumpMaxCount = targetJumpCount end)
        pcall(function() MoveComp.JumpMaxCount = targetJumpCount end)

        -- Step B: stop flinching and stuns
        local Mesh = Pawn.Mesh
        if Mesh and Mesh:IsValid() then
            local AnimInst = Mesh:GetAnimInstance()
            if AnimInst and AnimInst:IsValid() then
                local activeMontage = AnimInst:GetCurrentActiveMontage()
                if activeMontage and activeMontage:IsValid() then
                    local mName = string.lower(activeMontage:GetFName():ToString())

                    -- actions we shouldn't stop
                    local isPlayerAction = false
                    local pActs = {"melee", "attack", "swing", "mantle", "vault", "climb", "reload", "heal", "med", "loot", "revive", "interact", "grenade", "throw", "fire"}
                    for _, a in ipairs(pActs) do
                        if string.find(mName, a) then
                            isPlayerAction = true
                            break
                        end
                    end

                    if not isPlayerAction then
                        -- instantly abort bad animations
                        local bActs = {"hit", "flinch", "damage", "stagger", "react", "bullet", "pain", "wound", "hurt", "concussion", "stumble", "knock", "land", "hard", "impact", "recovery", "exhaust", "tired", "breath", "pant"}
                        for _, a in ipairs(bActs) do
                            if string.find(mName, a) then
                                AnimInst:Montage_Stop(0.01, activeMontage)
                                break
                            end
                        end
                    end
                end
            end
        end

        -- make sure stagger immunity stays active
        ApplyStaggerImmunity(Pawn)
        pcall(function()
            if Pawn.IsMoveInputIgnored and Pawn:IsMoveInputIgnored() then
                if PC and PC:IsValid() and PC.ResetIgnoreMoveInput then
                    PC:ResetIgnoreMoveInput()
                end
            end
        end)

        -- Step C: speed modes
        local isSprinting, sprintReason = DetermineSprintState(Pawn, MoveComp)

        local isCrouched = false
        pcall(function()
            if tostring(Pawn.bIsCrouched) == "true" or Pawn.bIsCrouched == true then
                isCrouched = true
            end
        end)

        -- scale speed with skills
        local effWalk = currentProfile.WalkSpeed * skillSpeedMultiplier
        local effSprint = currentProfile.SprintSpeed * sprintSkillMultiplier
        local effInnards = currentProfile.InnardsJog * skillSpeedMultiplier
        local effCrouch = currentProfile.CrouchSpeed * skillSpeedMultiplier
        local effSurge = currentProfile.SurgeSpeed * sprintSkillMultiplier

        local inHub = IsInInnards(Pawn)
        local baseSpeed = inHub and effInnards or effWalk

        local targetSpeed = baseSpeed
        if isCrouched then
            targetSpeed = effCrouch
            MoveComp.MaxWalkSpeed = targetSpeed
            MoveComp.MaxWalkSpeedCrouched = targetSpeed
        elseif isExhausted then
            targetSpeed = math.max(200.0, effWalk * 0.77) -- Proportional exhausted walk
            MoveComp.MaxWalkSpeed = targetSpeed
            MoveComp.MaxWalkSpeedCrouched = effCrouch * 0.85
        elseif isAmplifyActive then
            targetSpeed = effSurge
            MoveComp.MaxWalkSpeed = targetSpeed
            MoveComp.MaxWalkSpeedCrouched = effCrouch
        elseif isSprinting and not isExhausted then
            targetSpeed = effSprint
            MoveComp.MaxWalkSpeed = targetSpeed
            MoveComp.MaxWalkSpeedCrouched = effCrouch
        else
            targetSpeed = baseSpeed
            MoveComp.MaxWalkSpeed = targetSpeed
            MoveComp.MaxWalkSpeedCrouched = effCrouch
        end
        pcall(function() MoveComp.MaxCustomMovementSpeed = targetSpeed end)
        pcall(function() Pawn["Pawn BP Modded Walk Speed"] = targetSpeed end)
        pcall(function() Pawn["Default Max Walk Speed"] = targetSpeed end)

        -- Step D: stamina drain and recovery
        -- 1. Auto-Check Adrenal Surge health trigger
        local curHP, maxHP = GetHealthValues(Pawn)
        if curHP and maxHP and maxHP > 0.0 then
            local hpPercent = (curHP / maxHP) * 100.0

            if hpPercent <= 30.0 and not hasSurgeTriggered then
                hasSurgeTriggered = true
                TriggerAdrenalSurge(string.format("%.0f%% HP", hpPercent))
            elseif hpPercent > 60.0 and hasSurgeTriggered then
                hasSurgeTriggered = false
                print("[Surge] Health restored above 60%. Adrenal Surge re-armed.")
            end
        end

        -- 2. Surge active timer
        local costMultiplier = 1.0
        if isAmplifyActive then
            amplifyTimer = amplifyTimer - dt
            costMultiplier = 0.20 -- 80% stamina cost reduction
            if amplifyTimer <= 0.0 then
                isAmplifyActive = false
                print("[Surge] Adrenal Surge window expired.")
            end
        end

        -- 3. JUMP STAMINA COST = 0.0 (Both First Jump and Double Jump are 100% free)

        -- 4. Sprint drain (ONLY actively sprinting ON GROUND drains stamina; airborne jumps & walking are 100% free)
        if isSprinting and hSpeed > 450.0 and not isFalling and not isExhausted then
            currentStamina = math.max(0.0, currentStamina - ((currentProfile.SprintDrainRate * costMultiplier) * dt))
            timeSinceLastAction = 0.0
        else
            timeSinceLastAction = timeSinceLastAction + dt
        end

        -- 5. Exhaustion Lockout Gate
        if currentStamina <= 0.0 and not isExhausted then
            isExhausted = true
            isNativeSprintActive = false
            pcall(function()
                if Pawn and Pawn:IsValid() then
                    Pawn.bWantsToRun = false
                    if Pawn.BPC_Stamina and Pawn.BPC_Stamina:IsValid() then
                        Pawn.BPC_Stamina["Out of Stamina"] = true
                        Pawn.BPC_Stamina["Report Out of Stamina"] = true
                    end
                end
            end)
            print("[Stamina] Exhausted! Forced to walk until stamina is 100% full.")
        end

        -- 6. Tactical regeneration & release gate (Accurately reads skill-upgraded rate from BPC_Stamina!)
        local vanillaRegen = 8.5
        local rechargeDelay = 0.60
        pcall(function()
            local bpc = Pawn.BPC_Stamina
            if bpc and bpc:IsValid() then
                local r = ParseNumeric(bpc["Stamina Recharge: Recharge Rate"])
                       or ParseNumeric(bpc["Stamina Regeneration Rate"]) 
                       or ParseNumeric(bpc["Stamina Regen Rate"]) 
                       or ParseNumeric(bpc["Regeneration Rate"]) 
                       or ParseNumeric(bpc["Regen Rate"])
                if r and r > 0.0 and r < 100.0 then
                    vanillaRegen = r
                end

                local d = ParseNumeric(bpc["Stamina Recharge: Recharge Delay"])
                if d and d >= 0.0 and d < 5.0 then
                    rechargeDelay = math.min(0.60, d)
                end

                -- Dynamic Max Stamina refresh (if skills/booze/rig modified Max Stamina during session)
                local dynMax = ParseNumeric(bpc["Max Stamina"]) or ParseNumeric(bpc.MaxStamina)
                if dynMax and dynMax > 30.0 and dynMax < 500.0 and math.abs(dynMax - activeMaxStamina) > 0.5 then
                    local prevMax = activeMaxStamina
                    activeMaxStamina = dynMax
                    if currentStamina >= prevMax - 1.0 then
                        currentStamina = activeMaxStamina
                    end
                end
            end
        end)

        if isExhausted then
            -- Exhausted recovery: proportional to player's skill-upgraded stamina recharge rate
            local exhaustRecoveryRate = math.max(6.0, vanillaRegen * 0.70)
            currentStamina = math.min(activeMaxStamina, currentStamina + (exhaustRecoveryRate * dt))
            if currentStamina >= activeMaxStamina then
                isExhausted = false
                pcall(function()
                    if Pawn and Pawn:IsValid() and Pawn.BPC_Stamina and Pawn.BPC_Stamina:IsValid() then
                        Pawn.BPC_Stamina["Out of Stamina"] = false
                        Pawn.BPC_Stamina["Report Out of Stamina"] = false
                    end
                end)
                print("[Stamina] Fully recovered! Sprint and double-jump restored.")
            end
        elseif timeSinceLastAction > rechargeDelay and currentStamina < activeMaxStamina then
            currentStamina = math.min(activeMaxStamina, currentStamina + (vanillaRegen * dt))
        end

        -- 7. Comprehensive BPC_Stamina, HUD & Engine Synchronization
        SyncStamina(Pawn, MoveComp, currentStamina, activeMaxStamina)
    end)

    if not loopStatus then
        print(string.format("[Movement Loop Error] %s\n", tostring(loopErr)))
    end

    return false
end)

-- toggle button
-- M key toggles the mod
local lastToggleTimestamp = 0.0
local TOGGLE_DEBOUNCE = 0.35 -- 350ms debounce prevents rapid re-triggering

local function RunOnGameThread(fn)
    local inGameThread = false
    pcall(function()
        if IsInGameThread and IsInGameThread() then
            inGameThread = true
        end
    end)
    if inGameThread then
        fn()
    else
        ExecuteInGameThread(fn)
    end
end

local function HandleMasterModToggle()
    local now = os.clock()
    if (now - lastToggleTimestamp) < TOGGLE_DEBOUNCE then
        return
    end
    lastToggleTimestamp = now

    RunOnGameThread(function()
        isOverhaulActive = not isOverhaulActive
        local MoveComp, Pawn = GetPawnAndComp()
        if Pawn and Pawn:IsValid() then
            UpdateCharacterProfile(Pawn)
        end

        local charName = currentProfile and currentProfile.DisplayName or "Survivor"

        if not isOverhaulActive then
            -- restore vanilla values
            local vel = (MoveComp and MoveComp:IsValid()) and MoveComp.Velocity or nil
            local hSpeed = vel and math.sqrt((vel.X * vel.X) + (vel.Y * vel.Y)) or 0.0

            local vanillaWalk = initialVanillaWalk or 299.09
            local vanillaSprint = vanillaWalk * 2.0
            local vanillaCrouch = initialVanillaCrouch or 150.0

            if MoveComp and MoveComp:IsValid() then
                MoveComp.GravityScale = 1.0
                MoveComp.JumpZVelocity = 600.0
                MoveComp.AirControl = 1.0
                MoveComp.FallingLateralFriction = 2.0
                MoveComp.MaxAcceleration = 492.2
                MoveComp.BrakingDecelerationWalking = 95.0
                MoveComp.GroundFriction = 5.0
                MoveComp.MaxWalkSpeedCrouched = vanillaCrouch
                pcall(function() MoveComp.MaxCustomMovementSpeed = vanillaWalk end)
                pcall(function() MoveComp.JumpMaxCount = 1 end)

                -- Seamless on-the-move speed transition:
                -- If player is running or holding Shift, adopt vanilla sprint speed
                -- so character does not abruptly stutter or grind to a halt!
                if isNativeSprintActive or hSpeed > 350.0 then
                    MoveComp.MaxWalkSpeed = vanillaSprint
                else
                    MoveComp.MaxWalkSpeed = vanillaWalk
                end
            end

            -- Smooth stamina percentage preservation: prevents HUD bar confusion
            local currentRatio = 1.0
            if activeMaxStamina > 0.0 then
                currentRatio = math.min(1.0, math.max(0.0, currentStamina / activeMaxStamina))
            end
            local vanillaMax = initialVanillaMaxStamina or (currentProfile and currentProfile.DefaultMaxStamina) or 85.0
            local restoredVanillaStamina = currentRatio * vanillaMax

            if Pawn and Pawn:IsValid() then
                pcall(function() Pawn.JumpMaxCount = 1 end)
                pcall(function() Pawn["Pawn BP Modded Walk Speed"] = vanillaWalk end)
                pcall(function() Pawn["Default Max Walk Speed"] = vanillaWalk end)

                if isNativeSprintActive or hSpeed > 350.0 then
                    pcall(function() Pawn.bWantsToRun = true end)
                else
                    pcall(function() Pawn.bWantsToRun = false end)
                end

                -- Restore native vanilla stagger & flinch attributes
                pcall(function()
                    Pawn["Hit Reaction Invuln?"] = false
                    Pawn["Hit Reaction Invuln Window"] = initialVanillaHitInvulnWindow or 0.2
                    Pawn.StaggerDamageThreshold = initialVanillaStaggerThreshold or 50.0
                    Pawn.StaggerDamageThreshhold = initialVanillaStaggerThreshold or 50.0
                    Pawn.TinyDamageHitReaction = true
                    Pawn.HitReactsPreventFire = true
                end)

                pcall(function()
                    local bpc = Pawn.BPC_Stamina
                    if bpc and bpc:IsValid() then
                        bpc["Max Stamina"] = vanillaMax
                        bpc["Current Stamina"] = restoredVanillaStamina
                        bpc["Stamina Cost: Jumping"] = 15.0
                        bpc["Stamina Cost: Sprint"] = 5.0
                        bpc["Out of Stamina"] = isExhausted
                        bpc["Report Out of Stamina"] = isExhausted
                    end
                end)
            end

            jumpPhase = 0
            isAmplifyActive = false

            print(string.format("\n============================================================\n[MovementPlus] MOD DISABLED via [M] Key.\n  -> Seamlessly restored to 100%% VANILLA state for %s.\n============================================================\n", charName))
        else
            -- re-enable mod values
            jumpPhase = 0
            cachedIsInInnards = nil

            if MoveComp and MoveComp:IsValid() and Pawn and Pawn:IsValid() then
                -- Re-apply damage stagger immunity
                ApplyStaggerImmunity(Pawn)

                -- Read current vanilla stamina ratio and smoothly map to overhaul pool
                local currentRatio = 1.0
                pcall(function()
                    local bpc = Pawn.BPC_Stamina
                    if bpc and bpc:IsValid() then
                        local cur = ParseNumeric(bpc["Current Stamina"])
                        local max = ParseNumeric(bpc["Max Stamina"]) or initialVanillaMaxStamina or activeMaxStamina
                        if cur and max and max > 0.0 then
                            currentRatio = math.min(1.0, math.max(0.0, cur / max))
                        end
                    end
                end)

                currentStamina = currentRatio * activeMaxStamina
                groundedStamina = currentStamina

                -- Neutralize component costs
                pcall(function()
                    local bpc = Pawn.BPC_Stamina
                    if bpc and bpc:IsValid() then
                        bpc["Max Stamina"] = activeMaxStamina
                        bpc["Current Stamina"] = currentStamina
                        bpc["Stamina Cost: Jumping"] = 0.0
                        bpc["Stamina Cost: Sprint"] = 0.0
                        bpc["Out of Stamina"] = isExhausted
                        bpc["Report Out of Stamina"] = isExhausted
                    end
                end)

                local effWalk = currentProfile.WalkSpeed * skillSpeedMultiplier
                local effSprint = currentProfile.SprintSpeed * sprintSkillMultiplier
                local effInnards = currentProfile.InnardsJog * skillSpeedMultiplier
                local effCrouch = currentProfile.CrouchSpeed * skillSpeedMultiplier

                local inHub = IsInInnards(Pawn)
                local baseSpeed = inHub and effInnards or effWalk
                local vel = MoveComp.Velocity
                local hSpeed = vel and math.sqrt((vel.X * vel.X) + (vel.Y * vel.Y)) or 0.0

                -- Seamless on-the-move speed transition:
                -- If player was moving fast or holding Shift in vanilla, instantly surge into rocket sprint!
                if isNativeSprintActive or hSpeed > 350.0 or Pawn.bWantsToRun == true then
                    isNativeSprintActive = true
                    MoveComp.MaxWalkSpeed = effSprint
                    pcall(function() Pawn.bWantsToRun = true end)
                else
                    MoveComp.MaxWalkSpeed = baseSpeed
                end

                ApplyModdedPhysics(MoveComp)
                MoveComp.MaxWalkSpeedCrouched = effCrouch
                pcall(function() MoveComp.JumpMaxCount = 2 end)
                pcall(function() Pawn.JumpMaxCount = 2 end)
                pcall(function() Pawn["Pawn BP Modded Walk Speed"] = effSprint end)
                pcall(function() Pawn["Default Max Walk Speed"] = baseSpeed end)
            end

            print(string.format("\n============================================================\n[MovementPlus] MOD ENABLED via [M] Key.\n  -> Kinetic overhaul ACTIVE for %s (Max Stamina: %.1f).\n============================================================\n", charName, activeMaxStamina))
        end
    end)
end

-- register M with all modifiers
local modifierPermutations = { {} }
if ModifierKey then
    if ModifierKey.SHIFT then table.insert(modifierPermutations, {ModifierKey.SHIFT}) end
    if ModifierKey.CONTROL then table.insert(modifierPermutations, {ModifierKey.CONTROL}) end
    if ModifierKey.ALT then table.insert(modifierPermutations, {ModifierKey.ALT}) end
    if ModifierKey.SHIFT and ModifierKey.CONTROL then
        table.insert(modifierPermutations, {ModifierKey.SHIFT, ModifierKey.CONTROL})
    end
    if ModifierKey.SHIFT and ModifierKey.ALT then
        table.insert(modifierPermutations, {ModifierKey.SHIFT, ModifierKey.ALT})
    end
end

for _, mods in ipairs(modifierPermutations) do
    pcall(function()
        RegisterKeyBindAsync(Key.M, mods, HandleMasterModToggle)
    end)
    pcall(function()
        RegisterKeyBind(Key.M, mods, HandleMasterModToggle)
    end)
end