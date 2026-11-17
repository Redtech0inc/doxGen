local function arrowRead(arrow,arrowColor,char)
    local color = term.getTextColor()
    if type(arrowColor) == "number" then
        term.setTextColor(arrowColor)
    end
    term.write(arrow)
    term.setTextColor(color)

    return read(char)
end

local function setupFolder(folderPath)
    if not fs.isDir(folderPath) then
        if fs.exists(folderPath) then
            error("please delete or rename '"..folderPath.."' for setup stage to work")
        end
        fs.makeDir(folderPath)
    end
end

local function warn(msg)
    local color = term.getTextColor()
    term.setTextColor(colors.orange)
    print("warn: "..tostring(msg))
    term.setTextColor(color)
end

local getSimpleJSONStyleMap = function(_,_)end --* placeholder for VSCode syntax detection

local function jsonStyleToString(value, indents)
    if type(value) == "nil" then return "null"
    elseif type(value) == "number" or type(value) == "boolean" then return tostring(value)
    elseif type(value) == "table" then return getSimpleJSONStyleMap(value, indents)
    end
    return "\""..(tostring(value):gsub("\"","")).."\""
end

function getSimpleJSONStyleMap(map, indents)
    local output = "{\n"
    local firstItr = true
    local indentStr = ("    "):rep(indents)
    for k,v in pairs(map) do
        if firstItr then
            output = output..indentStr.."\""..tostring(k).."\": "..jsonStyleToString(v, indents+1)
        else
            output = output..",\n"..indentStr.."\""..tostring(k).."\": "..jsonStyleToString(v, indents+1)
        end
        firstItr = false
    end
    if indents > 1 then return output.."\n"..("    "):rep(indents-1).."}" end
    return output.."\n}"
end

local function getPathString(path)
    if #path == 0 or path == "/" then return "root" end
    return path
end

local function getFileNameNoExtension(fileName)
    local output = fileName:match("(.+)%.[^%.]+$")

    if not output then return fileName end
    return output
end

local function makeSettings()
    local genSettings = {}

    genSettings.misc={}
    genSettings.misc.typeSep = "|"
    genSettings.misc.summaryPathDiv = "/"
    genSettings.misc.warnParagraph = "style=\"color:red;\""
    
    genSettings.formatting={}
    genSettings.formatting.inputs = "<b>({types})</b> {name}: {desc}"
    genSettings.formatting.returns = "<b>({types})</b> {name}: {desc}"
    genSettings.formatting.seeAlso = "[{label}]({file}): {desc}"

    genSettings.flags = {}
    genSettings.flags.docLocals = false

    return genSettings
end

local function validateSettings(settings,settingsPath)
    local expectation = makeSettings()

    local function recursiveFiltering(setSubTbl, expSubTbl)
        if type(setSubTbl) ~= "table" then
            setSubTbl = expSubTbl
            return true, true, expSubTbl
        end

        local wasChanged = false
        for k,v in pairs(expSubTbl) do
            if type(v) == "table" then
                local internalChange, shouldReplace, newSettings = recursiveFiltering(setSubTbl[k], v)
                if shouldReplace then
                    setSubTbl[k] = newSettings
                end

                if internalChange then wasChanged = true end
            elseif type(v) ~= type(setSubTbl[k]) then
                setSubTbl[k] = v
                wasChanged = true
            end
        end
        return wasChanged
    end

    local rewriteFile = recursiveFiltering(settings,expectation) --don't need extra logic here cause load settings ensures that settings is a table
    if rewriteFile then
        local file = io.open(settingsPath,"w")
        if not file then
            warn("cannot update settings file ("..settingsPath..")")
            return settings
        end

        file:write(getSimpleJSONStyleMap(settings,1))
        file:close()
    end
    return settings
end

local function loadSettings(mountPath)
    local output

    local settingsPath = fs.combine(mountPath,"genSettings.json")
    if not fs.exists(settingsPath) then
        output = makeSettings()

        local file = io.open(settingsPath,"w")
        if not file then
            warn("cannot create settings file ("..settingsPath..")")
            return output
        end

        file:write(getSimpleJSONStyleMap(output,1))
        file:close()
    else
        local file = io.open(settingsPath,"r")
        if not file then
            warn("cannot read settings file ("..settingsPath..")")
            return output
        end

        output = textutils.unserialiseJSON(file:read("a"))

        file:close()

        if type(output) == "table" then return validateSettings(output, settingsPath)
        else output = makeSettings()
        end
    end

    return output
end

local mountPath = fs.getDir(shell.getRunningProgram())
if mountPath == "rom/" then mountPath = "" end

local docsFolderPath = fs.combine(mountPath,"docs")
local logsFolderPath = fs.combine(mountPath,"logs")

setupFolder(docsFolderPath)
setupFolder(logsFolderPath)

