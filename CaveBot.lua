local jsonFilename = "C:/Users/Cadu/Documents/ZeroBot/Scripts/Hunts/" -- pasta de waypoints (se nao tiver, crie)
local change_path = "C:/Users/Cadu/Documents/ZeroBot/Scripts/Hunts/issavi.json" -- necessario para um script padrão inicializar
local KeySwitch = "i" -- Defina a tecla de ativação
local waypointIndex = 1 -- Índice do waypoint atual
local isTrackingRunning
local playerName = Player.getName()
local new_path
local file
local prefix = "!"

local minimoadjacente = 3

local responses = { --prefixo do nome das hunts (igual ao json)
    "issavi",
    "grimevip",
    "rodar",
    "bilu",
    "thais"
}


local function getFileNameWithoutExtension(fullPath)
    local backslashes = fullPath:reverse():find("\\") or fullPath:reverse():find("/")
    local fileNameWithExtension = backslashes and fullPath:sub(-backslashes + 1) or fullPath
    local fileNameWithoutExtension = fileNameWithExtension:gsub("%.json$", "")
    return fileNameWithoutExtension
end

local fileNameWithoutExtension = getFileNameWithoutExtension(change_path)
local waypoints = {}

local function loadWaypointsFromJson(filename)
    local file = io.open(filename, "r")
    if not file then
        print("Erro ao abrir o arquivo JSON.")
        return false
    end

    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        print("Conteudo do JSON vazio ou invalido.")
        return false
    end

    local success, decodedData = pcall(JSON.decode, content)

    if not success or type(decodedData) ~= "table" then
        print("Erro ao decodificar waypoints do arquivo JSON.")
        return false
    end

    waypoints = decodedData
    print("Waypoints carregados com sucesso.")
    return true
end

if not loadWaypointsFromJson(change_path) then
    return
end

local function findNearestWaypoint(playerPos)
    local nearestIndex = 1
    local minDistance = math.huge

    for i, waypoint in ipairs(waypoints) do
        local distance = math.sqrt((waypoint.x - playerPos.x)^2 + (waypoint.y - playerPos.y)^2)
        if distance < minDistance then
            minDistance = distance
            nearestIndex = i
        end
    end

    return nearestIndex
end

local function isCreatureAtPosition(pos)
    local creatures = Map.getCreatureIds(true, false) or {}
    for i = 1, #creatures do
        local cid = creatures[i]
        local creature = Creature(cid)
        if creature then
            local creaturePos = creature:getPosition()
            if creaturePos and creaturePos.x == pos.x and creaturePos.y == pos.y and creaturePos.z == pos.z then
                return true
            end
        end
    end
    return false
end

local function useItemOnWaypoints(totalCreatures)
    local delay = 30
    if totalCreatures > 10 then
        delay = 30
    elseif totalCreatures >= 3 then
        delay = 600
    else
        delay = 30
    end

    while waypointIndex <= #waypoints do
        local waypoint = waypoints[waypointIndex]

        if not isCreatureAtPosition(waypoint) then
            Map.goTo(waypoint.x, waypoint.y, waypoint.z)

            local cameraPos = Map.getCameraPosition()
            local dx = math.abs(waypoint.x - cameraPos.x)
            local dy = math.abs(waypoint.y - cameraPos.y)
            local dz = math.abs(waypoint.z - cameraPos.z)
            
            if dx == 0 and dy == 0 and dz == 0 then
                waypointIndex = waypointIndex + 1
            end
            break
        else 
            waypointIndex = waypointIndex + 2

        end
    end

    if waypointIndex > #waypoints then
        waypointIndex = 1
    end
    wait(delay)
end


local player = Creature(Player.getId())

local function Start()

    local playerPos = Map.getCameraPosition()
    local creatures = Map.getCreatureIds(true, false) or {}
    local adjacentCount = 0
    local totalCreatures = 0
    for i = 1, #creatures do
        local cid = creatures[i]
        local creature = Creature(cid)
        if creature then
            local creaturePos = creature:getPosition()
            if creaturePos ~= nil then 
                local dx = math.abs(creaturePos.x - playerPos.x)
                local dy = math.abs(creaturePos.y - playerPos.y)
                local dz = creaturePos.z - playerPos.z
                local creaturename = creature:getName()

                if (dx <= 7 and dy <= 5) and creaturename ~= "Manticore" or creaturename == "Venerable Girtablilu" then
                    totalCreatures = totalCreatures + 1
                end
            end
        end
    end
    if totalCreatures >= 1 then
        for i = -1, 1 do
            for j = -1, 1 do
                if (i ~= 0 or j ~= 0) then
                    local walkable = Map.canWalk(playerPos.x + i, playerPos.y + j, playerPos.z, false, false, false)

                    if not walkable then
                        adjacentCount = adjacentCount + 1
                    end

                    local walkable1 = Map.canWalk(playerPos.x + i, playerPos.y + j, playerPos.z, false, false, true)

                    if not walkable1 then
                        adjacentCount = adjacentCount + 1
                    end
                end
            end
        end
    end

    player = Creature(Player.getId())

    if Player.getState(Enums.States.STATE_FEARED) then
        wait(5000)
    end

    if totalCreatures <= 7 or adjacentCount >= minimoadjacente and not Player.getState(Enums.States.STATE_FEARED) then
        useItemOnWaypoints(totalCreatures)
    end
