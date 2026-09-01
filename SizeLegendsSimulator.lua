-- size legends autofarm -- rshift to toggle menu

local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local lp = Players.LocalPlayer

-- remotes
local Functions = RS:WaitForChild("Functions")
local Events    = RS:WaitForChild("Events")

local PurchaseHandle = Functions:WaitForChild("PurchaseHandle")
local TeleportCheck  = Functions:WaitForChild("TeleportCheck")
local SellSize       = Events:WaitForChild("SellSize")

-- grab item data
local SizeValues = require(RS:WaitForChild("SizeValues"))

local TOOLS, DNA, STAGES = {}, {}, {}

for name, d in pairs(SizeValues.Tools) do
    if type(d) == "table" and d.price and d.strength and not d.gamepass then
        TOOLS[name] = { price = tonumber(d.price), strength = tonumber(d.strength) }
    end
end

for name, d in pairs(SizeValues.DNA) do
    if type(d) == "table" and d.price and d.capacity and not d.gamepass then
        DNA[name] = { price = tonumber(d.price), capacity = tonumber(d.capacity) }
    end
end

-- stages use d.name ("Stage 2") as key -- matches gui children + PurchaseHandle arg
for _, d in pairs(SizeValues.RankValues) do
    if type(d) == "table" and d.name and d.price and d.multiplier then
        STAGES[d.name] = { price = tonumber(d.price), multiplier = tonumber(d.multiplier) }
    end
end

local WORLD_POS = {
    Spawn        = Vector3.new(-141,  0,   2080),
    Candyland    = Vector3.new(-50,   148, 2513),
    Gym          = Vector3.new(-180,  158, 2263),
    Sandland     = Vector3.new(-238,  167, 2403),
    Mushroomland = Vector3.new(-419,  167, 2304),
    Snowland     = Vector3.new(-85,   146, 1745),
    DesertGym    = Vector3.new(216,   145, 1779),
    BeachGym     = Vector3.new(258,   158, 2136),
    JungleGym    = Vector3.new(246,   146, 2452),
    Toyland      = Vector3.new(200,   143, 2840),
    Heaven       = Vector3.new(-117,  149, 2866),
    SakuraGym    = Vector3.new(-387,  148, 2872),
    Spookyland   = Vector3.new(-715,  133, 2835),
    HalloweenGym = Vector3.new(-809,  125, 2483),
    ToxicGym     = Vector3.new(-795,  146, 2149),
    LavaGym      = Vector3.new(-768,  146, 1792),
    VoidGym      = Vector3.new(-423,  145, 1739),
}

-- try workspace zones first for accurate pos, fallback to hardcoded
local function getZonePos(worldName)
    local zones = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Zones")
    if zones then
        local part = zones:FindFirstChild(worldName)
        if part and part:IsA("BasePart") then
            return part.Position
        end
    end
    return WORLD_POS[worldName]
end

-- state
local farmEnabled    = false
local antiHitEnabled = false
local statusText     = "idle"
local function addLog(_) end -- no logs
local menuKey = Enum.KeyCode.RightControl
local listeningForBind = false

-- utils
local function fmtNum(n)
    if not n then return "?" end
    n = tonumber(n) or 0
    if     n >= 1e18 then return string.format("%.2fQi", n/1e18)
    elseif n >= 1e15 then return string.format("%.2fQ",  n/1e15)
    elseif n >= 1e12 then return string.format("%.2fT",  n/1e12)
    elseif n >= 1e9  then return string.format("%.2fB",  n/1e9)
    elseif n >= 1e6  then return string.format("%.2fM",  n/1e6)
    elseif n >= 1e3  then return string.format("%.2fK",  n/1e3)
    else return tostring(math.floor(n)) end
end

