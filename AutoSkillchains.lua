--[[
Copyright © 2023, SnickySnacks
Based on Skillchains by Ivaar and AutoWS by Lorand
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
* Neither the name of SkillChains nor the
  names of its contributors may be used to endorse or promote products
  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL SNICKYSNACKS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
_addon.author = 'SnickySnacks'
_addon.command = 'asc'
_addon.name = 'AutoSkillChains'
_addon.version = '1.24.01.28'

require('luau')
require('pack')
require('actions')
texts = require('texts')
skills = require('skills')

_static = S{'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG','SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN'}

default = {}
default.Show = {burst=_static, pet=S{'BST','SMN'}, props=_static, spell=S{'SCH','BLU'}, step=_static, timer=_static, weapon=_static}
default.UpdateFrequency = 0.2
default.aeonic = false
default.color = false
default.display = {text={size=12,font='Consolas'},pos={x=0,y=0},bg={visible=true}}
default.autows = {}
default.autows.enabled = false
default.autows.open = true
default.autows.openTp = 999
default.autows.openDelay = 0.8
default.autows.opener = ''
default.autows.close = true
default.autows.closeTp = 999
default.autows.levelPriority = {3, 4, 2, 1}
default.autows.chainPriority = 'Darkness'
default.autows.blacklist = {'Cyclone','Aeolian Edge','Fell Cleave','Sonic Thrust','Spinning Attack','Shockwave','Earth Crusher','Cataclysm','Spinning Scythe','Circle Blade'}
default.autows.hpGt = 3
default.autows.hpLt = 99

settings = config.load(default)
settings.autows.enabled = false --Always disabled to start
skill_props = texts.new('',settings.display,settings)
message_ids = S{110,185,187,317,802}
skillchain_ids = S{288,289,290,291,292,293,294,295,296,297,298,299,300,301,385,386,387,388,389,390,391,392,393,394,395,396,397,767,768,769,770}
buff_dur = {[163]=40,[164]=30,[470]=60}
info = {}
resonating = {}
buffs = {}
local autowsNextWS = ''

colors = {}            -- Color codes by Sammeh
colors.Light =         '\\cs(255,255,255)'
colors.Dark =          '\\cs(0,0,204)'
colors.Ice =           '\\cs(0,255,255)'
colors.Water =         '\\cs(0,0,255)'
colors.Earth =         '\\cs(153,76,0)'
colors.Wind =          '\\cs(102,255,102)'
colors.Fire =          '\\cs(255,0,0)'
colors.Lightning =     '\\cs(255,0,255)'
colors.Gravitation =   '\\cs(102,51,0)'
colors.Fragmentation = '\\cs(250,156,247)'
colors.Fusion =        '\\cs(255,102,102)'
colors.Distortion =    '\\cs(51,153,255)'
colors.Darkness =      colors.Dark
colors.Umbra =         colors.Dark
colors.Compression =   colors.Dark
colors.Radiance =      colors.Light
colors.Transfixion =   colors.Light
colors.Induration =    colors.Ice
colors.Reverberation = colors.Water
colors.Scission =      colors.Earth
colors.Detonation =    colors.Wind
colors.Liquefaction =  colors.Fire
colors.Impaction =     colors.Lightning

skillchains = {'Light','Darkness','Gravitation','Fragmentation','Distortion','Fusion','Compression','Liquefaction','Induration','Reverberation','Transfixion','Scission','Detonation','Impaction','Radiance','Umbra'}

sc_info = {
    Radiance = {'Fire','Wind','Lightning','Light', lvl=4},
    Umbra = {'Earth','Ice','Water','Dark', lvl=4},
    Light = {'Fire','Wind','Lightning','Light', Light={4,'Light','Radiance'}, lvl=3},
    Darkness = {'Earth','Ice','Water','Dark', Darkness={4,'Darkness','Umbra'}, lvl=3},
    Gravitation = {'Earth','Dark', Distortion={3,'Darkness'}, Fragmentation={2,'Fragmentation'}, lvl=2},
    Fragmentation = {'Wind','Lightning', Fusion={3,'Light'}, Distortion={2,'Distortion'}, lvl=2},
    Distortion = {'Ice','Water', Gravitation={3,'Darkness'}, Fusion={2,'Fusion'}, lvl=2},
    Fusion = {'Fire','Light', Fragmentation={3,'Light'}, Gravitation={2,'Gravitation'}, lvl=2},
    Compression = {'Darkness', Transfixion={1,'Transfixion'}, Detonation={1,'Detonation'}, lvl=1},
    Liquefaction = {'Fire', Impaction={2,'Fusion'}, Scission={1,'Scission'}, lvl=1},
    Induration = {'Ice', Reverberation={2,'Fragmentation'}, Compression={1,'Compression'}, Impaction={1,'Impaction'}, lvl=1},
    Reverberation = {'Water', Induration={1,'Induration'}, Impaction={1,'Impaction'}, lvl=1},
    Transfixion = {'Light', Scission={2,'Distortion'}, Reverberation={1,'Reverberation'}, Compression={1,'Compression'}, lvl=1},
    Scission = {'Earth', Liquefaction={1,'Liquefaction'}, Reverberation={1,'Reverberation'}, Detonation={1,'Detonation'}, lvl=1},
    Detonation = {'Wind', Compression={2,'Gravitation'}, Scission={1,'Scission'}, lvl=1},
    Impaction = {'Lightning', Liquefaction={1,'Liquefaction'}, Detonation={1,'Detonation'}, lvl=1},
}

chainbound = {}
chainbound[1] = L{'Compression','Liquefaction','Induration','Reverberation','Scission'}
chainbound[2] = L{'Gravitation','Fragmentation','Distortion'} + chainbound[1]
chainbound[3] = L{'Light','Darkness'} + chainbound[2]

local aeonic_weapon = {
    [20515] = 'Godhands',
    [20594] = 'Aeneas',
    [20695] = 'Sequence',
    [20843] = 'Chango',
    [20890] = 'Anguta',
    [20935] = 'Trishula',
    [20977] = 'Heishi Shorinken',
    [21025] = 'Dojikiri Yasutsuna',
    [21082] = 'Tishtrya',
    [21147] = 'Khatvanga',
    [21485] = 'Fomalhaut',
    [21694] = 'Lionheart',
    [21753] = 'Tri-edge',
    [22117] = 'Fail-Not',
    [22131] = 'Fail-Not',
    [22143] = 'Fomalhaut'
}

initialize = function(text, settings)
    if not windower.ffxi.get_info().logged_in then
        return
    end
    if not info.job then
        local player = windower.ffxi.get_player()
        info.job = player.main_job
        info.player = player.id
    end
    local properties = L{}
    if settings.Show.timer[info.job] then
        properties:append('${timer}')
    end
    if settings.Show.step[info.job] then
        properties:append('Step: ${step} → ${name}')
    end
    if settings.Show.props[info.job] then
        properties:append('[${props}] ${elements}')
    elseif settings.Show.burst[info.job] then
        properties:append('${elements}')
    end
    properties:append('${disp_info}')
    text:clear()
    text:append(properties:concat('\n'))
end
skill_props:register_event('reload', initialize)

function update_weapon()
    if not settings.Show.weapon[info.job] then
        return
    end
    local main_weapon = windower.ffxi.get_items(info.main_bag, info.main_weapon).id
    if main_weapon ~= 0 then
        info.aeonic = aeonic_weapon[main_weapon] or info.range and aeonic_weapon[windower.ffxi.get_items(info.range_bag, info.range).id]
        return
    end
    if not check_weapon or coroutine.status(check_weapon) ~= 'suspended' then
        check_weapon = coroutine.schedule(update_weapon, 10)
    end
end

function aeonic_am(step)
    for x=270,272 do
        if buffs[info.player][x] then
            return 272-x < step
        end
    end
    return false
end

function aeonic_prop(ability, actor)
    if ability.aeonic and (ability.weapon == info.aeonic and actor == info.player or settings.aeonic and info.player ~= actor) then
        return {ability.skillchain[1], ability.skillchain[2], ability.aeonic}
    end
    return ability.skillchain
end

function check_props(old, new)
    for k = 1, #old do
        local first = old[k]
        local combo = sc_info[first]
        for i = 1, #new do
            local second = new[i]
            local result = combo[second]
            if result then
                return unpack(result)
            end
            if #old > 3 and combo.lvl == sc_info[second].lvl then
                break
            end
        end
    end
end

function get_skills(abilities, active, resource, AM)
    local tt = {{},{},{},{}}
    for k=1,#abilities do
        local ability_id = abilities[k]
        local skillchain = skills[resource][ability_id]
        if skillchain then
            local lv, prop, aeonic = check_props(active, aeonic_prop(skillchain, info.player))
            if prop then
                prop = AM and aeonic or prop
                local temp = {}
                temp.name = res[resource][ability_id].name
                temp.prop = prop
                temp.text = settings.color and
                    '%-16s → Lv.%d %s%-14s\\cr':format(res[resource][ability_id].name, lv, colors[prop], prop) or
                    '%-16s → Lv.%d %-14s':format(res[resource][ability_id].name, lv, prop)
                tt[lv][#tt[lv]+1] = temp
            end
        end
    end
    return tt;
end

function tableContains(testtable, value)
  for i = 1,#testtable do
    if (testtable[i] == value) then
      return true
    end
  end
  return false
end

function tableCombine(dst, src)
    for i = 1,#src do
        for j = 1,#src[i] do
            dst[i][#dst[i]+1] = src[i][j]
        end
    end
    
    return dst
end

function find_weaponskill(tempTable, reson)
--    local tt = {{},{},{},{}}
--    tt = get_skills(windower.ffxi.get_abilities().weapon_skills, reson.active, 'weapon_skills', info.aeonic and aeonic_am(reson.step))
    
    for x=1,#settings.autows.levelPriority,1 do
        local lp = settings.autows.levelPriority[x]
        for k=#tempTable[lp],1,-1 do
            local name = tempTable[lp][k].name
            if not tableContains(settings.autows.blacklist, name) then
                if lp ~= 3 or tempTable[lp][k].prop == settings.autows.chainPriority or k == 1 then
                    autowsNextWS = tempTable[lp][k].name
                    tempTable[lp][k].text = tempTable[lp][k].text .. '*'
                    return tempTable
                else
                    last_lp = lp
                    last_k = k
                end
            end
        end
        if (last_lp ~= nil) and (last_k ~= nil) then
            autowsNextWS = tempTable[last_lp][last_k].name
            tempTable[last_lp][last_k].text = '*' .. tempTable[last_lp][last_k].text
            return tempTable
        end
    end
    
    return tempTable
end

function check_results(reson)
    local tempTable = {{},{},{},{}}
    local resultTable = {{},{},{},{}}
    local outputTable = {}
    if settings.Show.spell[info.job] and info.job == 'SCH' then
        tempTable = get_skills({0,1,2,3,4,5,6,7}, reson.active, 'elements')
        resultTable = tableCombine(resultTable, tempTable)
    elseif settings.Show.spell[info.job] and info.job == 'BLU' then
        tempTable = get_skills(windower.ffxi.get_mjob_data().spells, reson.active, 'spells')
        resultTable = tableCombine(resultTable, tempTable)
    elseif settings.Show.pet[info.job] and windower.ffxi.get_mob_by_target('pet') then
        tempTable = get_skills(windower.ffxi.get_abilities().job_abilities, reson.active, 'job_abilities')
        resultTable = tableCombine(resultTable, tempTable)
    end
    if settings.Show.weapon[info.job] then
        tempTable = get_skills(windower.ffxi.get_abilities().weapon_skills, reson.active, 'weapon_skills', info.aeonic and aeonic_am(reson.step))
        if settings.autows.enabled and settings.autows.close then
            tempTable = find_weaponskill(tempTable, reson)
        end
        resultTable = tableCombine(resultTable, tempTable)
    end
    for x=4,1,-1 do
        for k=#resultTable[x],1,-1 do
            outputTable[#outputTable+1] = resultTable[x][k].text
        end
    end
    return _raw.table.concat(outputTable, '\n')
end

function colorize(t)
    local temp
    if settings.color then
        temp = {}
        for k=1,#t do
            temp[k] = '%s%s\\cr':format(colors[t[k]], t[k])
        end
    end
    return _raw.table.concat(temp or t, ',')
end

local next_frame = os.clock()

windower.register_event('prerender', function()
    local now = os.clock()

    if now < next_frame then
        return
    end

    next_frame = now + 0.1

    for k, v in pairs(resonating) do
        if v.times - now + 10 < 0 then
            resonating[k] = nil
        end
    end

    local targ = windower.ffxi.get_mob_by_target('t', 'bt')
    targ_id = targ and targ.id
    local reson = resonating[targ_id]
    local timer = reson and (reson.times - now) or 0

    if targ and targ.hpp > 0 then
        if timer > 0 then
            if not reson.closed then
                reson.disp_info = reson.disp_info or check_results(reson)
                local delay = reson.delay
                if now < delay then
                    reson.waiting = true
                    reson.timer = '\\cs(255,0,0)Wait  %.1f\\cr':format(delay - now)
                else
                    if settings.autows.enabled and settings.autows.close and timer > 1 and now - 1 > delay and reson.waiting then
                        local player = windower.ffxi.get_player()
                        if (player ~= nil) and (player.status == 1) and (targ ~= nil) then
                            if player.vitals.tp > settings.autows.closeTp then
                                if settings.autows.hpGt < targ.hpp and targ.hpp < settings.autows.hpLt then
                                    reson.waiting = false
                                    if (autowsNextWS ~= nil) and (autowsNextWS ~= '') then
                                        windower.send_command(('input /ws "%s" <t>'):format(autowsNextWS))
                                        autowsNextWS = ''
                                    end
                                end
                            end
                        end
                    end
                    reson.timer = '\\cs(0,255,0)Go!   %.1f\\cr':format(timer)
                end
            elseif settings.Show.burst[info.job] then
                reson.disp_info = ''
                reson.timer = 'Burst %d':format(timer)
            else
                resonating[targ_id] = nil
                return
            end
            reson.name = res[reson.res][reson.id].name
            reson.props = reson.props or not reson.bound and colorize(reson.active) or 'Chainbound Lv.%d':format(reson.bound)
            reson.elements = reson.elements or reson.step > 1 and settings.Show.burst[info.job] and '(%s)':format(colorize(sc_info[reson.active[1]])) or ''
            skill_props:update(reson)
            skill_props:show()
        else
            if settings.autows.enabled and settings.autows.open then
                local now = os.clock()
                if (now - autowsLastCheck) >= settings.autows.openDelay then
                    local player = windower.ffxi.get_player()
                    if (player ~= nil) and (player.status == 1) and (targ ~= nil) then
                        if player.vitals.tp > 999 then
                            if 5 < targ.hpp and targ.hpp < 99 then
                                if (settings.autows.opener ~= nil) and settings.autows.opener ~= '' then
                                    windower.send_command(('input /ws "%s" <t>'):format(settings.autows.opener))
                                end
                            end
                        end
                    end
                end
            end
            if not visible then
                skill_props:hide()
            end
        end
    elseif not visible then
        skill_props:hide()
    end
end)

function check_buff(t, i)
    if t[i] == true or t[i] - os.time() > 0 then
        return true
    end
    t[i] = nil
end

function chain_buff(t)
    local i = t[164] and 164 or t[470] and 470
    if i and check_buff(t, i) then
        t[i] = nil
        return true
    end
    return t[163] and check_buff(t, 163)
end

categories = S{
    'weaponskill_finish',
    'spell_finish',
    'job_ability',
    'mob_tp_finish',
    'avatar_tp_finish',
    'job_ability_unblinkable',
}

function apply_properties(target, resource, action_id, properties, delay, step, closed, bound)
    local clock = os.clock()
    resonating[target] = {
        res=resource,
        id=action_id,
        active=properties,
        delay=clock+delay,
        times=clock+delay+8-step,
        step=step,
        closed=closed,
        bound=bound
    }
    if target == targ_id then
        next_frame = clock
    end
end

function action_handler(act)
    local actionpacket = ActionPacket.new(act)
    local category = actionpacket:get_category_string()

    if not categories:contains(category) or act.param == 0 then
        return
    end

    local actor = actionpacket:get_id()
    local target = actionpacket:get_targets()()
    local action = target:get_actions()()
    local message_id = action:get_message_id()
    local add_effect = action:get_add_effect()
    --local basic_info = action:get_basic_info()
    local param, resource, action_id, interruption, conclusion = action:get_spell()
    local ability = skills[resource] and skills[resource][action_id]

    if add_effect and conclusion and skillchain_ids:contains(add_effect.message_id) then
        local skillchain = add_effect.animation:ucfirst()
        local level = sc_info[skillchain].lvl
        local reson = resonating[target.id]
        local delay = ability and ability.delay or 3
        local step = (reson and reson.step or 1) + 1

        if level == 3 and reson and ability then
            level = check_props(reson.active, aeonic_prop(ability, actor))
        end

        local closed = step > 5 or level == 4

        apply_properties(target.id, resource, action_id, {skillchain}, delay, step, closed)
    elseif ability and (message_ids:contains(message_id) or message_id == 2 and buffs[actor] and chain_buff(buffs[actor])) then
        apply_properties(target.id, resource, action_id, aeonic_prop(ability, actor), ability.delay or 3, 1)
    elseif message_id == 529 then
        apply_properties(target.id, resource, action_id, chainbound[param], 2, 1, false, param)
    elseif message_id == 100 and buff_dur[param] then
        buffs[actor] = buffs[actor] or {}
        buffs[actor][param] = buff_dur[param] + os.time()
    end
end

ActionPacket.open_listener(action_handler)

windower.register_event('incoming chunk', function(id, data)
    if id == 0x29 and data:unpack('H', 25) == 206 and data:unpack('I', 9) == info.player then
        buffs[info.player][data:unpack('H', 13)] = nil
    elseif id == 0x50 and data:byte(6) == 0 then
        info.main_weapon = data:byte(5)
        info.main_bag = data:byte(7)
        update_weapon()
    elseif id == 0x50 and data:byte(6) == 2 then
        info.range = data:byte(5)
        info.range_bag = data:byte(7)
        update_weapon()
    elseif id == 0x63 and data:byte(5) == 9 then
        local set_buff = {}
        for n=1,32 do
            local buff = data:unpack('H', n*2+7)
            if buff_dur[buff] or buff > 269 and buff < 273 then
                set_buff[buff] = true
            end
        end
        buffs[info.player] = set_buff
    end
end)

windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower()
    if cmd == 'move' then
        visible = not visible
        if visible and not skill_props:visible() then
            skill_props:update({disp_info='     --- SkillChains ---\n\n\n\nClick and drag to move display.'})
            skill_props:show()
        elseif not visible then
            skill_props:hide()
        end
    elseif cmd == 'save' then
        local arg = ... and ...:lower() == 'all' and 'all'
        config.save(settings, arg)
        windower.add_to_chat(207, '%s: settings saved to %s character%s.':format(_addon.name, arg or 'current', arg and 's' or ''))
    elseif default.Show[cmd] then
        if not default.Show[cmd][info.job] then
            return error('unable to set %s on %s.':format(cmd, info.job))
        end
        local key = settings.Show[cmd][info.job]
        if not key then
            settings.Show[cmd]:add(info.job)
        else
            settings.Show[cmd]:remove(info.job)
        end
        config.save(settings)
        config.reload(settings)
        windower.add_to_chat(207, '%s: %s info will no%s be displayed on %s.':format(_addon.name, cmd, key and ' longer' or 'w', info.job))--'t' or 'w'
    elseif type(default[cmd]) == 'boolean' then
        settings[cmd] = not settings[cmd]
        windower.add_to_chat(207, '%s: %s %s':format(_addon.name, cmd, settings[cmd] and 'on' or 'off'))
    elseif cmd == 'autows' then
        if ... then
            if ...:lower() == 'on' then
                settings.autows.enabled = true
            elseif ...:lower() == 'off' then
                settings.autows.enabled = false
            end
        end
                    
        windower.add_to_chat(207, '[AutoWS: %s] Open: %s, Close: %s @ %d < HP%% < %s':format(settings.autows.enabled and 'ON' or 'OFF', settings.autows.open and settings.autows.opener and settings.autows.opener ~= '' and settings.autows.opener or 'OFF', settings.autows.close and 'ON' or 'OFF', settings.autows.hpGt, settings.autows.hpLt))
    elseif cmd == 'eval' then
        assert(loadstring(table.concat({...}, ' ')))()
    else
        windower.add_to_chat(207, '%s: valid commands [save | move | burst | weapon | spell | pet | props | step | timer | color | aeonic]':format(_addon.name))
    end
end)

windower.register_event('job change', function(job, lvl)
    job = res.jobs:with('id', job).english_short
    if job ~= info.job then
        info.job = job
        config.reload(settings)
    end
end)

windower.register_event('zone change', function()
    resonating = {}
    autowsLastCheck = os.clock() + 15
end)

windower.register_event('load', function()
    if windower.ffxi.get_info().logged_in then
        local equip = windower.ffxi.get_items('equipment')
        info.main_weapon = equip.main
        info.main_bag = equip.main_bag
        info.range = equip.range
        info.range_bag = equip.range_bag
        update_weapon()
        buffs[info.player] = {}
        autowsLastCheck = os.clock()
    end
end)

windower.register_event('unload', function()
    coroutine.close(check_weapon)
end)

windower.register_event('logout', function()
    coroutine.close(check_weapon)
    check_weapon = nil
    info = {}
    resonating = {}
    buffs = {}
end)
