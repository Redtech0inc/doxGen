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

local function getPathString(path)
    if #path == 0 or path == "/" then return "root" end
    return path
end

local function getCleanFileName(fileName)
    local output = fileName:match("(.+)%.[^%.]+$")

    if not output then return fileName end
    return output
end

local mountPath = fs.getDir(shell.getRunningProgram())
if mountPath == "rom/" then mountPath = "" end

local docsFolderPath = fs.combine(mountPath,"docs")

setupFolder(docsFolderPath)

print()
term.setTextColor(colors.blue)
print("please enter the path of the directory you would like to generate documentations for")
term.setTextColor(colors.orange)
print("will recursively iterate over the content if the target is a folder")
term.setTextColor(colors.white)
local filePath = arrowRead("> ",colors.lightGray)
if not fs.exists(filePath) or filePath == "" then error("cannot use '"..getPathString(filePath).."' as input either doesn't exist or is protected")
end

local outputFolderPath = fs.combine(docsFolderPath,getCleanFileName(fs.getName(filePath)))


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
                if name and line:match("^%s*local%s") then --TODO: might add like a flag to allow locals in docs
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

                file:write("<b>(")
                if #input.types == 0 then
                    file:write("any")
                else
                    file:write(table.concat(input.types,"|"))
                end
                file:write(")</b> "..input.name..": "..input.desc,"<br>\n")
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

                file:write("<b>(")
                if #returnData.types == 0 then
                    file:write("any")
                else
                    file:write(table.concat(returnData.types,"|"))
                end
                file:write(")</b> "..returnData.name..": "..returnData.desc,"<br>\n")
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
            file:write("<p style=\"color:red;\">\n")
            file:write("    <b>WARNINGS:</b><br>\n")
            for j=1,#method.warnings do
                file:write("    "..method.warnings[j],"<br>\n")
            end
            file:write("</p>")
        end
    },
    {
        index = "seeAlso",
        func = function(file, method)
            file:write("### See Also:\n")
            local seeAlso
            for j=1,#method.seeAlso do
                seeAlso = method.seeAlso[j]
                file:write("["..seeAlso.label.."]("..seeAlso.file.."): "..seeAlso.desc,"<br>\n")
            end
        end
    }
}

local function generateDocs(filePath, backPath, parentFolderPath)
    local docTokens = tokenizeFile(filePath)

    if #docTokens == 0 then return false end --nothing to document

    local docName = fs.getName(filePath)
    local name = getCleanFileName(docName)

    local file = io.open(fs.combine(parentFolderPath,name..".md"),"w")

    if not file then
        warn("cannot generate docs for "..docName.." file handle won't open")
        return;
    end

    file:write("# "..name,"\n")

    if backPath then file:write("back to ["..fs.getName(backPath)..".md]("..backPath..".md)\n") end
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
    if backPath then file:write("---\nback to ["..fs.getName(backPath)..".md]("..backPath..".md)") end
    file:close()

    return true
end

local function generateSummary(path, summary, backPath, head)
    local outputFile = fs.combine(outputFolderPath, path..".md")

    local file = io.open(outputFile,"w")

    if not file then
        warn("cannot open file handle for: "..outputFile)
        return
    end

    file:write("# Package: "..head,"\n")

    if #backPath > 0 then file:write("back to ["..backPath..".md]("..backPath..".md)\n") end

    if #summary.folders > 0 then
        file:write("## Packages\n")
        for i=1,#summary.folders do
            file:write("["..fs.getName(summary.folders[i])..".md]("..summary.folders[i]..".md)<br>\n")
        end
    end

    if #summary.files > 0 then
        file:write("\n")
        file:write("## Files\n")
        for i=1,#summary.files do
            file:write("["..getCleanFileName(fs.getName(summary.files[i]))..".md]("..getCleanFileName(summary.files[i])..".md)<br>\n")
        end
    end

    file:close()
end

local function stripFirstDir(path)
    return path:match("^[^/]+/(.+)$") or path
end

local function getLastTwoDirs(path, layer)
    if layer == 0 then return fs.getName(path) end
    return path:match("([^/]+/[^/]+)$") or path
end

local function getCorrectBackPath(path, layer)
    path = fs.getDir(getLastTwoDirs(path, layer))
    if layer == 0 or layer == 1 then return path end
    return "../"..path
end

local function recursiveGenerating(path, layer, outputPath)
    local hasFiles = false

    local summary = {
        files = {},
        folders = {}
    }
    local summaryPath = stripFirstDir(path)

    local fileList = fs.list(path)
    local objPath, pathItem
    for i=1,#fileList do
        objPath = fs.combine(path,fileList[i]);
        pathItem = getLastTwoDirs(objPath, layer)

        if fs.isDir(objPath) then
            if recursiveGenerating(objPath, layer+1, fs.combine(outputPath,fileList[i])) then
                summary.folders[#summary.folders+1] = pathItem
                hasFiles = true
            end
        else
            if generateDocs(objPath, getCorrectBackPath(objPath, layer+1), outputPath) then
                summary.files[#summary.files+1] = pathItem
                hasFiles = true
            end
        end
    end

    if hasFiles then
        generateSummary(summaryPath, summary, getCorrectBackPath(path, layer), outputPath:sub(#docsFolderPath+2))
    end
    return hasFiles
end

fs.delete(outputFolderPath)

if fs.isDir(filePath) then
    recursiveGenerating(filePath, 0, outputFolderPath)
else--file
    generateDocs(filePath, nil, outputFolderPath)
end

--print(textutils.serialise(packageSummaries))

term.setTextColor(colors.gray)
print("generated documentation in '"..outputFolderPath.."/'")
term.setTextColor(colors.white)