local SUFFIX_MULT = {
    ["K"]=1e3,  ["M"]=1e6,  ["B"]=1e9,  ["T"]=1e12,
    ["Qa"]=1e15, ["Qi"]=1e18, ["Sx"]=1e21, ["Sp"]=1e24,
    ["Oc"]=1e27, ["No"]=1e30, ["Dc"]=1e33, ["Ud"]=1e36,
    ["Dd"]=1e39, ["Td"]=1e42, ["Qad"]=1e45,["Qid"]=1e48,
    ["Sxd"]=1e51,["Spd"]=1e54,["Ocd"]=1e57,["Nod"]=1e60,
    ["Vg"]=1e63, ["Uvg"]=1e66,["Dvg"]=1e69,["Tvg"]=1e72,
    -- uppercase variants too just in case
    ["QA"]=1e15, ["QI"]=1e18, ["SX"]=1e21, ["SP"]=1e24,
    ["OC"]=1e27, ["NO"]=1e30, ["DC"]=1e33, ["UD"]=1e36,
    ["DD"]=1e39, ["TD"]=1e42, ["QAD"]=1e45,["QID"]=1e48,
    ["SXD"]=1e51,["SPD"]=1e54,["OCD"]=1e57,["NOD"]=1e60,
    ["VG"]=1e63,
}
local function parseVal(v)
    local s = tostring(v)
    local num, suf = s:match("^([%d%.]+)([A-Za-z]*)$")
    if not num then return 0 end
    num = tonumber(num) or 0
    if suf == "" then return num end
    local m = SUFFIX_MULT[suf] or SUFFIX_MULT[suf:upper()] or SUFFIX_MULT[suf:lower()]
    return m and (num * m) or num
end

local function getStat(name)
    local ls = lp:FindFirstChild("leaderstats")
    if not ls then return 0 end
    local v = ls:FindFirstChild(name)
    return v and parseVal(v.Value) or 0
end

-- best owned weight by strength, owned = tick.visible true
local function getBestOwnedTool()
    local toolsList = lp.PlayerGui:FindFirstChild("ToolsList", true)
    if not toolsList then return nil, 0 end
    local bestName, bestStr = nil, 0
    for _, v in toolsList:GetChildren() do
        if v:IsA("ImageLabel") and TOOLS[v.Name] then
            local tick = v:FindFirstChild("Tick")
            if tick and tick.Visible then
                local s = TOOLS[v.Name].strength
                if s > bestStr then
                    bestStr = s
                    bestName = v.Name
                end
            end
        end
    end
    return bestName, bestStr
end

-- equip best owned weight if we're not already holding it
local function equipBestTool()
    local bestName, bestStr = getBestOwnedTool()
    if not bestName then return end
    -- already got it, skip
    local char = lp.Character
    if char then
        for _, v in char:GetChildren() do
            if v:IsA("Tool") and v.Name == bestName then return end
        end
    end
    -- invoke purchase again so server equips it
    local RS = game:GetService("ReplicatedStorage")
    local PurchaseHandle = RS:WaitForChild("Functions"):WaitForChild("PurchaseHandle")
    PurchaseHandle:InvokeServer(bestName, 1)
    task.wait(0.5)
end

local function getCurrentStrength()
    local _, bestStr = getBestOwnedTool()
    return bestStr
end

-- read active dna cap from strengthtext "cur/max" -- way more reliable than checking tick.visible
-- tick on dna items means something else (not "equipped"), so dont use it
local function getCurrentDNACapacity()
    local strengthText = lp.PlayerGui:FindFirstChild("StrengthText", true)
    if strengthText then
        local cur, max = strengthText.Text:match("^(%d+[%d%.]*[A-Za-z]*)/(%d+[%d%.]*[A-Za-z]*)$")
        if max then
            local parsed = parseVal(max)
            if parsed > 0 then return parsed end
        end
    end
    -- fallback: best purchased dna by lock.visible == false
    local dnasList = lp.PlayerGui:FindFirstChild("DnasList", true)
    if dnasList then
        local best = 0
        for _, v in dnasList:GetChildren() do
            if v:IsA("ImageLabel") and DNA[v.Name] then
                local lock = v:FindFirstChild("Lock")
                if lock and not lock.Visible then
                    local cap = DNA[v.Name].capacity
                    if cap > best then best = cap end
                end
            end
        end
        if best > 0 then return best end
    end
    return 0
