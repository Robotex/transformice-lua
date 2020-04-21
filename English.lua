-- Configuration settings
local g_config = {
    admins = {"Junny1992#0000", "Ruka#0823"},
    spawn = { x = 0, y = 0 },
    spawnAreas = {
        SECOND_FLOOR = {x = 855, y = 162},
        START = {x = 20, y = 370}
    },
    toysAreas = {
        {x1 = 1458, y1 = 297, x2 = 1590, y2 = 370}
    },
    packingAreas = {
        {x1 = 954, y1 = 315, x2 = 1033, y2 = 345},
        {x1 = 1114, y1 = 315, x2 = 1228, y2 = 345}
    },
    dropOffAreas = {
        {x1 = 109, y1 = 285, x2 = 284, y2 = 384}
    },
    minigameChars = {"q","u","o","p","f","g","h","j","k","l","z","x","c","v","b","n","m"},
    map = "@7550816",
    doorId = 10
}

-- Local globals
local g_players = {}
local g_lastTick = 0
local g_timers = {}
local g_gameState = 0
local g_textAreaIds = {
    countdown = 1,
    inventory = 2,
    toast = 3,
    scoreboard = 4,
    hint = 5
}

-- Utilities
local function isAdministrator(playerName)
    for _, adminName in ipairs(g_config.admins)
    do
        if adminName == playerName then
            return true
        end
    end
    return false
end

local function addTimer(callback, startDelay, loop, ...)
    if callback == nil then
        print ("Warning: null callback in addTimer")
        return
    end
    local timer = {
        callback = callback,
        startDelay = startDelay,
        loop = loop,
        args = ...,
        createdTime = g_lastTick,
        expired = false
    }
    table.insert(g_timers, timer)
    return #g_timers
end

local function showToast(text, duration, playerName)
    ui.addTextArea(g_textAreaIds.toast, text, playerName, 300, 250, 200, 20, 0x324650, 0x000000, 0.6, true)
    addTimer(function()
        ui.removeTextArea(g_textAreaIds.toast, playerName)
    end, duration, false)
end

-- Script core logic
local function addPlayer(playerName)
    local player = g_players[playerName]
    if player == nil then
        print("New player: " .. playerName)
        player = {
            name = playerName,
            carrying = 0,
            score = 0,
            minigame = {
                nextKeyCode = 0,
                combo = 0
            }
        }
        g_players[playerName] = player
    end
    tfm.exec.setPlayerScore(playerName, player.score, false)
    system.bindKeyboard(playerName, 32, true, true)
    system.bindKeyboard(playerName, 1, false, true)
    system.bindKeyboard(playerName, 2, false, true)
    system.bindKeyboard(playerName, 3, false, true)
    system.bindKeyboard(playerName, 4, false, true)
    system.bindKeyboard(playerName, 1, true, true)
    system.bindKeyboard(playerName, 2, true, true)
    system.bindKeyboard(playerName, 3, true, true)
    system.bindKeyboard(playerName, 4, true, true)

    for _, char in ipairs(g_config.minigameChars) do
        local keyCode = string.byte(string.upper(char), 1)
        system.bindKeyboard(playerName, keyCode, true, true)
    end
end

local function resetPlayer(playerName)
    local player = g_players[playerName]
    if player ~= nil then
        player.nextKeyCode = 0
        player.carrying = 0
        player.combo = 0
        eventNewPlayer(playerName)
        tfm.exec.killPlayer(playerName)
    end
end

local function removePlayer(playerName)
    local player = g_players[playerName]
    if player ~= nil then
        ui.removeTextArea(g_textAreaIds.inventory, playerName)
        system.bindKeyboard(playerName, 32, true, false)
        g_players[playerName] = nil
    end
end

local function increasePlayerScore(playerName)
    local player = g_players[playerName]
    if player ~= nil then
        g_players[playerName].score = g_players[playerName].score + 1
        tfm.exec.setPlayerScore(playerName, g_players[playerName].score, false)
    end
end

local function isPlayer(playerName)
    return g_players[playerName] ~= nil
end

local function openDoor()
    tfm.exec.removePhysicObject(g_config.doorId)
end

local function startGame()
    g_gameState = 2
    tfm.exec.setGameTime(300)
    openDoor()
end

local function resetGame()
    for _, id in pairs(g_textAreaIds) do
        ui.removeTextArea(id, nil)
    end

    tfm.exec.newGame(g_config.map)
    tfm.exec.setUIMapName("Greenwolves - Christmas 2018")
    tfm.exec.setGameTime(0)

    g_gameState = 0
    g_players = {}

    g_config.spawn = g_config.spawnAreas.START

    for playerName, _ in pairs(tfm.get.room.playerList)
    do
        eventNewPlayer(playerName)
        tfm.exec.setPlayerScore(playerName, 0, false)
        tfm.exec.killPlayer(playerName)
    end
