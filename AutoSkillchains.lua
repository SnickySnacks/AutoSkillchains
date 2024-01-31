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
_addon.version = '1.24.01.31'

require('luau')
require('pack')
require('actions')
texts = require('texts')
skills = require('skills')
file = require('files')

_static = S{'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG','SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN'}

default = {}
default.debugLogs = false
default.Show = {burst=_static, pet=S{'BST','SMN'}, props=_static, spell=S{'SCH','BLU'}, step=_static, timer=_static, weapon=_static}
default.UpdateFrequency = 0.2
default.aeonic = false
default.color = false
default.display = {text={size=12,font='Consolas'},pos={x=0,y=0},bg={visible=true}}
default_autows = {}
default_autows.enabled = false
default_autows.open = true
default_autows.openTp = 999
default_autows.openWsDelay = 0.5
default_autows.opener = ''
default_autows.waitForMB = true
default_autows.close = true
default_autows.closeTp = 999
default_autows.closeWsDelay = 0.5
default_autows.closeWindowDelay = 1
default_autows.closeWindowMinimum = 1
default_autows.levelPriority = L{'dummy',3,4,2,1} -- 'dummy' required to keep the list from breaking if there is only 1 number
default_autows.chainPriority = ''
default_autows.closeWsPriority = ''
default_autows.blacklist = L{'Cyclone','Aeolian Edge','Fell Cleave','Sonic Thrust','Spinning Attack','Shockwave','Earth Crusher','Cataclysm','Spinning Scythe','Circle Blade'}
default_autows.hpGt = 3
default_autows.hpLt = 100

settings = config.load(default)

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

        load_autows()

        if autows.enabled then
            if settings.debugLogs then
                windower.add_to_chat(207, "initialize")
            end
            schedule_autows_status()
        end
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

function schedule_autows_status()
    coroutine.close(print_status)
    print_status = coroutine.schedule(print_autows_status, 1)
end

function load_autows()
    local name = windower.ffxi.get_player().name
    local path = 'data\\'
    if windower.dir_exists(windower.addon_path..'data\\'..name) then
        path = path..name..'\\'
    end
    if file.exists(path..'autows-'..info.job..'.xml') then
        default_filt = false
        autows = config.load(path..'autows-'..info.job..'.xml', default_autows)
        config.save(autows)
    elseif not default_filt then
        default_filt = true
        autows = config.load(path..'autows-default.xml', default_autows)
        config.save(autows)
    end
end

function print_autows_status()
    
    if #autows.levelPriority < 2 then
        autows.close = false
    end
    local openerText = 'OFF'
    if autows.open and autows.opener ~= '' then
        if not info.openerValid then
            openerText = openerText..' (Wrong weapon)'
        else
            openerText = autows.opener
        end
    end

    windower.add_to_chat(207, '[AutoWS%s: %s] Open: %s, Close: %s, MB: %s @ %d < HP%% < %s':format(not default_filt and '('..string.upper(info.job)..')' or '', autows.enabled and 'ON' or 'OFF', openerText, autows.close and 'ON' or 'OFF', autows.waitForMB and 'ON' or 'OFF', autows.hpGt, autows.hpLt))
    if autows.close then
        local levelPriority = ''
        local chainPriority = ''
        for x=2,#autows.levelPriority,1 do
            if x > 2 then
                levelPriority = levelPriority..' -> '
            end
            levelPriority = levelPriority..autows.levelPriority[x]
        end
        if autows.chainPriority ~= '' or autows.closeWsPriority ~= '' then
            chainPriority = ', Prioritizing '
            if autows.chainPriority ~= '' then
                chainPriority = chainPriority..autows.chainPriority
            end
            if autows.closeWsPriority ~= '' then
                if autows.chainPriority ~= '' then
                    chainPriority = chainPriority..' and '
                end
                chainPriority = chainPriority..autows.closeWsPriority
            end
        end
        windower.add_to_chat(207, 'Closing Level %s%s':format(levelPriority, chainPriority))
    end
end

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