end

-- best stage mult we own, owned = tick.visible
local function getCurrentStageMultiplier()
    local ranksList = lp.PlayerGui:FindFirstChild("RanksList", true)
    if not ranksList then return 0 end
    local bestMult = 0
    for _, v in ranksList:GetChildren() do
        if v:IsA("ImageLabel") and STAGES[v.Name] then
            local tick = v:FindFirstChild("Tick")
            if tick and tick.Visible then
                local m = STAGES[v.Name].multiplier
                if m > bestMult then bestMult = m end
            end
        end
    end
    return bestMult
end

-- read cur/max straight from ui bar, dont trust dna table values
local function isSizeFull()
    local txt = lp.PlayerGui:FindFirstChild("Main", true)
    -- Main.Top.Strength.StrengthText
    local strengthText = lp.PlayerGui:FindFirstChild("StrengthText", true)
    if strengthText then
        local cur, max = strengthText.Text:match("^(%d+[%d%.]*[A-Za-z]*)/(%d+[%d%.]*[A-Za-z]*)$")
        if cur and max then
            return parseVal(cur) >= parseVal(max)
        end
    end
    -- fallback if we cant find the text (old logic, kinda unreliable)
    local size = getStat("Size")
    local cap  = getCurrentDNACapacity()
    return cap > 0 and size >= cap
end

local function getBestWorld(currentSize)
    local best, bestMult = "Spawn", 1
    for world, d in pairs(SizeValues.WorldCriterias) do
        if WORLD_POS[world] then
            local req  = tonumber(d.size) or 0
            local mult = tonumber(d.multiplier) or 1
            if currentSize >= req and mult > bestMult then
                bestMult = mult
                best     = world
            end
        end
    end
    return best
end

local SELL_POS = Vector3.new(-112, -28, 2043)

-- anti-hit state (declared before ensurePositionLoop so Heartbeat closure can read them)
local antiHitConn    = nil  -- not used as connection anymore, kept for compat
local antiHitBasePos = nil
local antiHitNextTp  = 0

local function randomInsideZone(center)
    -- uniform random point inside sphere of radius 60 around zone center (all XYZ axes)
    local r     = math.random() * 60
    local theta = math.random() * 2 * math.pi          -- azimuth
    local phi   = math.acos(2 * math.random() - 1)     -- inclination, uniform on sphere
    local dx    = r * math.sin(phi) * math.cos(theta)
    local dy    = r * math.sin(phi) * math.sin(theta)
    local dz    = r * math.cos(phi)
    return Vector3.new(center.X + dx, center.Y + dy, center.Z + dz)
end

-- unified position lock: one Heartbeat handles both freeze and anti-hit
-- priority: anti-hit > freeze
local freezeConnection = nil
local freezeTarget     = nil

local function ensurePositionLoop()
    if freezeConnection then return end
    freezeConnection = RunService.Heartbeat:Connect(function()
        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp then return end

        -- always kill physics so nothing drifts
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end

        -- anti-hit: teleport to random zone point on its own timer
        if antiHitEnabled and antiHitBasePos then
            local now = os.clock()
            if now >= antiHitNextTp then
                antiHitNextTp = now + 0.05  -- new random point every 50ms
                hrp.CFrame = CFrame.new(randomInsideZone(antiHitBasePos))
            end
            return  -- don't pin to freezeTarget, anti-hit owns the position
        end

        -- plain freeze: pin to zone center
        if freezeTarget then
            hrp.CFrame = CFrame.new(freezeTarget)
        end
    end)
end

local function startFreeze(pos)
    freezeTarget = pos
    ensurePositionLoop()