end

local function endGame()
    local highscores = {
        [1] = {},
        [2] = {},
        [3] = {}
    }
    local scoreboard = {}

    g_gameState = 3
    g_config.spawn = g_config.spawnAreas.SECOND_FLOOR
    for playerName, _ in pairs(tfm.get.room.playerList)
    do
        tfm.exec.killPlayer(playerName)
    end

    for playerName, player in pairs(g_players)
    do
        table.insert(scoreboard, player)
    end

    table.sort(scoreboard, function(a,b) return a.score>b.score end)

    local highscorePosition = 1
    for i=1, #scoreboard do
        print ("[" .. scoreboard[i].score .. "] " .. scoreboard[i].name)
        table.insert(highscores[highscorePosition], scoreboard[i])
        if i < #scoreboard then
            if scoreboard[i + 1].score ~= scoreboard[i].score then
                highscorePosition = highscorePosition + 1
            end
        end
        if highscorePosition > 3 then
            break
        end
    end

    local scoreboardText = "1. "
    for _, player in ipairs(highscores[1]) do
        scoreboardText = scoreboardText .. "[" .. player.name .. "]"
    end
    scoreboardText = scoreboardText .. "<br>2. "
    for _, player in ipairs(highscores[2]) do
        scoreboardText = scoreboardText .. "[" .. player.name .. "]"
    end
    scoreboardText = scoreboardText .. "<br>3. "
    for _, player in ipairs(highscores[3]) do
        scoreboardText = scoreboardText .. "[" .. player.name .. "]"
    end

    ui.addTextArea(g_textAreaIds.scoreboard, scoreboardText, nil, 280, 250, 240, 80, 0x324650, 0x000000, 1, true)

end

local function startCountdown()
    g_gameState = 1
    g_config.spawn = g_config.spawnAreas.START
    for playerName, player in pairs(g_players) do
    --    tfm.exec.killPlayer(playerName)
    end
    local headerText = "<VP><p align=\"center\"><B>Are you ready?</B>\n\n<CH>"
    local textAreaId = g_textAreaIds.countdown;
    ui.addTextArea(textAreaId, headerText, nil, 300, 270, 200, 60, 0x324650, 0x000000, 1, true)
    local function countdown(secondsLeft)
        if (secondsLeft > 0) then
            ui.updateTextArea(textAreaId, headerText .. secondsLeft, nil)
            addTimer(countdown, 1000, false, secondsLeft - 1)
        else
            ui.updateTextArea(textAreaId, headerText .. "START!!!", nil)
            addTimer(function()
                ui.removeTextArea(textAreaId, nil)
            end, 1000, false)
            startGame()
        end
    end
    countdown(3)
end

local function isInsideAreas(areas, xPlayerPosition, yPlayerPosition)
    for _, area in ipairs(areas) do
        if area.x1 < xPlayerPosition and xPlayerPosition < area.x2 and area.y1 < yPlayerPosition and yPlayerPosition < area.y2 then
            return true
        end
    end
    return false
end

local function init()
    tfm.exec.disableAutoShaman(true)
    tfm.exec.disableAutoNewGame(true)
    tfm.exec.disableAutoScore(true)
    tfm.exec.disableAutoTimeLeft(true)
    tfm.exec.disableAfkDeath(true)
    tfm.exec.disableAllShamanSkills(true)
    resetGame()
    print("Script started!")
end

-- Game delegates
local lastColor = 0x00
function eventChatCommand(playerName, message)
    if isAdministrator(playerName) then
        if message == "start" then
            startCountdown(5)
        elseif message == "endgame" then
            endGame()
        elseif message == "resetgame" then
            resetGame()
        elseif message == "abracadabra" then
            openDoor()
        elseif message == "respawn" then
            tfm.exec.respawnPlayer(playerName)
        elseif message == "debug" then
            addPlayer(playerName)
            increasePlayerScore(playerName)
        elseif message == "win" then
            tfm.exec.playerVictory(playerName)
        elseif message == "exit" then
            system.exit()
        end
    end
    if message == "reset" then
        resetPlayer(playerName)
    end
end

