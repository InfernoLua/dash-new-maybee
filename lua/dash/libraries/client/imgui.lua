imgui = {}
local a = GetConVar('developer')

function imgui.IsDeveloperMode()
    return not imgui.DisableDeveloperMode and a:GetInt() > 0
end

local b = false
local c
local d = {}

local function e()
    if render.GetRenderTarget() ~= nil then return false end
    if vgui.CursorVisible() and vgui.GetHoveredPanel() ~= g_ContextMenu then return false end

    return true
end

hook('PreRender', 'imgui.PreRender', function()
    if e() then
        local f = input.LookupBinding('+use', true)
        local g = input.LookupBinding('+attack', true)
        local h = f and input.GetKeyCode(f)
        local i = g and input.GetKeyCode(g)
        local j = d.pressing
        d.pressing = h and input.IsButtonDown(h) or i and input.IsButtonDown(i)
        d.pressed = not j and d.pressing
    end
end)

local k = {}

local l = {
    output = k,
    filter = {}
}

local function m(n, o, p)
    local q = l
    q.start = n
    q.endpos = o
    q.filter[1] = c
    q.filter[2] = p
    local r = util.TraceLine(q)

    if r.Hit then
        return true, r.Entity
    else
        return false
    end
end

function imgui.Start3D2D(s, t, u, v, w)
    if not IsValid(c) then
        c = LocalPlayer()
    end

    if d.shutdown == true then return end

    if d.rendering == true then
        print('[IMGUI] Starting a new IMGUI context when previous one is still rendering' .. 'Shutting down rendering pipeline to prevent crashes..')
        d.shutdown = true

        return false
    end

    b = imgui.IsDeveloperMode()
    local n = c:EyePos()
    local x = s - n

    do
        local y = t:Up()
        local z = x:Dot(y)

        if b then
            d._devDot = z
        end

        if z >= 0 then return false end
    end

    if v then
        local A = x:Length()
        if A > v then return false end

        if b then
            d._devDist = A
            d._devHideDist = v
        end

        if v and w and A > w then
            local B = math.min(math.Remap(A, w, v, 1, 0), 1)
            render.SetBlend(B)
            surface.SetAlphaMultiplier(B)
        end
    end

    d.rendering = true
    d.pos = s
    d.angles = t
    d.scale = u
    cam.Start3D2D(s, t, u)

    if not vgui.CursorVisible() or vgui.IsHoveringWorld() then
        local r = c:GetEyeTrace()
        local C = r.StartPos
        local D

        if vgui.CursorVisible() and vgui.IsHoveringWorld() then
            D = gui.ScreenToVector(gui.MousePos())
        else
            D = r.Normal
        end

        local E = t:Up()
        local o = util.IntersectRayWithPlane(C, D, s, E)

        if o then
            local F, G = m(C, o, d.entity)

            if F then
                d.mx = nil
                d.my = nil

                if b then
                    d._devInputBlocker = 'collision ' .. G:GetClass() .. '/' .. G:EntIndex()
                end
            else
                local H = s - o
                local I = H:Dot(-t:Forward()) / u
                local J = H:Dot(-t:Right()) / u
                d.mx = I
                d.my = J
            end
        else
            d.mx = nil
            d.my = nil

            if b then
                d._devInputBlocker = 'not looking at plane'
            end
        end
    else
        d.mx = nil
        d.my = nil

        if b then
            d._devInputBlocker = 'not hovering world'
        end
    end

    if b then
        d._renderStarted = SysTime()
    end

    return true
end

function imgui.Entity3D2D(K, L, M, u, ...)
    d.entity = K
    local N = imgui.Start3D2D(K:LocalToWorld(L), K:LocalToWorldAngles(M), u, ...)

    if not N then
        d.entity = nil
    end

    return N
end

local function O(I, J, P, Q)
    local s = d.pos
    local R, S = d.angles:Forward(), d.angles:Right()
    local u = d.scale
    local T, U = s + R * I * u + S * J * u, s + R * (I + P) * u + S * (J + Q) * u
    local V, W = Vector(math.huge, math.huge, math.huge), Vector(-math.huge, -math.huge, -math.huge)
    V.x = math.min(V.x, T.x, U.x)
    V.y = math.min(V.y, T.y, U.y)
    V.z = math.min(V.z, T.z, U.z)
    W.x = math.max(W.x, T.x, U.x)
    W.y = math.max(W.y, T.y, U.y)
    W.z = math.max(W.z, T.z, U.z)

    return V, W
end

local X = Vector(0, 0, 30)