end

local function stopFreeze()
    freezeTarget = nil
    if freezeConnection then
        freezeConnection:Disconnect()
        freezeConnection = nil
    end
    local char = lp.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end
end

local function startAntiHit(basePos)
    antiHitBasePos = basePos
    antiHitNextTp  = 0  -- fire immediately on next Heartbeat tick
end

local function stopAntiHit()
    antiHitBasePos = nil
    antiHitNextTp  = 0
end

local function teleportToWorld(worldName)
    local pos  = getZonePos(worldName)
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not pos or not hrp then return end
    -- tp then lock, dont anchor
    hrp.CFrame = CFrame.new(pos)
    task.wait(0.1) -- let server register the touch
    startFreeze(pos)
    -- kick off anti-hit jitter if enabled, centered on zone pos
    if antiHitEnabled then
        startAntiHit(pos)
    end
end

local function teleportToSell()
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    stopAntiHit()
    stopFreeze()
    hrp.CFrame = CFrame.new(Vector3.new(-112, -23, 2043))
    task.wait(0.8)
end

-- cheapest upgrade above current level across weights, dna, stages
local function getNextBuy(strength, dnaCapacity, stageMult)
    local best, bestPrice = nil, math.huge

    -- next weight: stronger than what we have, cheapest
    for name, d in pairs(TOOLS) do
        if d.price > 0 and d.strength > strength and d.price < bestPrice then
            bestPrice = d.price
            best = {name=name, price=d.price, page=1, kind="weight"}
        end
    end
    -- next dna: higher cap, cheapest
    for name, d in pairs(DNA) do
        if d.price > 0 and d.capacity > dnaCapacity and d.price < bestPrice then
            bestPrice = d.price
            best = {name=name, price=d.price, page=2, kind="dna"}
        end
    end
    -- next stage: higher mult, cheapest
    for name, d in pairs(STAGES) do
        if d.price > 0 and d.multiplier > stageMult and d.price < bestPrice then
            bestPrice = d.price
            best = {name=name, price=d.price, page=3, kind="stage"}
        end
    end
    return best
end


-- tool equip + activation events
local ToolActivation = Events:WaitForChild("ToolActivation")
local ToolEquipped   = Events:WaitForChild("ToolEquipped")

-- skip these when scanning for the weight tool
local COMBAT_TOOLS = { CombatPunch = true, CombatStomp = true }

-- currently equipped weight or nil
local function getEquippedWeight()
    local char = lp.Character
    if not char then return nil end
    for _, v in char:GetChildren() do
        if v:IsA("Tool") and not COMBAT_TOOLS[v.Name] then
            return v
        end
    end
    return nil
end

-- best weight sitting in backpack by strength
local function getBestWeightInBackpack()
    local bp = lp:FindFirstChildOfClass("Backpack")
    if not bp then return nil end
    local bestTool, bestStr = nil, -1
    for _, v in bp:GetChildren() do
        if v:IsA("Tool") and not COMBAT_TOOLS[v.Name] then
            local d = TOOLS[v.Name]
            local s = d and d.strength or 0
            if s > bestStr then
                bestStr = s
                bestTool = v
            end
        end
    end
    return bestTool
end

-- every frame: make sure weight is equipped then spam activate
RunService.Heartbeat:Connect(function()
    if not farmEnabled then return end
    local char = lp.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- nothing in hand, grab best from backpack
    local equipped = getEquippedWeight()
    if not equipped then
        local best = getBestWeightInBackpack()
        if best then
            hum:EquipTool(best)
            ToolEquipped:FireServer(best.Name)
        end
        return -- wait for next frame
    end

    -- got weight, fire lift
    ToolActivation:FireServer(equipped.Name)
end)

