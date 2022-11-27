INITwindowWidth = love.graphics.getWidth()
INITwindowHeight = love.graphics.getHeight()
function refreshWindowValues()
    windowWidth = love.graphics.getWidth()
    windowHeight = love.graphics.getHeight()
    gameWidth = 400
    gameHeight =400
    gameScale = (math.min(windowWidth, windowHeight) / math.min(INITwindowWidth, INITwindowHeight))
    --print("gameScale:" .. gameScale)
    if objects then 
        loadObjects()
    end
end
refreshWindowValues()

catlib = {}

function renderObject(obj,r,g,b,a, ...)
    local args = {...}
    if r == nil then love.graphics.setColor(1,1,1,1) else
    love.graphics.setColor(r, g, b, a) end
    if args and obj["animation"]["anim8"] == true then
        obj["animation"]["ANIM"]:draw(obj["texture"], ...)
        --print("printing")
    elseif obj["animation"]["anim8"] == true then
        obj["animation"]["ANIM"]:draw(obj["texture"],obj["coords"][1][1], obj["coords"][1][2], 0, obj["scale"], obj["scale"])
    end
    if not obj["animation"]["anim8"] then
        if not obj["animation"]["parallax"] then
            if ... then
                love.graphics.draw(obj["texture"], ...)
            else
                love.graphics.draw(obj["texture"], obj["coords"][1][1], obj["coords"][1][2], 0, obj["scale"])
            end
        else
            for k, v in pairs(obj["coords"]) do
                love.graphics.draw(obj["texture"], obj["coords"][k][1], obj["coords"][k][2], 0, obj["scale"])
            end
        end
    end 
    love.graphics.setColor(1,1,1,1)
end

function loadObjects()
    for k, v in pairs(RAW_objects) do
        objects[k]["texture"] = love.graphics.newImage(v["texture"])
        local xC, yC = 0, 0
        --think about deprecating gamewidth/height here for using gamescale and normal coordinates
        if not v["x"] then xC = 0 elseif v["x"] == "window" then xC = windowWidth else xC = (v["x"] / gameWidth) * windowWidth end
        if not v["y"] then yC = 0 elseif v["y"] == "window" then xY = windowHeight else yC = (v["y"] / gameHeight) * windowHeight  end
        objects[k]["coords"] = {{xC, yC}}
        if v["scale"] == "auto" then
            if v["animation"]["anim8"] == true then
                objects[k]["scale"] = ((math.min(windowWidth, windowHeight) / math.max(objects[k]["animation"]["frameHeight"],objects[k]["animation"]["frameWidth"])))
            else
                objects[k]["scale"] = ((math.min(windowWidth, windowHeight) / math.max(objects[k]["texture"]:getWidth(),objects[k]["texture"]:getHeight())))
            end
        else
            objects[k]["scale"] = v["scale"] * gameScale
        end
        if v["animation"]["anim8"] == true then
            objects[k]["animation"]["SPRITEMAP"] = anim8.newGrid(objects[k]["animation"]["frameWidth"], objects[k]["animation"]["frameHeight"], objects[k]["texture"]:getWidth(), objects[k]["texture"]:getHeight())
            objects[k]["animation"]["ANIM"] = anim8.newAnimation(objects[k]["animation"]["SPRITEMAP"](objects[k]["animation"]["frameCount"], 1), objects[k]["animation"]["frameTiming"], objects[k]["animation"]["loopCondition"])
        end
        if v["animation"]["parallax"] == true then
            objects[k]["animation"]["MAX_parallaxRepeats"] = math.ceil((windowWidth + (objects[k]["texture"]:getWidth() * objects[k]["scale"])) / (objects[k]["texture"]:getWidth() * objects[k]["scale"]))
            if v["animation"]["parallaxRepeats"] == "auto" or not v["animation"]["parallaxRepeats"] then objects[k]["animation"]["parallaxRepeats"] = objects[k]["animation"]["MAX_parallaxRepeats"] end
            local offsetX = objects[k]["coords"][1][1]
            for i = 1, objects[k]["animation"]["parallaxRepeats"] - 1, 1 do
                if v["animation"]["parallaxRepeats"] == "auto" or not v["animation"]["parallaxRepeats"] then
                    offsetX = offsetX + (objects[k]["texture"]:getWidth() * objects[k]["scale"])
                else
                    offsetX = offsetX + ((objects[k]["texture"]:getWidth() * objects[k]["scale"]) * ((objects[k]["animation"]["MAX_parallaxRepeats"] / objects[k]["animation"]["parallaxRepeats"]) * (i)))
                end
                --if v == RAW_objects["pillar"] then for c, f in pairs(objects["pillar"]["coords"]) do print("pillar",f[1]) end end
                table.insert(objects[k]["coords"], {offsetX,0})
            end
            objects[k]["animation"]["parallaxSpeed"] = (v["animation"]["parallaxSpeed"] * gameScale)
        end
        if v["hitboxes"] then
            for n, l in pairs(objects[k]["hitboxes"]) do
                for c, j in pairs(l) do
                    if j[1] == "width" then j[1] = objects[k]["texture"]:getWidth() end
                    if j[2] == "height" then j[2] = objects[k]["texture"]:getHeight() end
                    j[1], j[2] = (j[1] * objects[k]["scale"]),(j[2] * objects[k]["scale"])
                end
            end
        end
        objects[k]["drawObject"] = function(x, ...) renderObject(x, ...) end
    end