local genSettings = loadSettings(mountPath)

print()
term.setTextColor(colors.blue)
print("please enter the path of the directory you would like to generate documentations for")
term.setTextColor(colors.orange)
print("will recursively iterate over the content if the target is a folder")
term.setTextColor(colors.white)
local filePath = arrowRead("> ",colors.lightGray)
if not fs.exists(filePath) or filePath == "" then error("cannot use '"..getPathString(filePath).."' as input either doesn't exist or is protected")
end

local outputFolderPath = fs.combine(docsFolderPath,getFileNameNoExtension(fs.getName(filePath)))

--[[
format:
    {
        def = "name of method",
        desc = { <- use table to preserve line format
                "description line 1",
                "desc line 2",
                ...
            },
        inputs = { <- if inputs, description and returns empty just says nothing
            {
                name = "input name",
                types = { <- if nil assumes any
                    "type of input",
                    "2nd type of input",
                    ...
                },
                desc = "desc"
            },
            ...
        },
        returns = { <- if empty assumes nil as return
            {
                name = "name of the return", <- just there for anyone that needs it
                types = { <- if empty assumes any type
                    "type of return",
                    "2nd type of return"
                }
                desc = "description of return"
            },
            ...
        }
    },
    ...
]]

local function parseTokens(line)
    if line:sub(1, 3) ~= "---" then
        return {}
    end

    local output = {}

    for value in line:sub(4):gmatch("%S+") do
        if #output == 0 then output[1] = value:lower()
        else output[#output+1] = value
        end
    end

    return output
end

local function splitTypes(typeString)
    local types = {}

    for typeName in typeString:gmatch("[^|]+") do
        types[#types + 1] = typeName
    end
    --if #types == 0 then return {"any"} end
    return types
end

local function captureParameter(tokens,methodTbl)
    local data = {}

    data.name = tokens[2]
    data.types = splitTypes(tokens[3])
    data.desc = table.concat(tokens, " ", 4)

    methodTbl.inputs[#methodTbl.inputs+1] = data
end

local function captureReturn(tokens, methodTbl)
    local data = {}

    data.name = tokens[3]
    data.types = splitTypes(tokens[2])
    data.desc = table.concat(tokens, " ", 4)

    methodTbl.returns[#methodTbl.returns+1] = data
end

local function captureExplanation(tokens, methodTbl)
    methodTbl.exampleDesc[#methodTbl.exampleDesc+1] = table.concat(tokens," ",2)
end

local function captureSeeAlso(tokens, methodTbl)
    local data = {}

    data.file = tokens[2]
    data.label = tokens[3]
    data.desc = table.concat(tokens," ",4)

    methodTbl.seeAlso[#methodTbl.seeAlso+1] = data
end

local function resetMethodTbl()
    local methodTbl = {
        def="",
        desc = {},
        inputs = {},
        returns = {},
        exampleLines = {},
        exampleDesc = {},
        seeAlso = {},
        warnings = {}
    }
    return methodTbl
end

local instructions = {}
instructions["@param"] = captureParameter
instructions["@return"] = captureReturn
instructions["@explanation"] = captureExplanation
instructions["@see"] = captureSeeAlso

local lineExpr = {}

lineExpr["@example"] = function(line, methodTbl)
    methodTbl.exampleLines[#methodTbl.exampleLines+1] = line:sub(13)
end
lineExpr["@warn"] = function(line, methodTbl)
    methodTbl.warnings[#methodTbl.warnings+1] = line:sub(10)
end

local function tokenizeFile(filePath)
    local docTokens = {}
    local methodTbl = resetMethodTbl();

    for line in io.lines(filePath) do

        local tokens = parseTokens(line)

        if instructions[tokens[1]] then
            instructions[tokens[1]](tokens, methodTbl)

        elseif #tokens > 0 then --must preserve case

            if lineExpr[tokens[1]] then
                lineExpr[tokens[1]](line,methodTbl)
            else
                methodTbl.desc[#methodTbl.desc+1] = line:sub(4) --use this to preserve written form
            end

        else
            if #methodTbl.inputs > 0 or #methodTbl.returns > 0 or #methodTbl.desc > 0 then --only check if there is a active documentation
                local name = line:match("function%s+([%w_%.:]+%b())")
                if not genSettings.flags.docLocals and name and line:match("^%s*local%s") then
                    --reset method desc tracking cause this isn't public
                    methodTbl = resetMethodTbl();
                elseif name then
                    methodTbl.def = name

                    docTokens[#docTokens+1] = methodTbl

                    --reset method tracking
                    methodTbl = resetMethodTbl();
                end
            end
        end
    end

    return docTokens
end

local function formatString(format, valueTbl)
    return format:gsub("{([^}]+)}", function(tag)
        return tostring(valueTbl[tag] or "")
    end)
end

local function getTypesStr(types)
    if type(types) ~= "table" then types = {} end
    if #types == 0 then
        return "any"
    else
        return table.concat(types,genSettings.misc.typeSep)
    end
end

local serializers = {
    {
        index = "desc",
        func = function(file, method)
            file:write("### Description:\n")
            for j=1,#method.desc do
                file:write(method.desc[j],"<br>\n")
            end
        end
    },
    {
        index = "inputs",
        func = function(file, method)
            file:write("### Parameters:\n")
            local input
            for j=1,#method.inputs do
                input = method.inputs[j]

                file:write(
                    formatString(
                        genSettings.formatting.inputs,
                        {
                            name = input.name,
                            desc = input.desc,
                            types = getTypesStr(input.types)
                        }
                    )
                    ,"<br>\n"
                )
            end
        end
    },
    {
        index = "returns",
        func = function(file, method)
            file:write("### Returns:\n")
            local returnData
            for j=1,#method.returns do
                returnData = method.returns[j]

                file:write(
                    formatString(
                        genSettings.formatting.returns,
                        {
                            name = returnData.name,
                            desc = returnData.desc,
                            types = getTypesStr(returnData.types)
                        }
                    ),
                    "<br>\n"
                )
            end
        end
    },
    {
        index = "exampleLines",
        func = function(file, method)
            file:write("### Example:\n```lua\n")
            for j=1,#method.exampleLines do
                file:write(method.exampleLines[j],"\n")
            end
            file:write("```\n")

            if #method.exampleDesc > 0 then
                file:write("#### Explanation:\n")
                for j=1,#method.exampleDesc do
                    file:write(method.exampleDesc[j],"<br>\n")
                end
            end
        end
    },
    {
        index = "warnings",
        func = function(file, method)
            file:write("<p "..genSettings.misc.warnParagraph..">\n")
            file:write("    <b>WARNINGS:</b><br>\n")
            for j=1,#method.warnings do
                file:write("    "..method.warnings[j],"<br>\n")
            end
            file:write("</p>\n")
        end
    },
    {
        index = "seeAlso",
        func = function(file, method)
            file:write("### See Also:\n")
            local seeAlso
            for j=1,#method.seeAlso do
                seeAlso = method.seeAlso[j]
                file:write(
                    formatString(
                        genSettings.formatting.seeAlso,
                        seeAlso
                    )
                    ,"<br>\n"
                )
            end
        end
    }
}

local function generateDocs(docTokens, name, backPath, parentOutputPath)
    local outputPath = fs.combine(parentOutputPath,name..".md")

    local file = io.open(outputPath,"w")

    if not file then
        warn("cannot generate docs for "..outputPath.." file handle won't open")
        return;
    end

    file:write("# "..name,"\n")

    if backPath then file:write("back to package ["..fs.getName(backPath).."]("..backPath..".md)\n") end
    file:write("\n")

    local method
    for i=1,#docTokens do
        method = docTokens[i]

        file:write("## "..method.def,"\n\n")

        local serializer
        for j=1,#serializers do
            serializer = serializers[j]

            if type(method[serializer.index]) == "table" then
                if #method[serializer.index] > 0 then
                    serializer.func(file, method)
                    file:write("\n")
                end
            else
                warn(serializer.index.." is not a sub table of a method token")
            end
        end

        if i ~= #docTokens then file:write("\n") end
    end
    if backPath then file:write("---\nback to package ["..fs.getName(backPath).."]("..backPath..".md)") end
    file:close()
end

local logger

--[[
    hasFiles = false/true
    files ={
        {   
            path = "just the file name with extension"
            tokens=nil
        },
        ...
    },
    folders = {
        {
            hasFiles = false/true
            files ={
                {
                    path="just the file name with extension"
                    tokens=nil
                },
                ...
            },
            folders ={
                ...
            }
        }
    }
]]
local docTree = {
    path = getFileNameNoExtension(fs.getName(filePath)),
    hasFiles = false,
    files={},
    folders={}
}

local function insertFolder(path,currentSubTable)
    currentSubTable.folders[#currentSubTable.folders+1]={
        path = path,
        hasFiles = false,
        files={},
        folders={}
    }
    return #currentSubTable.folders
end

local function insertFile(file,tokens,currentSubTable)
    if #tokens == 0 then return false end
    currentSubTable.hasFiles = true
    currentSubTable.files[#currentSubTable.files+1]={
        path=file,
        tokens = tokens
    }
    return true
end

local function scanFiles(path,currentSubTable)
    local fileList = fs.list(path)

    local hasFiles = false
    local itemPath
    for i=1,#fileList do
        itemPath = fs.combine(path,fileList[i])

        if fs.isDir(itemPath) then
            local index = insertFolder(fileList[i],currentSubTable)
            if scanFiles(itemPath, currentSubTable.folders[index]) then
                currentSubTable.hasFiles = true
                hasFiles = true
            end
        else
            if insertFile(getFileNameNoExtension(fileList[i]), tokenizeFile(itemPath), currentSubTable) then hasFiles = true end
        end

    end

    return hasFiles
end

local function getBackPath(folderName, layer, skips)
    if layer <= 1 then return folderName end
    return ("../"):rep(skips+1)..folderName
end

local function getRelativePath(fromFile, toFile)
    local fromParts = {}
    local toParts = {}

    for part in fs.getDir(fromFile):gmatch("[^/]+") do
        fromParts[#fromParts+1] = part
    end

    for part in toFile:gmatch("[^/]+") do
        toParts[#toParts+1] = part
    end

    -- Find the common path prefix
    local common = 0

    while common < #fromParts and common < #toParts
        and fromParts[common+1] == toParts[common+1] do
        common = common + 1
    end

    local result = {}

    -- Go upwards from the current directory
    for i = common+1, #fromParts do
        result[#result+1] = ".."
    end

    -- Then descend into the target path
    for i = common+1, #toParts do
        result[#result+1] = toParts[i]
    end

    return table.concat(result, "/")
end

local function useDocTree(docBranch, folderName, skips, layer, outputPath, indexPath, parentSummaryPath)
    local summaryOutputPaths = {}

    local generationPath = outputPath
    if layer == 0 then generationPath = fs.combine(generationPath, folderName) end

    local currentSummaryPath
    if #docBranch.files > 0 then currentSummaryPath = generationPath..".md" end

    local childParentSummaryPath = currentSummaryPath or parentSummaryPath

    local file
    for i=1,#docBranch.files do
        file = docBranch.files[i]
        generateDocs(file.tokens, file.path, getBackPath(folderName, layer+1, skips), outputPath)
    end

    local folder
    for i=1,#docBranch.folders do
        folder = docBranch.folders[i]

        local newSkips = skips
        local newIndexPath = fs.combine(indexPath, folder.path)

        if #folder.files == 0 then
            newSkips = newSkips + 1
        else
            summaryOutputPaths[#summaryOutputPaths+1] = newIndexPath
            newSkips = 0
            if layer > 0 then newIndexPath = fs.getName(newIndexPath) end
        end

        if folder.hasFiles then
            local summaryOut = useDocTree(folder, folder.path, newSkips, layer+1, fs.combine(outputPath, folder.path), newIndexPath, childParentSummaryPath)

            if #folder.files == 0 then
                for j=1,#summaryOut do
                    summaryOutputPaths[#summaryOutputPaths+1] = summaryOut[j]
                end
            end
        end
    end

    if currentSummaryPath then
        local file = io.open(currentSummaryPath,"w")

        local summaryHead = outputPath:sub(#docsFolderPath+2)

        if genSettings.misc.summaryPathDiv ~= "/" then
            summaryHead = summaryHead:gsub("/",genSettings.misc.summaryPathDiv)
        end

        file:write("# Package: "..summaryHead.."\n\n")

        if parentSummaryPath then
            local backPath = getRelativePath(currentSummaryPath,parentSummaryPath)
            file:write("back to ["..getFileNameNoExtension(fs.getName(parentSummaryPath)).."]("..backPath..")\n")
        end

        if #summaryOutputPaths > 0 then
            file:write("## Sub-Packages:\n")
            for i=1,#summaryOutputPaths do
                file:write("["..summaryOutputPaths[i].."]("..summaryOutputPaths[i]..".md)<br>\n")
            end
            file:write("\n")
        end

        if #docBranch.files > 0 then
            file:write("## Files:\n")
            local path
            for i=1,#docBranch.files do
                path =docBranch.files[i].path
                if layer ~= 0 then path = fs.combine(folderName,path) end

                file:write("["..docBranch.files[i].path.."]("..path..".md)")
            end
        end

        file:close()
    end

    return summaryOutputPaths
end

fs.delete(outputFolderPath)
logger = io.open(fs.combine(logsFolderPath,getFileNameNoExtension(fs.getName(filePath))..".log"),"w")

--TODO: hook up logger
if fs.isDir(filePath) then
    scanFiles(filePath,docTree)

    if docTree.hasFiles then
        useDocTree(docTree, docTree.path, 0, 0, outputFolderPath, "")

        --logger:write(textutils.serialise(docTree))

        term.setTextColor(colors.gray)
        print("generated documentation in '"..outputFolderPath.."/'")
        term.setTextColor(colors.white)
    else
        warn("There are no files with a documentation attached")
    end
else--file
    generateDocs(tokenizeFile(filePath), getFileNameNoExtension(fs.getName(filePath)), nil, outputFolderPath)
end

if logger then logger:close() end