function update_opener()
    if not settings.Show.weapon[info.job] then
        return
    end
    local main_weapon = windower.ffxi.get_items(info.main_bag, info.main_weapon).id
    if main_weapon ~= 0 then
        if info.last_weapon ~= main_weapon and autows.opener ~= '' then
            info.last_weapon = main_weapon
            local weaponskills = windower.ffxi.get_abilities().weapon_skills
            
            for x=1,#weaponskills,1 do
                if res['weapon_skills'][weaponskills[x]].name == autows.opener then
                    info.openerValid = true
                    if autows.enabled then
                        if settings.debugLogs then
                            windower.add_to_chat(207, "update opener (valid)")
                        end
                        schedule_autows_status()
                    end
                    return
                end
            end
            info.openerValid = false
            if autows.enabled then
                if settings.debugLogs then
                    windower.add_to_chat(207, "update opener (invalid)")
                end
                schedule_autows_status()
            end
        end
        return
    end
    if not check_opener or coroutine.status(check_opener) ~= 'suspended' then
        check_opener = coroutine.schedule(update_opener, 10)
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
    local last_lp, lastk, last_prop

    for x=2,#autows.levelPriority,1 do
        local lp = tonumber(autows.levelPriority[x])
           for k=#tempTable[lp],1,-1 do
            local name = tempTable[lp][k].name
            if not tableContains(autows.blacklist, name) then
                if lp ~= 3 or autows.chainPriority == '' or tempTable[lp][k].prop == autows.chainPriority then
                    if lp ~= 3 or autows.wsPriority == '' or name == autows.wsPriority then
                        autowsNextWS = name
                        return tempTable
                    end
                end

                if (last_prop == nil) or (lp == 3 and autows.chainPriority ~= '' and last_prop ~= autows.chainPriority and tempTable[lp][k].prop == autows.chainPriority) then
                    last_lp = lp
                    last_k = k
                    last_prop = tempTable[lp][k].prop
                end
            end
        end
        if (last_lp ~= nil) and (last_k ~= nil) then
            autowsNextWS = tempTable[last_lp][last_k].name
            return tempTable
        end
    end

    autowsNextWS = ''
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
        if autows.enabled and autows.close then
            tempTable = find_weaponskill(tempTable, reson)
        end
        resultTable = tableCombine(resultTable, tempTable)
    end
    local once = true
    for x=4,1,-1 do
        for k=#resultTable[x],1,-1 do
            if once and autowsNextWS and resultTable[x][k].name == autowsNextWS then
                once = false
                outputTable[#outputTable+1] = settings.color and
                    '*%-15s → Lv.%d %s%-14s\\cr':format(resultTable[x][k].name, x, colors[resultTable[x][k].prop], resultTable[x][k].prop) or
                    '*%-15s → Lv.%d %-14s':format(resultTable[x][k].name, x, resultTable[x][k].prop)
            else
                outputTable[#outputTable+1] = settings.color and
                    '%-16s → Lv.%d %s%-14s\\cr':format(resultTable[x][k].name, x, colors[resultTable[x][k].prop], resultTable[x][k].prop) or
                    '%-16s → Lv.%d %-14s':format(resultTable[x][k].name, x, resultTable[x][k].prop)
            end
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
                    if autows.enabled and autows.close and timer > autows.closeWindowMinimum and now - autows.closeWindowDelay > delay and reson.waiting then
                        if (now - autowsLastCheck) >= autows.closeWsDelay then
                            local player = windower.ffxi.get_player()
                            if (player ~= nil) and (player.status == 1) and (targ ~= nil) then
                                if player.vitals.tp > autows.closeTp then
                                    if autows.hpGt < targ.hpp and targ.hpp < autows.hpLt then
                                        if (autowsNextWS ~= nil) and (autowsNextWS ~= '') then
                                            windower.send_command(('input /ws "%s" <t>'):format(autowsNextWS))
                                            autowsLastCheck = now
                                        end
                                    end
                                end
                            end
                        end
                    end
                    reson.timer = '\\cs(0,255,0)Go!   %.1f\\cr':format(timer)
                end
            else
                if autows.enabled and autows.open and not autows.waitForMB then
                    if (now - autowsLastCheck) >= autows.openWsDelay then
                        local player = windower.ffxi.get_player()
                        if (player ~= nil) and (player.status == 1) and (targ ~= nil) then
                            if player.vitals.tp > autows.openTp then
                                if autows.hpGt < targ.hpp and targ.hpp < autows.hpLt then
                                    if info.openerValid and autows.opener ~= '' then
                                        windower.send_command(('input /ws "%s" <t>'):format(autows.opener))
                                        autowsLastCheck = now
                                    end
                                end
                            end
                        end
                    end
                end
                if settings.Show.burst[info.job] then
                    reson.disp_info = ''
                    reson.timer = 'Burst %d':format(timer)
                else
                    resonating[targ_id] = nil
                    return
                end
            end
            reson.name = res[reson.res][reson.id].name
            reson.props = reson.props or not reson.bound and colorize(reson.active) or 'Chainbound Lv.%d':format(reson.bound)
            reson.elements = reson.elements or reson.step > 1 and settings.Show.burst[info.job] and '(%s)':format(colorize(sc_info[reson.active[1]])) or ''
            skill_props:update(reson)
            skill_props:show()
        else
            if autows.enabled and autows.open then
                if (now - autowsLastCheck) >= autows.openWsDelay then
                    local player = windower.ffxi.get_player()
                    if (player ~= nil) and (player.status == 1) and (targ ~= nil) then
                        if player.vitals.tp > autows.openTp then
                            if autows.hpGt < targ.hpp and targ.hpp < autows.hpLt then
                                if info.openerValid and autows.opener ~= '' then
                                    windower.send_command(('input /ws "%s" <t>'):format(autows.opener))
                                    autowsLastCheck = now
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
    elseif id == 0xAC then
        if settings.debugLogs then
            windower.add_to_chat(207, "ability change")
        end
        update_opener()
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
        config.reload(settings) -- why?
        windower.add_to_chat(207, '%s: %s info will no%s be displayed on %s.':format(_addon.name, cmd, key and ' longer' or 'w', info.job))--'t' or 'w'
    elseif type(default[cmd]) == 'boolean' then
        settings[cmd] = not settings[cmd]
        windower.add_to_chat(207, '%s: %s %s':format(_addon.name, cmd, settings[cmd] and 'on' or 'off'))
    elseif cmd == 'autows' then
        if ... then
            if ...:lower() == 'on' then
                autows.enabled = true
            elseif ...:lower() == 'off' then
                autows.enabled = false
            end
        end
        if settings.debugLogs then
            windower.add_to_chat(207, "command")
        end
        print_autows_status()
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
        autowsNextWS = ''
        local wasEnabled = autows.enabled
        config.reload(settings)
        load_autows()
        
        if autows.enabled or wasEnabled then
            if settings.debugLogs then
                windower.add_to_chat(207, "job change")
            end
            schedule_autows_status()
        end
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
        update_opener()
        buffs[info.player] = {}
        autowsLastCheck = os.clock()
    end
end)

windower.register_event('unload', function()
    coroutine.close(check_opener)
    coroutine.close(check_weapon)
end)

windower.register_event('logout', function()
    coroutine.close(check_opener)
    check_opener = nil
    coroutine.close(check_weapon)
    check_weapon = nil
    info = {}
    resonating = {}
    buffs = {}
end)