end

local function startTracking()
    isTrackingRunning = true
    local playerPos = player:getPosition()
    waypointIndex = findNearestWaypoint(playerPos)
    Client.showMessage("bot on")
    print("Rastreamento iniciado.")
end

local function stopTracking()
    isTrackingRunning = false
    Client.showMessage("bot off")
    print("Rastreamento parado.")
end

Timer("Andando", function()
    if isTrackingRunning then
        local connected = Client.isConnected()
        if connected then
            --playernatela()
            Start()
        end
    end
end, 10)

Timer("keyActivation", function()
    local status, modifiers, key = HotkeyManager.parseKeyCombination(KeySwitch)
    if status then
        if Client.isKeyPressed(key, modifiers) then
            if not isTrackingRunning  then
                cavebot:setItemId(37338)
                hudTextSetText(hudId, "Cavebot ON")
                startTracking()
                wait(250)
            else
                cavebot:setItemId(37337)
                hudTextSetText(hudId, "Cavebot OFF ")
                stopTracking()
                wait(250)
            end
        end
    end
end, 10)

-- local playerDetectado = false
-- local cooldownplayer = 0
-- local cooldownTimeplayer = 2

cavebot = HUD.new(60, 780, 3)
cavebot:setItemId(37337)

hudId = hudTextCreate()
hudTextSetText(hudId, "Cavebot OFF ")
hudSetPos(hudId, 125, 772)
hudTextSetColor(hudId,255,255,255)

scripIdHUD = hudTextCreate()
hudTextSetText(scripIdHUD, "(" ..fileNameWithoutExtension.. ")")
hudSetPos(scripIdHUD, 230, 772)
hudTextSetColor(scripIdHUD,127, 255, 0)

local function updateHUD()
    fileNameWithoutExtension = getFileNameWithoutExtension(change_path)
    hudTextSetText(scripIdHUD, "(" ..fileNameWithoutExtension.. ")")
    hudSetPos(scripIdHUD, 230, 772)
    hudTextSetColor(scripIdHUD,127, 255, 0)

    if not loadWaypointsFromJson(change_path) then
        return
    end
end

local function file_exists(name)
    local archive = io.open(jsonFilename, "r")

    if archive then
        archive:close()
    end
    return true
end

local function changeHunt(hunt)
    new_path = jsonFilename .. hunt

    if not file_exists(new_path) then
        print("A hunt " .. hunt .. "não existe no diretorio" .. jsonFilename .. ".")
        Client.showMessage("A hunt " .. hunt .. "não existe no diretorio" .. jsonFilename .. ".")
    end

    change_path = jsonFilename .. hunt
    Client.showMessage("Waypoints trocado para: " .. hunt)
    updateHUD()
end

function onTalk(authorName, authorLevel, type, x, y, z, text)
    if string.lower(authorName) == playerName then
        for _, value in pairs(responses) do
            local new_value = prefix .. value
            if text == new_value then
                file = value .. ".json"
                changeHunt(file)
            end
        end
    end
end

Game.registerEvent(Game.Events.TALK, onTalk)

-- function playernatela()
--     local dir = "C:\\Users\\gewbi\\onedrive\\Documentos\\ZeroBot\\Scripts\\playernatela.wav" -- local do alarme
--     local currentTime = os.time()

--     -- Verifica se o cooldown passou
--     if (currentTime - cooldownplayer) >= cooldownTimeplayer then
--         playerDetectado = false
--         somTocado = false -- Resetar a variável para permitir que o som seja tocado novamente
--     end

--     local creatures1 = Map.getCreatureIds(true, false) or {}
--     for i = 2, #creatures1 do
--         local cid = creatures1[i]
--         local creature1 = Creature(cid)
--         if creature1 and not somTocado then
--             if creature1:getType() == Enums.CreatureTypes.CREATURETYPE_PLAYER then
--                 print(creature1:getId())
--                 Sound.play(dir)
--                 somTocado = true
--                 cooldownplayer = currentTime -- Atualizar o tempo do último cooldown
--             end
--         end
--     end
-- end





local efeitoDetectado = false
local cooldownEfeito = 0
local cooldownTimeEfeito = 1 -- Cooldown de 1 segundo para efeitoDetectado

function onLocalMagicEffect(type, x, y, z)
    local dir = "C:\\Users\\gewbi\\onedrive\\Documentos\\ZeroBot\\Scripts\\gmnatela.wav"
    local currentTime = os.time()

    -- Verifica se o cooldown passou
    if (currentTime - cooldownEfeito) >= cooldownTimeEfeito then
        efeitoDetectado = false
    end

    if type == 56 and not efeitoDetectado then
        Sound.play(dir)
        efeitoDetectado = true
        cooldownEfeito = currentTime -- Atualiza o timestamp do cooldown
    end
end

Game.registerEvent(Game.Events.MAGIC_EFFECT, onLocalMagicEffect)