local Y = {
    background = Color(0, 0, 0, 200),
    title = Color(78, 205, 196),
    mouseHovered = Color(0, 255, 0),
    mouseUnhovered = Color(255, 0, 0),
    pos = Color(255, 255, 255),
    distance = Color(200, 200, 200, 200),
    ang = Color(255, 255, 255),
    dot = Color(200, 200, 200, 200),
    angleToEye = Color(200, 200, 200, 200),
    renderTime = Color(255, 255, 255),
    renderBounds = Color(0, 0, 255)
}

local function Z(_, I, J, a0)
    draw.SimpleText(_, 'DefaultFixedDropShadow', I, J, a0, TEXT_ALIGN_CENTER, nil)
end

local function a1()
    local a2 = c:EyeAngles()
    a2:RotateAroundAxis(a2:Right(), 90)
    a2:RotateAroundAxis(a2:Up(), -90)
    cam.IgnoreZ(true)
    cam.Start3D2D(d.pos + X, a2, 0.15)
    local a3 = Y['background']
    surface.SetDrawColor(a3.r, a3.g, a3.b, a3.a)
    surface.DrawRect(-100, 0, 200, 140)
    local a4 = Y['title']
    Z('imgui developer', 0, 5, a4)
    surface.SetDrawColor(a4.r, a4.g, a4.b)
    surface.DrawLine(-50, 16, 50, 16)
    local a5, a6 = d.mx, d.my

    if a5 and a6 then
        Z(string.format('mouse: hovering %d x %d', a5, a6), 0, 20, Y['mouseHovered'])
    else
        Z(string.format('mouse: %s', d._devInputBlocker or ''), 0, 20, Y['mouseUnhovered'])
    end

    local s = d.pos
    Z(string.format('pos: %.2f %.2f %.2f', s.x, s.y, s.z), 0, 40, Y['pos'])
    Z(string.format('distance %.2f / %.2f', d._devDist or 0, d._devHideDist or 0), 0, 53, Y['distance'])
    local a7 = d.angles
    Z(string.format('ang: %.2f %.2f %.2f', a7.p, a7.y, a7.r), 0, 75, Y['ang'])
    Z(string.format('dot %d', d._devDot or 0), 0, 88, Y['dot'])
    local a8 = (s - c:EyePos()):Angle()
    a8:RotateAroundAxis(a7:Up(), -90)
    a8:RotateAroundAxis(a7:Right(), 90)
    Z(string.format('angle to eye (%d,%d,%d)', a8.p, a8.y, a8.r), 0, 100, Y['angleToEye'])
    Z(string.format('rendertime avg: %.2fms', (d._devBenchAveraged or 0) * 1000), 0, 120, Y['renderTime'])
    cam.End3D2D()
    cam.IgnoreZ(false)
end

function imgui.End3D2D()
    if d then
        if b then
            local a9 = SysTime() - d._renderStarted
            d._devBenchTests = (d._devBenchTests or 0) + 1
            d._devBenchTaken = (d._devBenchTaken or 0) + a9

            if d._devBenchTests == 100 then
                d._devBenchAveraged = d._devBenchTaken / 100
                d._devBenchTests = 0
                d._devBenchTaken = 0
            end
        end

        d.rendering = false
        cam.End3D2D()
        render.SetBlend(1)
        surface.SetAlphaMultiplier(1)

        if b then
            a1()
        end

        d.entity = nil
    end
end

function imgui.CursorPos()
    local a5, a6 = d.mx, d.my

    return a5, a6
end

function imgui.IsHovering(I, J, P, Q)
    local a5, a6 = d.mx, d.my

    return a5 and a6 and a5 >= I and a5 <= I + P and a6 >= J and a6 <= J + Q
end

function imgui.IsPressing()
    return e() and d.pressing
end

function imgui.IsPressed()
    return e() and d.pressed
end

function imgui.Button(I, J, P, Q, aa)
    local ab = imgui.IsHovering(I, J, P, Q)
    aa(I, J, P, Q, ab, imgui.IsPressing() and ab)

    return e() and ab and d.pressed
end

function imgui.Cursor(I, J, P, Q, ac, ad)
    local a5, a6 = d.mx, d.my
    if not a5 or not a6 then return end
    if I and P and (a5 < I or a5 > I + P) then return end
    if J and Q and (a6 < J or a6 > J + Q) then return end
    local ae = math.ceil(0.3 / d.scale)
    surface.SetDrawColor(imgui.IsPressing() and ad or ac)
    surface.DrawLine(a5 - ae, a6, a5 + ae, a6)
    surface.DrawLine(a5, a6 - ae, a5, a6 + ae)
end