function eventKeyboard(playerName, keyCode, down, xPlayerPosition, yPlayerPosition)
    local player = g_players[playerName]

    if isInsideAreas(g_config.toysAreas, xPlayerPosition, yPlayerPosition) then
        if player and down == true and keyCode == 32 then
            if player.carrying == 0 then
                player.carrying = 1
                ui.addTextArea(g_textAreaIds.inventory, "<p align=\"center\">You're carrying a toy!", playerName, 5, 20, 200, 30, 0x324650, 0x000000, 1, true)
                print(playerName .. " picked up a toy")
                return
            elseif player.carrying == 1 then
                showToast("<p align=\"center\">You already have a toy!", 1000, playerName)
                return
            end
        end
    end

    if isInsideAreas(g_config.packingAreas, xPlayerPosition, yPlayerPosition) then
        if player then
            if player.minigame.nextKeyCode > 0 and (keyCode == 1 or keyCode == 2 or keyCode == 3 or keyCode == 4) and player.carrying == 1 then
                ui.addTextArea(g_textAreaIds.hint, "<p align=\"center\">Press " .. string.char(player.minigame.nextKeyCode), playerName, 300, 250, 200, 20, 0x324650, 0x000000, 0.6, true)
            elseif down == true and keyCode == 32 then
                if player.carrying == 1 and player.minigame.nextKeyCode == 0 then
                    player.minigame.nextKeyCode = string.byte(string.upper(g_config.minigameChars[math.random(#g_config.minigameChars)]), 1)
                    ui.addTextArea(g_textAreaIds.hint, "<p align=\"center\">Press " .. string.char(player.minigame.nextKeyCode), playerName, 300, 250, 200, 20, 0x324650, 0x000000, 0.6, true)
                elseif player.carrying == 2 then
                    showToast("<p align=\"center\">You already have a gift!", 1000, playerName)
                    return
                end
            elseif down == true and keyCode == player.minigame.nextKeyCode and player.carrying == 1 then
                player.minigame.combo = player.minigame.combo + 1
                if player.minigame.combo > 5 then
                    player.minigame.nextKeyCode = 0
                    player.minigame.combo = 0
                    player.carrying = 2
                    tfm.exec.giveCheese(playerName)
                    ui.removeTextArea(g_textAreaIds.inventory, playerName)
                    ui.removeTextArea(g_textAreaIds.hint, playerName)
                    print(playerName .. " packed the gift")
                else
                    player.minigame.nextKeyCode = string.byte(string.upper(g_config.minigameChars[math.random(#g_config.minigameChars)]), 1)
                    ui.updateTextArea(g_textAreaIds.hint, "<p align=\"center\">Press " .. string.char(player.minigame.nextKeyCode), playerName)
                end
            elseif down == true and player.minigame.nextKeyCode > 0 and keyCode ~= player.minigame.nextKeyCode and player.carrying == 1 then
                player.minigame.combo = 0
                player.carrying = 0
                player.minigame.nextKeyCode = 0
                ui.removeTextArea(g_textAreaIds.inventory, playerName)
                ui.removeTextArea(g_textAreaIds.hint, playerName)
                showToast("<p align=\"center\">Too bad! You broke the toy :(", 1000, playerName)
                print(playerName .. " broke the toy")
            end
        end
    else
        if player and player.carrying == 1 and player.minigame.nextKeyCode > 0 then
            ui.removeTextArea(g_textAreaIds.hint, playerName)
        end
    end

    if isInsideAreas(g_config.dropOffAreas, xPlayerPosition, yPlayerPosition) then
        if player and down == true and keyCode == 32 then
            if player.carrying == 2 then
                player.carrying = 0
                tfm.exec.removeCheese(playerName)
                increasePlayerScore(playerName)
                print(playerName .. " delivered the gift")
                showToast("<p align=\"center\">Gift delivered!", 3000, playerName)
                return
            end
        end
    end
end

function eventNewPlayer(playerName)
    if isAdministrator(playerName) then
        tfm.exec.setNameColor(playerName, 0x009DFF)
        if isPlayer(playerName) then
            addPlayer(playerName)
        end
    else
        addPlayer(playerName)
    end
    local player = tfm.get.room.playerList[playerName]
    if player and player.isDead then
        tfm.exec.respawnPlayer(playerName)
        print("eventNewPlayer(\"" .. playerName .."\") - score:" .. player.score)
    end
    if g_gameState == 2 then
        openDoor()
    end
end

function eventPlayerDied(playerName)
    tfm.exec.respawnPlayer(playerName)
end

function eventPlayerRespawn(playerName)
    tfm.exec.movePlayer(playerName, g_config.spawn.x, g_config.spawn.y, false, 0, 0, false)
end

function eventLoop(currentTime, timeRemaining)
    g_lastTick = currentTime

    --
    if g_gameState == 2 and timeRemaining <= 0 then
        endGame()
    end
    
    -- Timers handling
    for i=1, #g_timers
    do
        local timer = g_timers[i]
        timer.expired = (currentTime - timer.createdTime - timer.startDelay >= 0)
        if timer.expired then
            timer.callback(timer.args)
            if timer.loop then
                timer.createdTime = currentTime
                timer.expired = false
            end
        end
    end

    for i=#g_timers,1,-1 do
        if g_timers[i].expired then
            table.remove(g_timers, i)
        end
    end
end

init()
