local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESPConnections = {}
local Boxes = {} -- Store the created boxes
local ESPEnabled = true -- Flag to track whether ESP is enabled or not

local function createBox()
    local Outline = Drawing.new("Square")
    Outline.Visible = true
    Outline.Color = Color3.fromRGB(0, 0, 0)
    Outline.Thickness = 2
    Outline.Transparency = 1
    Outline.Filled = false

    local Box = Drawing.new("Square")
    Box.Visible = true
    Box.Color = Color3.fromRGB(255, 0, 0)
    Box.Thickness = 1
    Box.Transparency = 1
    Box.Filled = false

    return Box, Outline
end

local function updateBox(Box, Outline, target)
    local targetPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(target.Position)
    if onScreen then
        local headPos = workspace.CurrentCamera:WorldToViewportPoint(target.Position + Vector3.new(0, 2, 0))
        local legPos = workspace.CurrentCamera:WorldToViewportPoint(target.Position - Vector3.new(0, 3, 0))
        local size = Vector2.new(1200 / targetPos.Z, headPos.Y - legPos.Y)
        Box.Size = size
        Box.Position = Vector2.new(targetPos.X - size.X / 2, targetPos.Y - size.Y / 2)
        Outline.Size = size
        Outline.Position = Box.Position
        Box.Visible = true
        Outline.Visible = true
    else
        Box.Visible = false
        Outline.Visible = false
    end
end

local function addESP(player)
    if player ~= LocalPlayer then
        -- Check if ESP is enabled before adding the box
        if ESPEnabled then
            -- Check if the player's box is already created
            for _, box in ipairs(Boxes) do
                if box.Player == player then
                    return -- Skip adding ESP for existing players
                end
            end

            local character = player.Character or player.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            local Box, Outline = createBox()
            
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if character and humanoidRootPart and player.Parent then
                    updateBox(Box, Outline, humanoidRootPart)
                else
                    Box.Visible = false
                    Outline.Visible = false
                    if not player.Parent then
                        connection:Disconnect()
                        Box:Remove()
                        Outline:Remove()
                        -- Remove from ESPConnections and Boxes tables
                        for i, conn in ipairs(ESPConnections) do
                            if conn == connection then
                                table.remove(ESPConnections, i)
                                break
                            end
                        end
                        for i, b in ipairs(Boxes) do
                            if b.Player == player then
                                table.remove(Boxes, i)
                                break
                            end
                        end
                    end
                end
            end)
            
            table.insert(ESPConnections, connection) -- Store the connection for later cleanup
            table.insert(Boxes, {Box = Box, Outline = Outline, Player = player}) -- Store the created box and outline
        end
    end
end

local function toggleESP()
    -- Toggle the ESP flag
    ESPEnabled = not ESPEnabled

    -- Disconnect rendering connections
    for _, connection in ipairs(ESPConnections) do
        connection:Disconnect()
    end
    ESPConnections = {} -- Clear the connections table
    
    -- Make the boxes invisible
    for _, box in ipairs(Boxes) do
        local Box, Outline = box.Box, box.Outline
        Box.Visible = false
        Outline.Visible = false
    end
end

local function onPlayerAdded(player)
    addESP(player)
    player.CharacterAdded:Connect(function()
        addESP(player)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
    local espObjects = player:GetAttribute("ESPObjects")
    if espObjects then
        for _, object in pairs(espObjects) do
            object:Remove()
        end
    end
end)