-- main farm loop
local farmRunning = false
local function farmLoop()
    if farmRunning then return end
    farmRunning = true
    while farmEnabled do
        -- if char is gone (died), stop and let CharacterAdded restart us
        if not lp.Character then
            task.wait(0.5)
            break
        end
        local ok, err = pcall(function()
            local coins       = getStat("Coins")
            local size        = getStat("Size")
            local strength    = getCurrentStrength()
            local dnaCapacity = getCurrentDNACapacity()
            local stageMult   = getCurrentStageMultiplier()

            -- make sure best weight is on
            equipBestTool()
            strength = getCurrentStrength()

            -- go to best zone
            local world = getBestWorld(size)
            teleportToWorld(world)

            -- whats next to buy
            local nextItem = getNextBuy(strength, dnaCapacity, stageMult)
            if not nextItem then
                statusText = "farming | "..world.." | all bought"
                addLog("all bought, farming...")
                task.wait(3)
                return
            end

            statusText = "farming | "..world.." -> "..nextItem.name.." ("..fmtNum(nextItem.price)..")"

            -- grind until coins+size covers it or size bar maxes out
            while farmEnabled do
                coins       = getStat("Coins")
                size        = getStat("Size")
                strength    = getCurrentStrength()
                dnaCapacity = getCurrentDNACapacity()
                stageMult   = getCurrentStageMultiplier()

                -- zone might've changed
                local newWorld = getBestWorld(size)
                if newWorld ~= world then
                    world = newWorld
                    teleportToWorld(world)
                    addLog("switched zone: "..world)
                end

                -- recheck target
                nextItem = getNextBuy(strength, dnaCapacity, stageMult)
                if not nextItem then
                    addLog("all bought, farming...")
                    task.wait(1)
                    break
                end

                -- coins + size we can sell
                local totalBalance = coins + size
                local sizeFull     = isSizeFull()

                statusText = string.format(
                    "%s | coins %s + size %s = %s / need %s | %s",
                    world, fmtNum(coins), fmtNum(size), fmtNum(totalBalance),
                    fmtNum(nextItem.price), nextItem.name
                )

                -- can afford it or size bar full, go sell
                if totalBalance >= nextItem.price or sizeFull then
                    if sizeFull then addLog("size full, heading to sell") end
                    break
                end

                task.wait(1)
            end

            if not farmEnabled then return end

            -- sell
            teleportToSell()
            addLog("selling | size="..fmtNum(size).." need="..fmtNum(nextItem.price))
            SellSize:FireServer()
            task.wait(0.8)
            coins = getStat("Coins")

            -- buy loop, keep buying until we cant afford anything
            local boughtAny = true
            while boughtAny and farmEnabled do
                boughtAny = false
                strength    = getCurrentStrength()
                dnaCapacity = getCurrentDNACapacity()
                stageMult   = getCurrentStageMultiplier()

                local item = getNextBuy(strength, dnaCapacity, stageMult)
                if item and coins >= item.price then
                    addLog("buy "..item.kind..": "..item.name.." ("..fmtNum(item.price)..")")
                    PurchaseHandle:InvokeServer(item.name, item.page)
                    task.wait(0.5)
                    coins       = getStat("Coins")
                    strength    = getCurrentStrength()
                    dnaCapacity = getCurrentDNACapacity()
                    stageMult   = getCurrentStageMultiplier()
                    equipBestTool()
                    boughtAny = true
                end
            end

            -- back to farming
            size  = getStat("Size")
            world = getBestWorld(size)
            teleportToWorld(world)
            addLog("back to "..world)
        end)
        if not ok then
            addLog("err: "..tostring(err):sub(1, 60))
            task.wait(2)
        end
    end
    farmRunning = false
    statusText = "idle"
end

-- gui
local old = lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("SizeFarmGUI")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "SizeFarmGUI"
screenGui.ResetOnSpawn   = false
screenGui.DisplayOrder   = 999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = lp:WaitForChild("PlayerGui")

