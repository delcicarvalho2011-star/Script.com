--[[
    SISTEMA INTEGRADO: AIMBOT, ESP COMPOSITE E ANTI-AIM
    Finalidade: Estudos de programação e lógica de vetores.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- CONFIGURAÇÕES
local Config = {
    AimActive = true,
    EspActive = true,
    AntiAimActive = true,
    AimFOV = 150,
    AimSmoothing = 0.5,
    TeamCheck = true
}

-- 1. SISTEMA ESP (Box e Tracers)
local function CreateESP(Player)
    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.new(1, 0, 0)
    Box.Thickness = 1
    Box.Filled = false

    local Tracer = Drawing.new("Line")
    Tracer.Visible = false
    Tracer.Color = Color3.new(1, 1, 1)
    Tracer.Thickness = 1

    RunService.RenderStepped:Connect(function()
        if Config.EspActive and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player ~= LocalPlayer then
            local RootPart = Player.Character.HumanoidRootPart
            local Pos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)

            if OnScreen then
                -- Configurar Box
                Box.Size = Vector2.new(1000 / Pos.Z, 1500 / Pos.Z)
                Box.Position = Vector2.new(Pos.X - Box.Size.X / 2, Pos.Y - Box.Size.Y / 2)
                Box.Visible = true

                -- Configurar Tracer
                Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                Tracer.To = Vector2.new(Pos.X, Pos.Y)
                Tracer.Visible = true
            else
                Box.Visible = false
                Tracer.Visible = false
            end
        else
            Box.Visible = false
            Tracer.Visible = false
        end
    end)
end

-- 2. SISTEMA AIM (Aimbot Suave)
local function GetClosestPlayer()
    local Target = nil
    local ShortestDistance = Config.AimFOV

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
            if Config.TeamCheck and v.Team == LocalPlayer.Team then continue end
            
            local Pos, OnScreen = Camera:WorldToViewportPoint(v.Character.Head.Position)
            local Distance = (Vector2.new(Pos.X, Pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

            if OnScreen and Distance < ShortestDistance then
                ShortestDistance = Distance
                Target = v
            end
        end
    end
    return Target
end

RunService.RenderStepped:Connect(function()
    if Config.AimActive and Mouse.Target ~= nil then -- Ativa quando o mouse foca em algo ou você pode bindar a uma tecla
        local Target = GetClosestPlayer()
        if Target then
            local TargetPos = Target.Character.Head.Position
            local CurrentCamCFrame = Camera.CFrame
            local AimCFrame = CFrame.new(CurrentCamCFrame.Position, TargetPos)
            Camera.CFrame = CurrentCamCFrame:Lerp(AimCFrame, Config.AimSmoothing)
        end
    end
end)

-- 3. SISTEMA ANTI-AIM (Desync/Hitbox Manipulation)
-- Nota: Isso modifica a orientação do RootPart para tentar "confundir" o registro de tiro do servidor
local function AntiAim()
    RunService.Heartbeat:Connect(function()
        if Config.AntiAimActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local Root = LocalPlayer.Character.HumanoidRootPart
            
            -- Faz o personagem girar rapidamente ou inclinar para desviar o hit de scripts de terceiros
            -- Isso dificulta que a posição do HumanoidRootPart seja lida corretamente por armas de raycast simples
            Root.CFrame = Root.CFrame * CFrame.Angles(0, math.rad(70), 0) 
            
            -- Simulação de "No Damage" via CFrame Offset
            -- Aviso: Em muitos jogos, isso causará "Rubber Banding" ou Kick por anti-cheat
            -- Root.CFrame = Root.CFrame + Vector3.new(0, 500, 0) -- Move para longe e volta (exemplo teórico)
        end
    end)
end

-- INICIALIZAÇÃO
for _, p in pairs(Players:GetPlayers()) do
    CreateESP(p)
end
Players.PlayerAdded:Connect(CreateESP)
AntiAim()

print("Sistema Carregado com Sucesso.")
