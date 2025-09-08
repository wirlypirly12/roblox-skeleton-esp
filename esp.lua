local rig = {
    -- connect head->torso
    {"Head", "UpperTorso"},

    -- shoulders
    {"UpperTorso", "RightUpperArm"},
    {"UpperTorso", "LeftUpperArm"},

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
local Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/MirayXS/Roblox-Drawing-Lib/refs/heads/main/main.lua"))();

local scene = Instance.new("ScreenGui", game:GetService("CoreGui"));
scene.IgnoreGuiInset = true;
scene.Name = "not_scene";


local players = game:GetService("Players");
local localPlayer = players.LocalPlayer;
local runservice = game:GetService("RunService");
local camera = workspace.CurrentCamera;

local create_drawing: (Player)->nil = function(plr)
    drawings[plr] = {};

    for i, v in next, rig do
        local d;
        if identifyexecutor():find("Velocity") then
            d = Drawing.new("Line", scene);
        else
            d = Drawing.new("Line");
        end
        d.Thickness = 1;
        d.Color = Color3.fromRGB(0, 165, 255);
        d.Visible = false;

        drawings[plr][#drawings[plr]+1] = d;
    end
end

local hide_drawings: ()->nil = function(plr)
    if not drawings[plr] then
        return
    end

    for i,v in next, drawings[plr] do
        v.Visible = false;
    end
end

local should_unload = false;

local conn; conn = runservice.Heartbeat:Connect(function()
    if should_unload then
        for i, v in next, drawings do
            for index, drawing in next, v do
                drawing:Remove();
            end
        end

        if conn then
            conn:Disconnect()
        end
    end
    for i, v in next, players:GetPlayers() do
        if v == localPlayer then continue; end
        if v.Team and v.Team == localPlayer.Team then
            continue
        end
        
        local char = v and v.Character or nil;
        if not char then
            hide_drawings(v)
            continue;
        end

        local hrp = char:FindFirstChild("HumanoidRootPart");
        if not hrp then
            hide_drawings(v)
            continue;
        end

        local position, onscreen = camera:WorldToViewportPoint(hrp.Position);
        if not onscreen then
            hide_drawings(v)
            continue
        end;

        local draw_data = drawings[v];
        if not draw_data then
            create_drawing(v);
            draw_data = drawings[v];
        end

        for index, skel_data in next, rig do
            local from = char:FindFirstChild(skel_data[1]);
            local to = char:FindFirstChild(skel_data[2])

            if not from or not to then
                continue;
            end

            local skeleton_from_2d = camera:WorldToViewportPoint(from.Position);
            local skeleton_to_2d = camera:WorldToViewportPoint(to.Position);

            local this_line = drawings[v][index];
            if not this_line then
                continue
            end
            
            local from = Vector2.new(skeleton_from_2d.X, skeleton_from_2d.Y)
            local to = Vector2.new(skeleton_to_2d.X, skeleton_to_2d.Y);

            if (from ~= this_line.From or to ~= this_line.To) then
                this_line.From = from
                this_line.To = to
            end
            this_line.Visible = true;
        end
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end

    if input and input.KeyCode and input.KeyCode == Enum.KeyCode.J then
        should_unload = true
    end
end)

players.PlayerRemoving:Connect(function(plr)
    if drawings[plr] then
        for i, v in next, drawings[plr] do
            v:Remove();
        end
    end
end)
