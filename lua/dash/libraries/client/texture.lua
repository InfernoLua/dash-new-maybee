require'hash'
texture = {}

local a = {
    __tostring = function(self)
        return self.Name
    end
}

a.__index = a
a.__concat = a.__tostring
debug.getregistry().Texture = a
local b = {}
local c = 'https://YOUR_SITE.COM/?url=%s&width=%i&height=%i&format=%s'

if not file.IsDir('texture', 'DATA') then
    file.CreateDir'texture'
else
    local d = file.Find('texture/*', 'DATA')

    if #d > 1000 then
        for e, f in ipairs(d) do
            file.Delete('texture/' .. f)
        end
    end
end

function texture.Create(g)
    local h = setmetatable({
        Name = g,
        URL = '',
        Width = 1000,
        Height = 1000,
        Busy = false,
        Cache = true,
        Proxy = true,
        Format = 'jpg',
        PngParameters = 'smooth'
    }, a)

    b[g] = h

    return h
end

function texture.Get(g)
    if b[g] then return b[g]:GetMaterial() end
end

function texture.Delete(g)
    b[g] = nil
end

function texture.SetProxy(i)
    c = i
end

function a:SetSize(j, k)
    self.Width, self.Height = j, k

    return self
end

function a:SetFormat(l)
    self.Format = l

    return self
end

function a:SetPngParameters(m)
    self.PngParameters = m

    return self
end

function a:EnableCache(n)
    self.Cache = n

    return self
end

function a:EnableProxy(n)
    self.Proxy = n

    return self
end

function a:GetName()
    return self.Name
end

function a:GetUID(o)
    if not self.UID or o then
        self.UID = hash.MD5(self.Name .. self.URL .. self.Width .. self.Height .. self.Format)
    end

    return self.UID
end

function a:GetSize()
    return self.Width, self.Height
end

function a:GetFormat()
    return self.Format
end

function a:GetURL()
    return self.URL
end

function a:GetFile()
    return self.File
end

function a:GetMaterial()
    return self.IMaterial
end

function a:GetError()
    return self.Error
end

function a:IsBusy()
    return self.Busy == true
end

function a:Download(i, p, q)
    if self.Name == nil then
        self.Name = 'Web Material: ' .. i
    end

    self.URL = i
    self.File = 'texture/' .. self:GetUID() .. '.png'

    if self.Cache and file.Exists(self.File, 'DATA') then
        self.IMaterial = Material('data/' .. self.File, self.PngParameters)

        if p then
            p(self, self.IMaterial)
        end
    else
        self.Busy = true

        http.Fetch(self.Proxy and string.format(c, i:URLEncode(), self.Width, self.Height, self.Format) or i, function(r, s, t, u)
            if self.Cache then
                file.Write(self.File, r)
                self.IMaterial = Material('data/' .. self.File, self.PngParameters)
            else
                local v = 'texture/tmp_' .. os.time() .. '_' .. self:GetUID() .. '.png'
                file.Write(v, r)
                self.IMaterial = Material('data/' .. v, self.PngParameters)

                timer.Simple(1, function()
                    file.Delete(v)
                end)
            end

            if p then
                p(self, self.IMaterial)
            end

            self.Busy = false
        end, function(w)
            self.Error = w

            if q then
                q(self, self.Error)
            end

            self.Busy = false
        end)
    end

    return self
end

function a:RenderManual(x, y)
    local z = 'texture/' .. self:GetUID() .. '-render.png'

    if self.Cache and file.Exists(z, 'DATA') then
        self.File = z
        self.IMaterial = Material('data/' .. self.File, self.PngParameters)

        if y then
            y(self, self.IMaterial)
        end
    else
        local j, k = self.Width, self.Height
        local A = 'texture.PostRender' .. self:GetUID()

        hook.Add('PostRender', A, function()
            hook.Remove('PostRender', A)
            local B = GetRenderTarget(self:GetName(), j, k, true)
            render.PushRenderTarget(B, 0, 0, j, k)
            render.OverrideAlphaWriteEnable(true, true)
            surface.DisableClipping(true)
            render.ClearDepth()
            render.Clear(0, 0, 0, 0)
            cam.Start2D()
            x(self, j, k)
            cam.End2D()

            if self.Cache then
                self.File = 'texture/' .. self:GetUID() .. '-render.png'

                file.Write(self.File, render.Capture({
                    format = 'png',
                    quality = 100,
                    x = 0,
                    y = 0,
                    h = k,
                    w = j
                }))
            end

            surface.DisableClipping(false)
            render.OverrideAlphaWriteEnable(false)
            render.PopRenderTarget()

            if self.Cache then
                self.IMaterial = Material('data/' .. self.File)
            end

            if y then
                y(self, self.IMaterial)
            end
        end)
    end

    return self
end

function a:Render(x, y)
    return self:RenderManual(function(self, j, k)
        cam.Start2D()
        x(self, j, k)
        cam.End2D()
    end, y)
end