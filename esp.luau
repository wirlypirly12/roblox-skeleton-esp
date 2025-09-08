local rig = {
    -- connect head->torso
    {"Head", "UpperTorso"},

    -- shoulders
    {"l_neck", "RightUpperArm"},
    {"l_neck", "LeftUpperArm"},

    -- right arm
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},

    -- left arm
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},

    -- connect lower torso
    {"UpperTorso", "LowerTorso"},

    -- lower torso -> legs
    {"LowerTorso", "LeftUpperLeg"},
    {"LowerTorso", "RightUpperLeg"},

    -- left leg
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},

    -- right leg
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
};

local drawings = {};

-- if you have a working drawing library comment this line

local succ, Drawing = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/MirayXS/Roblox-Drawing-Lib/refs/heads/main/main.lua"))();
end)

if not succ then
    warn("issue: ".. Drawing);
    Drawing = getrenv().Drawing;
end

local scene = Instance.new("ScreenGui", game:GetService("CoreGui"));
scene.IgnoreGuiInset = true;
scene.Name = "not_scene";


local players = game:GetService("Players");
local localPlayer = players.LocalPlayer;
local runservice = game:GetService("RunService");
local camera = workspace.CurrentCamera;
local identifyexecutor = identifyexecutor or function() return "" end


local midpoint: (Vector3, Vector3)->Vector3 = function(a, b)
    return (a+b)/2;
end
local add_line: ()->drawing_object = function()
    local d;
    if identifyexecutor():find("Velocity") then
        d = Drawing.new("Line", scene);
    else
        d = Drawing.new("Line");
    end
    return d;
end

local create_drawing: (Player)->nil = function(plr)
    rawset(drawings, plr, {});
    for i, v in next, rig do
        local d = add_line();
        d.Thickness = 1;
        d.Color = Color3.fromRGB(0, 165, 255);
        d.Visible = false;

        local p_drawings = rawget(drawings, plr)
        rawset(p_drawings, #p_drawings+1, d)
    end
end

local hide_drawings: (Player)->boolean = function(plr)
    local draw_data = drawings[plr]
    for i,v in next, draw_data do
        v.Visible = false;
    end
    return true;
end

local destroy_drawings: (Player)->boolean = function(plr)
    if plr == nil then
        for i,v in next, drawings do
            for index, drawing in next, v do
                drawing:Remove();
            end
            drawings[i] = nil;
        end
        drawings = {};
        return true;
    end

    for i, v in next, drawings[plr] do
        v:Remove();
    end
    drawings[plr] = nil;
    return true
end

local cache_obj: (Model)->table? = function(char)
    local cache = { };

    for i, skel_data in next, rig do
        for index, part_name in ipairs(skel_data) do
            if part_name == "l_neck" then continue end;
            if not cache[part_name] then
                local entry = char:FindFirstChild(part_name);
                if not entry then
                    continue
                end
                local position = camera:WorldToViewportPoint(entry.Position);
                cache[part_name] = {entry, position};
            end
        end
    end
    return cache;
end

setmetatable(drawings, {
    __index = function(t, plr)
        local entry = rawget(t, plr);

        if entry == nil then
            create_drawing(plr);
            entry = rawget(t, plr);
        end
        return entry;
    end,
    __mode = "k"
})

local should_unload = false;
local last_ran = 0;

local conn; conn = runservice.RenderStepped:Connect(function()
    -- yield 2 frames (optimizastion)
    if (os.clock() - last_ran) < (1/105) then
        return;
    end
    last_ran = os.clock();

    if should_unload then
        destroy_drawings(nil)
        if conn then
            conn:Disconnect()
        end
    end

    for i, v in next, players:GetPlayers() do
        if v == localPlayer then continue; end
        
        local char = v and v.Character or nil;
        if not char then
            destroy_drawings(v)
            continue;
        end

        local hrp = char:FindFirstChild("HumanoidRootPart");
        if not hrp then
            destroy_drawings(v)
            continue;
        end

        local position, onscreen = camera:WorldToViewportPoint(hrp.Position);
        if not onscreen then
            hide_drawings(v)
            continue;
        end

        local draw_data = drawings[v];
        local cache = cache_obj(char);
        if not cache then
            continue
        end;
        for index, skel_data in next, rig do
            local data_from = cache[skel_data[1]];
            local data_to = cache[skel_data[2]];

            if skel_data[1] == "l_neck" then
                local head = cache["Head"][1];
                local upper_torso = cache["UpperTorso"][1];
                local mid = midpoint(head.Position, upper_torso.Position)
                data_from = {true, camera:WorldToViewportPoint(mid)};
            end

            if not data_from or not data_to then
                continue;
            end
            
            local from = data_from[1];
            
            local to = data_to[1];

            local skeleton_from_2d = data_from[2];
            local skeleton_to_2d = data_to[2];


            local this_line = drawings[v][index];
            if not this_line then
                continue
            end

            -- elimante the y cord.
            from = Vector2.new(skeleton_from_2d.X, skeleton_from_2d.Y)
            to = Vector2.new(skeleton_to_2d.X, skeleton_to_2d.Y);

            if (from ~= this_line.From or to ~= this_line.To) then
                this_line.From = from
                this_line.To = to
            end
            if not this_line.Visible then
                this_line.Visible = true;
            end
        end
    end
end)

-- unload
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end

    if input.KeyCode and input.KeyCode == Enum.KeyCode.J then
        should_unload = true
    end
end)

players.PlayerRemoving:Connect(destroy_drawings)