-- main card
local CARD_W = 280
local main = Instance.new("Frame")
main.Name             = "Main"
main.Size             = UDim2.new(0, CARD_W, 0, 220)
main.Position         = UDim2.new(0.5, -CARD_W/2, 0.5, -110)
main.BackgroundColor3 = Color3.fromRGB(242, 242, 247)
main.BorderSizePixel  = 0
main.Visible          = true
main.Parent           = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", main)
stroke.Color     = Color3.fromRGB(200, 200, 210)
stroke.Thickness = 0.8

-- header / drag zone
local header = Instance.new("Frame")
header.Name                   = "Header"
header.Size                   = UDim2.new(1, 0, 0, 44)
header.BackgroundTransparency = 1
header.Parent                 = main

local titleLbl = Instance.new("TextLabel")
titleLbl.Size                   = UDim2.new(1, -20, 1, 0)
titleLbl.Position               = UDim2.new(0, 16, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                   = "Auto Farm"
titleLbl.TextColor3             = Color3.fromRGB(10, 10, 15)
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextSize               = 15
titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
titleLbl.Parent                 = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size                   = UDim2.new(0, 13, 0, 13)
closeBtn.Position               = UDim2.new(1, -22, 0, 15)
closeBtn.BackgroundColor3       = Color3.fromRGB(255, 95, 86)
closeBtn.Text                   = ""
closeBtn.BorderSizePixel        = 0
closeBtn.ZIndex                 = 10
closeBtn.AutoButtonColor        = false
closeBtn.Parent                 = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.5, 0)

closeBtn.MouseButton1Click:Connect(function()
    farmEnabled    = false
    antiHitEnabled = false
    stopAntiHit()
    stopFreeze()
    screenGui:Destroy()
end)

-- divider helper
local function makeDivider(parent, yPos)
    local d = Instance.new("Frame")
    d.Size             = UDim2.new(1, -16, 0, 0.5)
    d.Position         = UDim2.new(0, 8, 0, yPos)
    d.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
    d.BorderSizePixel  = 0
    d.Parent           = parent
end

-- toggle row factory
local TOGGLE_W, TOGGLE_H = 50, 30
local KNOB_OFF = 2
local KNOB_ON  = TOGGLE_W - (TOGGLE_H - 4) - 2

local function makeToggleRow(parent, yPos, labelText)
    local row = Instance.new("Frame")
    row.Size                   = UDim2.new(1, 0, 0, 52)
    row.Position               = UDim2.new(0, 0, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent                 = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -80, 1, 0)
    lbl.Position               = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = labelText
    lbl.TextColor3             = Color3.fromRGB(10, 10, 15)
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextSize               = 14
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Parent                 = row

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, TOGGLE_W, 0, TOGGLE_H)
    track.Position         = UDim2.new(1, -(TOGGLE_W + 14), 0.5, -TOGGLE_H/2)
    track.BackgroundColor3 = Color3.fromRGB(209, 209, 214)
    track.BorderSizePixel  = 0
    track.Parent           = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, TOGGLE_H/2)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, TOGGLE_H - 4, 0, TOGGLE_H - 4)
    knob.Position         = UDim2.new(0, KNOB_OFF, 0, 2)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 2
    knob.Parent           = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5, 0)

    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(0, TOGGLE_W, 0, TOGGLE_H)
    btn.Position               = UDim2.new(1, -(TOGGLE_W + 14), 0.5, -TOGGLE_H/2)
    btn.BackgroundTransparency = 1
    btn.Text                   = ""
    btn.ZIndex                 = 3
    btn.AutoButtonColor        = false
    btn.Parent                 = row

    local function setVisual(on)
        TweenService:Create(track, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
            BackgroundColor3 = on and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(209, 209, 214)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0, on and KNOB_ON or KNOB_OFF, 0, 2)
        }):Play()
    end

    return btn, setVisual
end

-- layout: header=44, div=44, farm row=52, div=96, antihit row=52, div=148, keybind row=52, total=200+padding
makeDivider(main, 44)

