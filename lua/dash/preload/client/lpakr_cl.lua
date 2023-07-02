z

file.CreateDir'sup/lpakr/rp'



local a = {

    r = 255,

    g = 0,

    b = 0,

    a = 255

}



local b = {

    r = 0,

    g = 75,

    b = 235,

    a = 255

}



local c = {

    r = 255,

    g = 255,

    b = 255,

    a = 255

}



local d = {

    r = 150,

    g = 175,

    b = 200,

    a = 255

}



local function e(...)

    MsgC(b, '[lPakr] ', c, unpack{...})

    MsgN()

end



local function f(...)

    e(a, '[ERROR] ', c, ...)

end



local function g(h, i)

    local j = 10 ^ (i or 2)



    return math.floor(h * j + 0.5) / j

end



e'Init'

local k = false

local l = SysTime()

local m = 'lpakr-3907984898.dat'

local n = 'sup/lpakr/rp/' .. m

local o, p = file.Find('sup/lpakr/rp/*.dat', 'DATA')



for q, r in ipairs(o) do

    if r ~= m then

        e('Pruning old datapack: ', d, r)

        file.Delete('sup/lpakr/rp/' .. r)

    end

end



local s = 0

local t = {}

local u



local function v()

    local w = SysTime()

    u = file.Open(n, 'rb', 'DATA')



    if not u then

        f('Unable to open cached datapack: ', d, m)



        return false

    end



    local x = u:Read(u:Size())

    local y = util.SHA256(x)



    if y ~= '5e0e6c2f611980d67759bdb7381405c91ccf611cef956efb4dc688d7f42f9bee' then

        f('File hash mismatch: expected', d, '"5e0e6c2f611980d67759bdb7381405c91ccf611cef956efb4dc688d7f42f9bee"', c, ' got ', d, '"' .. y .. '"')

        u:Close()



        return false

    end



    x = nil

    collectgarbage()

    u:Seek(0)

    local z = u:ReadULong()

    local A = 0



    for B = 1, z do

        local C, D = u:ReadLine(), u:ReadULong()



        t['addons/!lpakr_out/' .. C:sub(1, C:len() - 1)] = {

            Origin = A,

            Len = D

        }



        A = A + D

    end



    s = u:Tell()

    local E = SysTime() - w

    e('Mounted datapack: ', d, m, c, ' in ', d, g(E, 4), c, ' seconds')

    e('Loaded ', d, z, c, ' files')

    e('Finished in ', d, g(SysTime() - l, 4), c, ' seconds')

    k = true



    return true

end



local F = 'lpakr-3907984898.bsp'

local G = 'download/data/sup/lpakr/rp/' .. F



local function H()

    local I = file.Open(G, 'rb', 'GAME')



    if not I then

        f('Unable to open datapack: ', d, F)



        return false

    end



    local J = I:Size()

    local K = I:Read(J)

    I:Close()



    if not K then

        f('Unable to read datapack: ', d, F)



        return false

    end



    local x = util.Decompress(K)

    K = nil

    collectgarbage()



    if not x then

        f('Unable to decompress datapack: ', d, F)



        return false

    end



    local L = file.Open(n, 'wb', 'DATA')



    if not L then

        f('Unable to open outfile for datapack: ', d, F)

        L:Close()



        return false

    end



    L:Write(x)

    L:Close()

    x = nil

    collectgarbage()

    e('Cached datapack: ', d, F, c, ' in ', d, g(SysTime() - l, 4), c, ' seconds')



    return true

end



local function M(N, O)

    if not hook then

        require'hook'

    end



    hook.Add('Think', 'lpakr.Think', function()

        if LocalPlayer():IsValid() then

            net.Start'lpakr.Error'

            net.WriteString(N)

            net.WriteUInt(O, 12)

            net.SendToServer()

            hook.Remove('Think', 'lpakr.Think')

        end

    end)

end



local function P(O)

    M('Missing content!\nMake sure you have server downloads on, restart your game and try again.\n' .. 'Error #' .. O, O)

end



local Q



local function R()

    local S = 'Loading content...'

    Q = vgui.Create('Panel')

    Q:SetSize(ScrW(), ScrH())

    Q:MakePopup()

    Q:DoModal()



    function Q:Paint(T, U)

        surface.SetDrawColor(0, 0, 0)

        surface.DrawRect(0, 0, T, U)

        surface.SetFont('DermaLarge')

        local V, W = surface.GetTextSize(S)

        surface.SetTextColor(255, 255, 255)

        surface.SetTextPos((T - V) * 0.5, (U - W) * 0.5)

        surface.DrawText(S)

    end

end



local X, Y = 0, 3



local function Z()

    X = X + 1



    if not Q then

        R()

    end



    HTTP{

        url = 'https://cdn.superiorservers.co/fastdl/data/sup/lpakr/rp/' .. F,

        method = 'GET',

        success = function(O, _, a0)

            local x = util.Decompress(_)



            if not x then

                f('Unable to decompress HTTP\'d datapack: ', d, F)



                if X < Y then

                    Z()

                else

                    O = tonumber(O)

                    P(O ~= 200 and O or 1)

                end



                return

            end



            local I = file.Open(n, 'wb', 'DATA')



            if not I then

                f('Unable to open outfile for HTTP\'d datapack: ', d, F)



                if X < Y then

                    Z()

                else

                    P(2)

                end



                return

            end



            I:Write(x)

            I:Close()

            e('Fetched ', d, F, c, ' over HTTP')

            e'Reconnecting'

            RunConsoleCommand'retry'

        end,

        failed = function(a1)

            if X <= Y then

                Z()

            else

                P(3)

            end

        end,

        timeout = 60

    }



    e('Fetching ', d, F, c, ' over HTTP try ', d, X .. '/' .. Y)

end



if file.Exists(n, 'DATA') then

    if not v() then

        if file.Exists(G, 'GAME') then

            if not H() then

                Z()

            end

        else

            Z()

        end

    end

elseif file.Exists(G, 'GAME') then

    if not H() then

        Z()

    else

        if not v() then

            Z()

        end

    end

else

    Z()

end



if not k then

    function lpakr()

        return function() end

    end



    return false

end



local a2 = debug.getinfo

local a3 = string.sub

local CompileString = CompileString

local a4 = file.Open



function lpakr()

    local a5 = a2(2, 'S')

    local a6 = a3(a5.source, 2)

    local a7 = t[a6]



    if not a7 then

        return function()

            f('Calling lpakr() from unmounted file: ', d, a6)

        end

    end



    u:Seek(s + a7.Origin)

    local a8 = u:Read(a7.Len)



    if not a8 then

        return function()

            f('Unable to read file: ', d, a6)

        end

    end



    return CompileString(a8, a6)

end