
local surface_SetFont 		= surface.SetFont
local surface_GetTextSize 	= surface.GetTextSize
local string_Explode 		= string.Explode
local ipairs 				= ipairs

function string.Wrap(font, text, width)
	surface_SetFont(font)
		
	local sw = surface_GetTextSize(' ')
	local ret = {}
		
	local w = 0
	local s = ''

	local t = string_Explode('\n', text)
	for i = 1, #t do
		local t2 = string_Explode(' ', t[i], false)
		for i2 = 1, #t2 do
			local neww = surface_GetTextSize(t2[i2])
				
			if (w + neww >= width) then
				ret[#ret + 1] = s
				w = neww + sw
				s = t2[i2] .. ' '
			else
				s = s .. t2[i2] .. ' '
				w = w + neww + sw
			end
		end
		ret[#ret + 1] = s
		w = 0
		s = ''
	end
		
	if (s ~= '') then
		ret[#ret + 1] = s
	end

	return ret
end

local a = ' '
local b = '\n'

local function c(d, e, f, g)
    local h = #d
    local i

    for j = 1, h do
        if j == h then
            if i then
                local k = surface.GetTextSize(d)

                if k > f then
                    table.insert(g, string.sub(d, 1, i))
                    table.insert(g, string.sub(d, i + 1))
                else
                    table.insert(g, d)
                end
            else
                table.insert(g, d)
            end
        elseif d[j] == a then
            local l = string.sub(d, 1, j)
            local k = surface.GetTextSize(l)

            if k > f then
                local m = i and i or j
                local n = string.sub(d, 1, m)
                table.insert(g, n)
                m = m + 1

                if h ~= m then
                    c(string.sub(d, m), e, f, g)
                end

                break
            end

            i = j
        end
    end
end

function string.WrapGay(d, e, f)
    surface.SetFont(e)
    local g = {}
    local o = 1

    for j = 1, #d do
        if d[j] == b then
            local p = string.sub(d, o, j - 1)
            local q = surface.GetTextSize(p)

            if q > f then
                c(p, e, f, g)
            else
                table.insert(g, p)
            end

            o = j + 1
        end
    end

    c(string.sub(d, o), e, f, g)

    return g
end