local farmToggleBtn, setFarmVisual = makeToggleRow(main, 44, "Auto Farm")

makeDivider(main, 96)

local antiHitToggleBtn, setAntiHitVisual = makeToggleRow(main, 96, "Anti Hit")

makeDivider(main, 148)

-- keybind row
local bindRow = Instance.new("Frame")
bindRow.Size                   = UDim2.new(1, 0, 0, 52)
bindRow.Position               = UDim2.new(0, 0, 0, 148)
bindRow.BackgroundTransparency = 1
bindRow.Parent                 = main

local bindLabel = Instance.new("TextLabel")
bindLabel.Size                   = UDim2.new(1, -90, 1, 0)
bindLabel.Position               = UDim2.new(0, 16, 0, 0)
bindLabel.BackgroundTransparency = 1
bindLabel.Text                   = "Menu Key"
bindLabel.TextColor3             = Color3.fromRGB(10, 10, 15)
bindLabel.Font                   = Enum.Font.Gotham
bindLabel.TextSize               = 14
bindLabel.TextXAlignment         = Enum.TextXAlignment.Left
bindLabel.Parent                 = bindRow

local bindBtn = Instance.new("TextButton")
bindBtn.Size             = UDim2.new(0, 68, 0, 28)
bindBtn.Position         = UDim2.new(1, -(68 + 14), 0.5, -14)
bindBtn.BackgroundColor3 = Color3.fromRGB(229, 229, 234)
bindBtn.Text             = "RCtrl"
bindBtn.TextColor3       = Color3.fromRGB(10, 10, 15)
bindBtn.Font             = Enum.Font.GothamSemibold
bindBtn.TextSize         = 12
bindBtn.BorderSizePixel  = 0
bindBtn.ZIndex           = 4
bindBtn.AutoButtonColor  = false
bindBtn.Parent           = bindRow
Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 8)

bindBtn.MouseButton1Down:Connect(function()
    TweenService:Create(bindBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 62, 0, 25)
    }):Play()
end)
bindBtn.MouseButton1Up:Connect(function()
    TweenService:Create(bindBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 68, 0, 28)
    }):Play()
end)

local dotsConn = nil
local function startDotsAnim()
    local t = 0
    dotsConn = RunService.Heartbeat:Connect(function(dt)
        t = t + dt
        local frame = math.floor(t * 2) % 3 + 1
        bindBtn.Text = string.rep(".", frame)
    end)
end
local function stopDotsAnim()
    if dotsConn then dotsConn:Disconnect(); dotsConn = nil end
end

bindBtn.MouseButton1Click:Connect(function()
    if listeningForBind then return end
    listeningForBind = true
    startDotsAnim()
    task.delay(5, function()
        if listeningForBind then
            listeningForBind = false
            stopDotsAnim()
            bindBtn.Text = tostring(menuKey):gsub("Enum%.KeyCode%.", "")
        end
    end)
end)

-- wire toggle buttons
farmToggleBtn.MouseButton1Click:Connect(function()
    farmEnabled = not farmEnabled
    setFarmVisual(farmEnabled)
    if farmEnabled then
        task.spawn(farmLoop)
    else
        stopAntiHit()
        stopFreeze()
    end
end)

antiHitToggleBtn.MouseButton1Click:Connect(function()
    antiHitEnabled = not antiHitEnabled
    setAntiHitVisual(antiHitEnabled)
    if antiHitEnabled then
        -- if farm is already frozen in a zone, kick off anti-hit immediately
        if farmEnabled and freezeTarget then
            startAntiHit(freezeTarget)
        end
    else
        stopAntiHit()
    end
end)

-- detect mobile
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobile then
    bindRow.Visible = false
    main.Size = UDim2.new(0, CARD_W, 0, 160)
end

