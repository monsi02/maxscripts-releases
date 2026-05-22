macroScript GroupIt_no_UI
category:"SimonScripts"
tooltip:"GroupIt_no_UI orientation is based on first selected object orientation"
buttontext:"GroupIt_no_UI"
autoUndoEnabled:false

(
	local SS_CURRENT_VERSION = "1.4.9"
	local SS_SCRIPT_NAME     = "GroupIt"
	local SS_SCRIPT_FILENAME = "SimonScripts-GroupIt_no_UI.mcr"
	local SS_SCRIPTSPOT_URL  = "https://www.scriptspot.com/3ds-max/scripts/group-it"
	local SS_VERSION_URL     = "https://raw.githubusercontent.com/monsi02/maxscripts-releases/main/GroupIt/version.txt"
	local SS_PACKAGE_URL     = "https://raw.githubusercontent.com/monsi02/maxscripts-releases/main/GroupIt/SimonScripts-GroupIt_V1-4-9_No_UI.mcr"
	
	-- =============================================
-- SS_UpdateChecker.ms
-- Auto-update system for Scriptspot scripts
-- 
-- Place this file in your #userScripts folder.
--
-- In each of your .mcr scripts, add at the top:
--
--   global SS_CURRENT_VERSION = "1.4.9"
--   global SS_SCRIPT_NAME     = "GroupIt"
--   global SS_SCRIPT_FILENAME = "SimonScripts-GroupIt_no_UI.mcr"
--   global SS_SCRIPTSPOT_URL  = "https://www.scriptspot.com/3ds-max/scripts/group-it"
--   global SS_VERSION_URL     = "https://raw.githubusercontent.com/monsi02/maxscripts-releases/main/GroupIt/version.txt"
--   global SS_PACKAGE_URL     = "https://raw.githubusercontent.com/monsi02/maxscripts-releases/main/GroupIt/SimonScripts-GroupIt_V1-4-9_No_UI.mcr"
--
--   fileIn ((getDir #userScripts) + "\\SS_UpdateChecker.ms")
--   checkForUpdate()
-- =============================================

-- ---------------------------------------------
fn curlFetch url outFile =
(
    if doesFileExist outFile do deleteFile outFile

    local psi = dotNetObject "System.Diagnostics.ProcessStartInfo" "curl.exe"
    psi.Arguments       = "--ssl-no-revoke -L -s --max-time 10 \"" + url + "\" -o \"" + outFile + "\""
    psi.UseShellExecute = false
    psi.CreateNoWindow  = true

    local proc = dotNetObject "System.Diagnostics.Process"
    proc.StartInfo = psi
    try ( proc.Start(); proc.WaitForExit 12000 ) catch ( return false )

    doesFileExist outFile and (getFileSize outFile) > 0
)

-- ---------------------------------------------
fn readTextFile path =
(
    local result = ""
    try
    (
        local f = openFile path mode:"r"
        while not eof f do result += readline f
        close f
    )
    catch ()
    trimRight (trimLeft result)
)

-- ---------------------------------------------
fn versionIsNewer remoteVer localVer =
(
    local r = filterString remoteVer "."
    local l = filterString localVer  "."
    local isNewer = false
    local minCount = if r.count < l.count then r.count else l.count
    for i = 1 to minCount do
    (
        local rv = execute r[i]
        local lv = execute l[i]
        if rv > lv then ( isNewer = true; exit )
        if rv < lv then ( isNewer = false; exit )
    )
    if not isNewer and r.count > l.count do isNewer = true
    isNewer
)

-- ---------------------------------------------
fn getInstalledVersion scriptFilename =
(
    local ver = undefined
    local mcr = (getDir #userMacros) + "\\" + scriptFilename
    if not doesFileExist mcr do return undefined

    try
    (
        local f = openFile mcr mode:"r"
        while not eof f do
        (
            local line = readline f
            if (findString line "SS_CURRENT_VERSION") != undefined and \
               (findString line "=") != undefined then
            (
                local q1 = findString line "\""
                if q1 != undefined then
                (
                    local q2 = findString line "\"" (q1 + 1)
                    if q2 != undefined do
                        ver = substring line (q1 + 1) (q2 - q1 - 1)
                )
                exit
            )
        )
        close f
    )
    catch ()
    ver
)

-- ---------------------------------------------
fn checkForUpdate silent:true =
(
    format "[ UpdateChecker:% ] Checking for updates...\n" SS_SCRIPT_NAME

    -- Resolve local version: explicit global > read from file > force update
    local localVer = undefined
    try ( if SS_CURRENT_VERSION != undefined do localVer = SS_CURRENT_VERSION ) catch ()

    if localVer == undefined then
    (
        localVer = getInstalledVersion SS_SCRIPT_FILENAME
        if localVer != undefined then
            format "[ UpdateChecker:% ] Auto-detected version: %\n" SS_SCRIPT_NAME localVer
        else
        (
            format "[ UpdateChecker:% ] No version found - forcing update check.\n" SS_SCRIPT_NAME
            localVer = "0.0.0"
        )
    )
    else
        format "[ UpdateChecker:% ] Local version: %\n" SS_SCRIPT_NAME localVer

    -- Fetch remote version
    local tmpVer = (getDir #temp) + "\\ss_ver_" + SS_SCRIPT_NAME + ".txt"

    format "[ UpdateChecker:% ] Fetching remote version...\n" SS_SCRIPT_NAME
    if not (curlFetch SS_VERSION_URL tmpVer) do
    (
        format "[ UpdateChecker:% ] Could not reach version file - silent fail.\n" SS_SCRIPT_NAME
        return false
    )

    local remoteVer = readTextFile tmpVer
    deleteFile tmpVer

    if remoteVer == "" do
    (
        format "[ UpdateChecker:% ] Empty version string - silent fail.\n" SS_SCRIPT_NAME
        return false
    )

    format "[ UpdateChecker:% ] Remote: % | Local: %\n" SS_SCRIPT_NAME remoteVer localVer

    -- Compare versions
    if not (versionIsNewer remoteVer localVer) do
    (
        format "[ UpdateChecker:% ] Already up to date.\n" SS_SCRIPT_NAME
        if not silent do
            messageBox ("You have the latest version (v" + localVer + ").") \
                title:(SS_SCRIPT_NAME + " — Up to Date")
        return false
    )

    -- Prompt user
    format "[ UpdateChecker:% ] Update available: %\n" SS_SCRIPT_NAME remoteVer
    local msg = SS_SCRIPT_NAME + " v" + remoteVer + " is available!\n" + \
                "You have v" + localVer + ".\n\n" + \
                "Download and install now?"
    if not (queryBox msg title:(SS_SCRIPT_NAME + " — Update Available")) do
    (
        format "[ UpdateChecker:% ] User declined update.\n" SS_SCRIPT_NAME
        return false
    )

    -- Download to temp first
    format "[ UpdateChecker:% ] Downloading...\n" SS_SCRIPT_NAME
    local tmpPkg  = (getDir #temp) + "\\ss_pkg_" + SS_SCRIPT_NAME + ".mcr"

    if not (curlFetch SS_PACKAGE_URL tmpPkg) do
    (
        format "[ UpdateChecker:% ] Download failed.\n" SS_SCRIPT_NAME
        messageBox "Download failed.\nPlease update manually on Scriptspot." \
            title:(SS_SCRIPT_NAME + " — Download Failed")
        shellLaunch SS_SCRIPTSPOT_URL ""
        return false
    )

    -- Verify temp file isn't a 404 page
    local firstLine = ""
    try
    (
        local f = openFile tmpPkg mode:"r"
        firstLine = readline f
        close f
    )
    catch ()

    if findString firstLine "404" != undefined do
    (
        format "[ UpdateChecker:% ] Download returned 404.\n" SS_SCRIPT_NAME
        deleteFile tmpPkg
        messageBox "Download failed (file not found on server).\nPlease update manually on Scriptspot." \
            title:(SS_SCRIPT_NAME + " — Download Failed")
        shellLaunch SS_SCRIPTSPOT_URL ""
        return false
    )

    -- Copy from temp to #userMacros
    format "[ UpdateChecker:% ] Installing...\n" SS_SCRIPT_NAME
    local destFile = (getDir #userMacros) + "\\" + SS_SCRIPT_FILENAME
    copyFile tmpPkg destFile
    deleteFile tmpPkg

    if not (doesFileExist destFile) do
    (
        format "[ UpdateChecker:% ] Copy to userMacros failed.\n" SS_SCRIPT_NAME
        messageBox "Install failed.\nPlease update manually on Scriptspot." \
            title:(SS_SCRIPT_NAME + " — Install Failed")
        shellLaunch SS_SCRIPTSPOT_URL ""
        return false
    )

    -- Re-execute without reboot
    format "[ UpdateChecker:% ] Loading updated script...\n" SS_SCRIPT_NAME
    local reloaded = false
    try ( fileIn destFile; reloaded = true ) catch ()

    if reloaded then
    (
        format "[ UpdateChecker:% ] Success - loaded v%\n" SS_SCRIPT_NAME remoteVer
        messageBox ("v" + remoteVer + " installed and loaded!\nNo restart needed.") \
            title:(SS_SCRIPT_NAME + " — Updated!")
    )
    else
    (
        format "[ UpdateChecker:% ] fileIn failed - restart needed.\n" SS_SCRIPT_NAME
        messageBox ("v" + remoteVer + " downloaded.\nPlease restart 3ds Max to apply the update.") \
            title:(SS_SCRIPT_NAME + " — Updated!")
    )

    reloaded
)
	
	--fileIn ((getDir #userScripts) + "\\SS_UpdateChecker.ms")
	checkForUpdate()
	
	local sel = selection as array
	if sel.count > 0 then
	(
		TheHold.SuperBegin()
		try(
				undo "Group It"on
				(
					local groupheadOnSingleObj = for o in sel where isgrouphead o and o.children.count == 1 collect o --collect group that contain ony one object
					for o in groupheadOnSingleObj do setGroupOpen o true --open those group  
					if groupheadOnSingleObj.count >0 do delete groupheadOnSingleObj--delete only the groupheads but keep object inside , i had some bug when using groups that has only one object inside them
					if isvalidnode sel[1] do objlayer = sel[1].layer --store the first selected object layer to add the new group to the same layer
					local groupheads =  for o in sel where isValidNode o and isgrouphead o collect o --collect all groupheads in selection
					local topgroupheads = for o in groupheads where finditem sel o.parent == 0 collect o --collect the parent group in the selection
					local parentgroup=#() --create an empty array that will be used to store "parent" group that aren't in selection
					local parentgroupChild --create a variable to hold the collection of children nodes of an eventual non selected master parent group
					for o in sel where isvalidnode o and o.parent != undefined and isGroupHead o.parent and finditem sel o.parent == 0 do appendifunique parentgroup o.parent --collect all "parent" group that aren't in selection
					if parentgroup[1] != undefined and parentgroup[1].children != undefined do (parentgroupChild = for o in parentgroup[1].children collect o) --if there is a group that is a "parent" group of the selected groups or objects it will collect all the nodes that are in the "parents"groups even if they aren't in selection
					local nodetodetach =#() --create an empty array that will be used to store nodes that needs to be detached
					if parentgroupChild != undefined do (for o in sel do (if finditem parentgroupChild o != 0 do append nodetodetach o)) --append the nodes that needs to be dettach from an eventual non selected master group
					if parentgroup != undefined and parentgroup.count > 1 then --if there is multiple non selected parent group
					(
						local tmpArr=#()
						for o in topgroupheads do (setGroupOpen o true; append tmpArr o) --open the selection top hierachy groupheads and append the groupheads to a tmp array
						if tmpArr.count!= 0 do sel = tmpArr --swap the sel array to the temp array to process only the topgroupheads, later in the rest of the code it will use only those top hierarchy group heads avoiding bugs
						try (detachNodesFromGroup sel ) catch(for o in sel do o.parent= undefined)--detach from group the top hierarchy group heads --detachNodesFromGroup nodetodetach was buggy in case of orphan group members
					)
					else if parentgroup != undefined and parentgroup.count <= 1 then ---else if there is one or none "non selected parent group"
					(
						if nodetodetach.count>0 do (try (detachNodesFromGroup nodetodetach ) catch( for o in nodetodetach do o.parent= undefined)) --detach nodes from groups--detachNodesFromGroup nodetodetach was buggy in case of orphan group members
						for o in topgroupheads do setGroupOpen o true  --open the top group herarchy
						if topgroupheads.count >0 do sel = topgroupheads --swap the sel array to the topgroupheads array
						for o in selection do (if not isGroupMember o do append sel o)--add to sel array any non groupheads objects that is in selection 
					)
					local Validobj = for o in sel where isvalidnode o collect o --filterout any non valid objects from the new sel array
					for o in Validobj do objlayer.addNode o
					local firstObj = Validobj[1] --create a new variable to hold the first valid object
					local firstObjMatrix --create a new variable to hold the first valid object matrix
					if firstObj != undefined do firstObjMatrix = firstObj.transform --transfer the first object matrix to the new variable
					local tempDummy = Dummy()--- creates a dummy object
					local groupname = uniqueName "Group" --creates a unique name for the group respecting 3dsmax native way of naming group objects
					local grpobj = group tempDummy name:groupname --creating a group with the dummy inside and giving it the right name
					if firstObjMatrix != undefined do grpobj.transform = firstObjMatrix --transfering the transform matrix of the first object to the empty dummy group
					grpobj.scale = [1,1,1] --reset the scaling values, if the first object have some scaling it would have been transfered as we transfered the all transform matrix
					attachNodesToGroup Validobj grpobj -- attaching to the new group the valid nodes
					if parentgroup.count > 1 do (for i = 1 to parentgroup.count where isvalidnode parentgroup[i] do (setGroupOpen parentgroup[i] false;setGroupOpen  parentgroup[i] true;setGroupOpen  parentgroup[i] false; parentgroup[i].pivot=[parentgroup[i].center.x, parentgroup[i].center.y, parentgroup[i].min.z]))--if there is some "parent" groups is then close them and center their pivots
					local groupheadTodelete = for o in helpers where isgrouphead o and o.children.count == 0 collect o --create an array of the left over groupheads that doesn't have any more children
					delete groupheadTodelete --deletes the left over groupheads
					delete tempDummy --delete the temp dummy
					if objlayer != undefined do objlayer.addNode grpobj --affect it to the stored layer
				)
					
				undo "Center Pivot" on --seperate undo for pivot centering as it was creating a bug,if set with the same undo as the rest , objects where moving from their original position on undo.
				(
					setGroupOpen grpobj true --refresh to make the centerpivot work	
					setGroupOpen grpobj false --refresh to make the centerpivot work		
					--CenterPivot grpobj --uncomment this line and remove next line if you prefer pivot centered
					grpobj.pivot=[grpobj.center.x,grpobj.center.y,grpobj.min.z] --pivot centered but z align at min position
				)
				select grpobj --select the resulting group
				TheHold.SuperAccept("Group It")
			)
			catch
			(
				TheHold.SuperCancel() --if the script crash it cancel TheHold
				messageBox ("GroupIt error:\n" + getCurrentException()) title:"GroupIt" beep:off
			)
	)	
	else ( messageBox "select at least one object" beep:off ) 
	gc light:on	
				
)
