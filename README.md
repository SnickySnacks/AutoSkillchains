# AutoSkillChains
### AutoWS + Active Battle Skillchain Display.

AutoWS doesn't have a lot of commands for setting the config yet, sorry

    //asc autows        -- display autows information

    //asc autows on/off -- turns autows on or off

    //asc autows reload -- reloads your autows config

AutoWS settings.  Most settings are currently only available in autows-default.xml.
Create an autows-job.xml for job specific config, i.e. autows-PUP.xml
Make a subdirectory with your character name for character specific configs, i.e. data\Snicky\autows-PUP.xml

    enabled            -- autows is enabled
    
    open               -- open skillchains
    
    openTp             -- minimum tp to weaponskill when opening
    
    openWsDelay        -- delay between weaponskill attempts, to avoid spamming
    
    opener             -- weaponskill to use when opening
    
    waitForMB          -- whether to wait for the magic burst window to close before opening a new skillchain

    waitForSC          -- whether to wait for the skillchain window if not able to continue the current skillchain
    
    close              -- close skillchains
    
    closeTp            -- minimum tp to weaponskill when closing

    closeWsDelay       -- delay between weaponskill attempts, to avoid spamming

    closeWindowDelay   -- delay after window opens before attempting to weaponskill

    closeWindowMinimum -- minimum amount of time that can be remaining in the window and still attempt a weaponskill
    
    levelPriority      -- the priority of what skillchain level to make, remove a level to avoid it entirely
    
    chainPriority      -- prioritize Light or Darkness when making a level 3 skillchain

    closeWsPriority    -- after checking chainPriority, which weaponskill should be used
    
    blacklist          -- all the aoe weaponskills you probably don't want to use
    
    hpGt               -- percentage of hps the mob must be above when considering to weaponskill, helps avoid overkill
    
    hpLt               -- percentage of hps the mob must be below when considering to weaponskill, helps avoid (too far)

Displays a text object containing skillchain elements resonating on current target, timer for skillchain window,
along with a list of weapon skills that can skillchain based on the weapon you have currently equipped. 

    //asc color    -- colorize properties and elements
    
    //asc move     -- displays text box click and drag it to desired location.

    //asc save     -- save settings to current character.

    //asc save all -- save settings to all characters.

The following commands toggle the display information and are saved on a per job basis.

    //asc spell    -- sch immanence and blue magic spells.

    //asc pet      -- smn and bst pet skills.

    //asc weapon   -- weapon skills. For jobs like SMN, I recommend turning weapon off so Blood Pacts are prioritized.

    //asc burst    -- magic burst elements.

    //asc props    -- skillchain properties currently active on target.

    //asc timer    -- skillchain window timer.

    //asc step     -- current weaponskill step information.

More settings related to text object can be found within the settings.xml, generated on addon load
