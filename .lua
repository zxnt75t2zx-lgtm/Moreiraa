LocalScript probado con debug -> pegar en StarterPlayer -> StarterPlayerScripts
-- Modo prueba (rápido): cambia TEST_MODE = false para usar 15 minutos (900s)
local TEST_MODE = true
local TEST_SECONDS = 10
local REAL_SECONDS = 15 * 60 -- 900s

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
    warn("[TP_UI] No se encontró Players.LocalPlayer. Asegúrate de ejecutar en Play (F5).")
    return
end

-- Espera PlayerGui seguro
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("[TP_UI] PlayerGui no apareció en 10s. Revisa que estés en Play y que el jugador exista.")
    return
end

local char = player.Character or player.CharacterAdded:Wait()

-- POSICIONES: editar a tus coordenadas
local positions = {
    CFrame.new(0,5,0),
    CFrame.new(50,5,0),
    CFrame.new(-50,5,0),
    CFrame.new(0,5,50),
    CFrame.new(0,5,-50),
}

local TOTAL_SECONDS = TEST_MODE and TEST_SECONDS or REAL_SECONDS
print(string.format("[TP_UI] TOTAL_SECONDS = %d (TEST_MODE=%s)", TOTAL_SECONDS, tostring(TEST_MODE)))

-- Helper para root con reintento
local function getRoot(retries)
    retries = retries or 5
    char = player.Character or player.CharacterAdded:Wait()
    for i = 1, retries do
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("HumanoidRootPart", true)
        if root then return root end
        wait(0.2)
    end
    return nil
end

-- Crear ScreenGui seguro (si ya existe, reutilizar)
local screenGui = playerGui:FindFirstChild("FullUI_TP_Load")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FullUI_TP_Load"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    print("[TP_UI] ScreenGui creado y parented a PlayerGui")
else
    print("[TP_UI] ScreenGui existente reutilizado")
end

local function makeFullFrame(name)
    local existing = screenGui:FindFirstChild(name)
    if existing then return existing end
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = UDim2.new(1,0,1,0)
    f.Position = UDim2.new(0,0,0,0)
    f.BackgroundColor3 = Color3.fromRGB(0,0,0)
    f.BackgroundTransparency = 0.3
    f.BorderSizePixel = 0
    f.Parent = screenGui
    return f
end

-- Build UI
local insertFrame = makeFullFrame("InsertServer")
local loadingFrame = makeFullFrame("Loading")
local resultsFrame = makeFullFrame("Results")

-- Clear children if exist (solo para evitar duplicados en tests)
for _,f in ipairs({insertFrame, loadingFrame, resultsFrame}) do
    for _,c in ipairs(f:GetChildren()) do c:Destroy() end
end

-- Insert Frame
do
    insertFrame.Visible = true
    local title = Instance.new("TextLabel", insertFrame)
    title.Size = UDim2.new(1,0,0,100)
    title.Position = UDim2.new(0,0,0.18,0)
    title.BackgroundTransparency = 1
    title.Text = "INSERTAR SERVIDOR"
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1,1,1)

    local inputBox = Instance.new("TextBox", insertFrame)
    inputBox.Size = UDim2.new(0.6,0,0,40)
    inputBox.Position = UDim2.new(0.2,0,0.45,0)
    inputBox.PlaceholderText = "Pega aquí el link del servidor (simulado)"
    inputBox.ClearTextOnFocus = false
    inputBox.Text = ""
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextColor3 = Color3.new(0,0,0)
    inputBox.BackgroundColor3 = Color3.fromRGB(255,255,255)

    local insertBtn = Instance.new("TextButton", insertFrame)
    insertBtn.Size = UDim2.new(0.2,0,0,40)
    insertBtn.Position = UDim2.new(0.4,0,0.55,0)
    insertBtn.Text = "INSERTAR"
    insertBtn.Font = Enum.Font.GothamSemibold
    insertBtn.TextColor3 = Color3.new(1,1,1)
    insertBtn.BackgroundColor3 = Color3.fromRGB(27,161,226)

    insertBtn.MouseButton1Click:Connect(function()
        print("[TP_UI] Botón INSERTAR presionado. Link simulado:", inputBox.Text)
        insertFrame.Visible = false
        loadingFrame.Visible = true
        -- reset barra
        local barFill = loadingFrame:FindFirstChild("BarFill")
        if barFill then barFill.Size = UDim2.new(0,0,1,0) end
        local percent = loadingFrame:FindFirstChild("Percent")
        if percent then percent.Text = "0%" end

        -- start progreso
        local start = tick()
        local conn
        conn = RunService.Heartbeat:Connect(function()
            local elapsed = tick() - start
            if elapsed > TOTAL_SECONDS then elapsed = TOTAL_SECONDS end
            local prog = elapsed / TOTAL_SECONDS
            if barFill then pcall(function() barFill.Size = UDim2.new(prog,0,1,0) end) end
            if percent then pcall(function() percent.Text = tostring(math.floor(prog*100)).."%"; end) end
            if elapsed >= TOTAL_SECONDS then
                conn:Disconnect()
                print("[TP_UI] Carga completada")
                loadingFrame.Visible = false
                resultsFrame.Visible = true
                -- Llenar resultados básicos
                local infoBox = resultsFrame:FindFirstChild("InfoBox")
                if infoBox then
                    local lines = {}
                    table.insert(lines, "Resultados simulados:")
                    local ls = player:FindFirstChild("leaderstats")
                    if ls then
                        table.insert(lines, "\nTus leaderstats:")
                        for _,s in ipairs(ls:GetChildren()) do
                            table.insert(lines, string.format("- %s : %s", s.Name, tostring(s.Value)))
                        end
                    else
                        table.insert(lines, "\nLeaderstats: (no visibles)")
                    end
                    -- Backpack
                    table.insert(lines, "\nBackpack (tuyo):")
                    local bp = player:FindFirstChild("Backpack")
                    if bp then
                        local found = false
                        for _,it in ipairs(bp:GetChildren()) do
                            found = true
                            table.insert(lines, "- "..it.Name.." ("..it.ClassName..")")
                        end
                        if not found then table.insert(lines, "(vacío)") end
                    else
                        table.insert(lines, "Backpack no encontrado")
                    end
                    infoBox.Text = table.concat(lines, "\n")
                end
            end
        end)
    end)