-- generic drag helper, works for both mouse and touch
local function makeDraggable(handle, target)
    local dragging   = false
    local dragStart  = nil
    local frameStart = nil

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            dragStart  = inp.Position
            frameStart = target.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - dragStart
            target.Position = UDim2.new(
                frameStart.X.Scale, frameStart.X.Offset + d.X,
                frameStart.Y.Scale, frameStart.Y.Offset + d.Y
            )
        end
    end)
end

makeDraggable(header, main)

if isMobile then
    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Name             = "MobileToggle"
    mobileBtn.Size             = UDim2.new(0, 50, 0, 50)
    mobileBtn.Position         = UDim2.new(0, 20, 0.5, -25)
    mobileBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    mobileBtn.BorderSizePixel  = 0
    mobileBtn.Text             = "AF"
    mobileBtn.TextColor3       = Color3.fromRGB(10, 10, 15)
    mobileBtn.Font             = Enum.Font.GothamBold
    mobileBtn.TextSize         = 18
    mobileBtn.ZIndex           = 10
    mobileBtn.AutoButtonColor  = false
    mobileBtn.Parent           = screenGui
    Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(0, 12)

    local mobileStroke = Instance.new("UIStroke", mobileBtn)
    mobileStroke.Color     = Color3.fromRGB(200, 200, 210)
    mobileStroke.Thickness = 0.8

    local mobileBtnDragged = false

    mobileBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            mobileBtnDragged = false
            local startPos = inp.Position
            local movedConn
            movedConn = inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    movedConn:Disconnect()
                elseif (inp.Position - startPos).Magnitude > 10 then
                    mobileBtnDragged = true
                end
            end)
        end
    end)

    mobileBtn.MouseButton1Click:Connect(function()
        if mobileBtnDragged then return end
        main.Visible = not main.Visible
    end)

    makeDraggable(mobileBtn, mobileBtn)
end

if not isMobile then
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if listeningForBind then
            local newKey = nil
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                newKey = inp.KeyCode
            end
            if newKey and newKey ~= Enum.KeyCode.Unknown then
                menuKey = newKey
                listeningForBind = false
                stopDotsAnim()
                local raw = tostring(newKey):gsub("Enum%.KeyCode%.", "")
                local shorts = {
                    RightShift="RShift", LeftShift="LShift",
                    RightControl="RCtrl", LeftControl="LCtrl",
                    RightAlt="RAlt", LeftAlt="LAlt",
                    RightMeta="RMeta", LeftMeta="LMeta",
                    BackSpace="Back", Return="Enter",
                }
                bindBtn.Text = shorts[raw] or raw
            end
            return
        end
        if not gpe and inp.KeyCode == menuKey then
            main.Visible = not main.Visible
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if not main.Visible then return end
end)

-- anti-afk, only fires when roblox is about to kick, always active
local VirtualUser = game:GetService("VirtualUser")
lp.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
end)

-- respawn handler
lp.CharacterAdded:Connect(function(char)
    -- wait for hrp and humanoid to exist
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hrp or not hum then return end

    -- kill old freeze conn, its holding a ref to the dead char
    if freezeConnection then
        freezeConnection:Disconnect()
        freezeConnection = nil
    end
    freezeTarget = nil

    -- farmRunning might still be true from the old loop that died mid-pcall
    -- reset it so farmLoop() doesnt exit immediately
    farmRunning = false

    if farmEnabled then
        -- wait for humanoid to fully land before we teleport
        -- Died fires after char is added, wait for it to flip back to None
        local died = false
        local conn
        conn = hum.Died:Connect(function() died = true end)

        -- wait until health is full and state is Running/Idle (not falling)
        local t = 0
        repeat
            task.wait(0.1)
            t = t + 0.1
        until (hum.Health >= hum.MaxHealth * 0.9
            and hum:GetState() ~= Enum.HumanoidStateType.Freefall
            and hum:GetState() ~= Enum.HumanoidStateType.Jumping)
            or t > 6

        conn:Disconnect()

        if farmEnabled and not died then
            task.spawn(farmLoop)
        end
    end
end)
