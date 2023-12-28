AddCSLuaFile()
if SERVER then return end -- cl only

-- Detours HTTP and allows only whitelisted trusted urls (ones that dont steal your ip and/or download bad things :) )

-- mostly inspired by StarFallEX and WebAudio's

-- todo:
-- menu

local function pattern(str) return {str, true} end
local function simple(str) return {string.PatternSafe(str), false} end

local whitelist = {
    pattern [[[%w-_]+%.sndcdn%.com/.+]],
    pattern [[[%w-_]+%.bcbits%.com/.+]],
    pattern [[[%w-_]+%.googlevideo%.com/.+]],
    simple [[translate.google.com]],
    simple [[i.redditmedia.com]],
	simple [[i.redd.it]],
	simple [[preview.redd.it]],
    simple [[dl.dropboxusercontent.com]],
	pattern [[%w+%.dl%.dropboxusercontent%.com/(.+)]],
	simple [[dropbox.com]],
	simple [[dl.dropbox.com]],
    simple [[raw.githubusercontent.com]],
	simple [[gist.githubusercontent.com]],
	simple [[raw.github.com]],
	simple [[github.io]],
	simple [[cloud.githubusercontent.com]],
    simple [[steamuserimages-a.akamaihd.net]],
	simple [[steamcdn-a.akamaihd.net]],
    simple [[tts.cyzon.us]],
}

local function check(url)
    for _, data in pairs(whitelist) do
        local match, pattern = data[1], data[2]
        local haystack = pattern and url or (url:match("(.-)/.*") or url)
        if haystack:find( "^" .. match .. (pattern and "" or "$") ) then
			return true -- oh look! a good url!
		end
    end
    return false -- oh look! a url that isnt in the whitelist
end

local function whitelisted(url)
    if not isstring(url) then return false end -- wtf

    local url = url:match("^https?://www%.(.*)") or url:match("^https?://(.*)")
    if not url then return false end

    return check(url) -- now we go see if its good
end

-- detour time

_HTTP = _HTTP or HTTP -- copy the orginal and incase this gets reloaded, the detoured

HTTP = function(req)
    --print(req)
    --PrintTable(req)
    local url = rawget(req, "url")
    if url and not whitelisted(url) then
		print(string.format("URL WHITELIST: Blocked HTTP request to %s", url))
		debug.Trace() -- so we know whos doing this
		local onfailure = rawget(req, "onfailure")
		if onfailure and isfunction(onfailure) then
			onfailure("blocked")
		end
		return
	end
	return _HTTP(req)
end

function http.Fetch(url, onsuccess, onfailure, header) -- copy pasted from gmod src
	local request = {
		url			= url,
		method		= "get",
		headers		= header or {},

		success = function( code, body, headers )
			if ( !onsuccess ) then return end
			onsuccess( body, body:len(), headers, code )
		end,

		failed = function( err )
			if ( !onfailure ) then return end
			onfailure( err )
		end
	}

	HTTP(request)
end

function http.Post(url, params, onsuccess, onfailure, header)
	local request = {
		url			= url,
		method		= "post",
		parameters	= params,
		headers		= header or {},
		
		success = function( code, body, headers )
			if ( !onsuccess ) then return end
			onsuccess( body, body:len(), headers, code )
		end,
		failed = function( err )
			if ( !onfailure ) then return end
			onfailure( err )
		end
	}
	HTTP(request)
end