end

-- Loading Frame
do
    loadingFrame.Visible = false
    local title = Instance.new("TextLabel", loadingFrame)
    title.Size = UDim2.new(1,0,0,100)
    title.Position = UDim2.new(0,0,0.18,0)
    title.BackgroundTransparency = 1
    title.Text = "CARGANDO BASES..."
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1,1,1)

    local barContainer = Instance.new("Frame", loadingFrame)
    barContainer.Size = UDim2.new(0.8,0,0,28)
    barContainer.Position = UDim2.new(0.1,0,0.55,0)
    barContainer.BackgroundColor3 = Color3.fromRGB(180,180,180)
    barContainer.BorderSizePixel = 0

    local barFill = Instance.new("Frame", barContainer)
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(0,0,1,0)
    barFill.Position = UDim2.new(0,0,0,0)
    barFill.BorderSizePixel = 0
    barFill.BackgroundColor3 = Color3.fromRGB(60,180,75)

    local percentLabel = Instance.new("TextLabel", loadingFrame)
    percentLabel.Name = "Percent"
    percentLabel.Size = UDim2.new(0.2,0,0,30)
    percentLabel.Position = UDim2.new(0.4,0,0.62,0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.TextScaled = true
    percentLabel.Font = Enum.Font.Gotham
    percentLabel.TextColor3 = Color3.new(1,1,1)
    percentLabel.Text = "0%"
end

-- Results Frame
do
    resultsFrame.Visible = false
    local title = Instance.new("TextLabel", resultsFrame)
    title.Size = UDim2.new(1,0,0,60)
    title.Position = UDim2.new(0,0,0.02,0)
    title.BackgroundTransparency = 1
    title.Text = "RESULTADOS (SIMULACIÓN / LOCALES)"
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1,1,1)

    local infoBox = Instance.new("TextBox", resultsFrame)
    infoBox.Name = "InfoBox"
    infoBox.Size = UDim2.new(0.96,0,0.78,0)
    infoBox.Position = UDim2.new(0.02,0,0.12,0)
    infoBox.MultiLine = true
    infoBox.ClearTextOnFocus = false
    infoBox.Text = "Aquí aparecerán los resultados."
    infoBox.TextWrapped = true
    infoBox.Font = Enum.Font.Gotham
    infoBox.TextXAlignment = Enum.TextXAlignment.Left
    infoBox.BackgroundTransparency = 0.2
    infoBox.BorderSizePixel = 0

    local closeBtn = Instance.new("TextButton", resultsFrame)
    closeBtn.Size = UDim2.new(0.18,0,0,36)
    closeBtn.Position = UDim2.new(0.41,0,0.86,0)
    closeBtn.Text = "CERRAR"
    closeBtn.Font = Enum.Font.GothamSemibold
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,39,39)

    closeBtn.MouseButton1Click:Connect(function()
        resultsFrame.Visible = false
        insertFrame.Visible = true
        -- reset barra
        local bf = loadingFrame:FindFirstChild("BarFill")
        if bf then bf.Size = UDim2.new(0,0,1,0) end
        local pct = loadingFrame:FindFirstChild("Percent")
        if pct then pct.Text = "0%" end
    end)
end

-- TP panel con protección (si falla no rompe todo)
do
    local tpPanel = screenGui:FindFirstChild("TPPanel")
    if tpPanel then tpPanel:Destroy() end

    local panel = Instance.new("Frame")
    panel.Name = "TPPanel"
    panel.Size = UDim2.new(0,200,0,230)
    panel.Position = UDim2.new(0,10,0,10)
    panel.BackgroundColor3 = Color3.fromRGB(10,10,10)
    panel.BackgroundTransparency = 0.2
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local tTitle = Instance.new("TextLabel", panel)
    tTitle.Size = UDim2.new(1,0,0,30)
    tTitle.Position = UDim2.new(0,0,0,0)
    tTitle.BackgroundTransparency = 1
    tTitle.Text = "TPS RÁPIDOS"
    tTitle.TextColor3 = Color3.new(1,1,1)
    tTitle.Font = Enum.Font.GothamBold
    tTitle.TextScaled = true

    for i=1,5 do
        local b = Instance.new("TextButton", panel)
        b.Size = UDim2.new(0.9,0,0,36)
        b.Position = UDim2.new(0.05,0,0, 30 + (i-1)*40)
        b.Text = "TP "..i
        b.Font = Enum.Font.Gotham
        b.TextColor3 = Color3.new(1,1,1)
        b.BackgroundColor3 = Color3.fromRGB(52,73,94)
        b.MouseButton1Click:Connect(function()
            local ok, root = pcall(getRoot, 5)
            if not ok or not root then
                warn("[TP_UI] No se encontró HumanoidRootPart para teletransportar.")
                return
            end
            local target = positions[i] or root.CFrame
            -- Teleport seguro
            local success, err = pcall(function() root.CFrame = target end)
            if not success then
                warn("[TP_UI] Error al teletransportar:", err)
            else
                print("[TP_UI] Teleport a TP "..i.." ejecutado.")
            end
        end)
    end
end

-- Mensaje final debug
print("[TP_UI] Script cargado correctamente. Revisa Output si algo falla.")