end

function isColliding(collider1, collider2)
    for u, f in pairs(collider1["coords"]) do
        for o, l in pairs(collider1["hitboxes"]) do
            for k, j in pairs(collider2["coords"]) do
                for v, h in pairs(collider2["hitboxes"]) do
                    if (((f[1] + l[1][1]) >= (j[1] + h[1][1]) and (f[1] + l[1][1]) <= (j[1] + h[2][1])) or ((f[1] + l[2][1]) >= (j[1] + h[1][1]) and (f[1] + l[2][1]) <= (j[1] + h[2][1]))) and (((f[2] + l[1][2]) >= (j[2] + h[1][2]) and (f[2] + l[1][2]) <= (j[2] + h[2][2])) or ((f[2] + l[2][2]) >= (j[2] + h[1][2]) and (f[2] + l[2][2]) <= (j[2] + h[2][2]))) then
                        return true
                    end
                end
            end
        end
    end
    return false
end
function isColliding(collider1, mouseX, mouseY)
    for u, f in pairs(collider1["coords"]) do
        for o, l in pairs(collider1["hitboxes"]) do
            if (((f[1] + l[2][1]) >= mouseX and (f[1] + l[1][1]) <= mouseX) and ((f[2] + l[2][2]) >= mouseY and (f[2] + l[1][2]) <= mouseY)) then
                return true
            end
        end
    end
    return false
end

function nextParallaxFrame(delta, ...)
    local args = {...}
    for k, v in pairs(args) do
        if v["animation"]["parallax"] == true then
            for d, f in pairs(v["coords"]) do
                if v["animation"]["parallaxAxis"] == "x" then
                    f[1] = f[1] + ((v["animation"]["parallaxSpeed"] ) * (60*delta))
                elseif v["animation"]["parallaxAxis"] == "y" then
                    f[2] = f[2] + ((v["animation"]["parallaxSpeed"] ) * (60*delta))
                elseif v["animation"]["parallaxAxis"] == "xy" then
                    f[1] = f[1] + ((v["animation"]["parallaxSpeed"] ) * (60*delta))
                    f[2] = f[2] + ((v["animation"]["parallaxSpeed"] ) * (60*delta))
                end
                if ((v["texture"]:getWidth() * v["scale"]) * -1) >= f[1] then
                    f[1] = f[1] + ((v["animation"]["MAX_parallaxRepeats"] * (v["texture"]:getWidth() * v["scale"])))
                end
            end
        end
    end
end

function calc_physics(delta,player)
    if love.keyboard.isDown("space") and currentState == "gameActive" then
        if isMoving == false then
            player["animation"]["ANIM"]:gotoFrame(1)
            player["animation"]["ANIM"]:resume()
            player["animation"]["velocity"] = 4.25
        end
        isMoving = true
    else
        isMoving = false
    end
    player["coords"][1][2] = player["coords"][1][2] - (player["animation"]["velocity"] * ((3   * gameScale) * (60 * delta)))
    if player["animation"]["velocity"] >= -11 then
        player["animation"]["velocity"] = player["animation"]["velocity"] - ((0.22) * (60 * delta))
    end
    if currentState == "gameActive" then
        if player["coords"][1][2] + player["hitboxes"][1][1][2] <= 0 then
            player["coords"][1][2] = 0 - player["hitboxes"][1][1][2]
        end
        if player["coords"][1][2] + player["hitboxes"][1][2][2] >= windowHeight then
            player["coords"][1][2] = windowHeight - player["hitboxes"][1][2][2]
        end
    end
end

function love.resize(w, h)
    refreshWindowValues()
end

function catlib.printf( r, g, b, a, ...)
    love.graphics.setColor(r, g, b, a)
    love.graphics.printf(...)
    love.graphics.setColor(1, 1, 1, 1)
end

function catlib.drawShape(shape, r, g, b, a, ...)
    love.graphics.setColor(r, g, b, a)
    love.graphics[shape](...)
    love.graphics.setColor(1, 1, 1, 1)
end

--function catlib.setFontSize(font, size)
--    font = love.graphics.newFont( font, size )
--end

function loadFonts()
    for k, v in pairs(RAW_font) do
        font[k] = love.graphics.setNewFont(v[1],v[2])
    end
end

function catlib.setFontSize(fontName, size)
    font[fontName]:release()
    font[fontName] = love.graphics.newFont( RAW_font[fontName][1], size )
end

function loadSounds()
    for k, v in pairs(RAW_sounds) do
        sounds[k] = love.audio.newSource(v[1],v[2])
    end
end

function catlib.loopAudio(sound)
    if not sound:isPlaying() then
		love.audio.play(sound)
	end
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end
  

