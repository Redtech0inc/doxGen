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

local function resetMethodTbl()
    local methodTbl = {
        def="",
        desc = {},
        inputs = {},
        returns = {},
        exampleLines = {},
        exampleDesc = {}
    }
    return methodTbl
end

local instructions = {}
instructions["@param"] = captureParameter
instructions["@return"] = captureReturn
instructions["@explanation"] = captureExplanation

local function tokenizeFile(filePath)
    local docTokens = {}
    local methodTbl = resetMethodTbl();

    for line in io.lines(filePath) do

        local tokens = parseTokens(line)

        if instructions[tokens[1]] then
            instructions[tokens[1]](tokens, methodTbl)
        elseif #tokens > 0 then --must be a description
            if tokens[1] == "@example" then
                methodTbl.exampleLines[#methodTbl.exampleLines+1] = line:sub(13) --code has to preserve original
            else
                methodTbl.desc[#methodTbl.desc+1] = line:sub(4) --use this to preserve written form
            end
        else
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

    return docTokens
end

local function generateDocs(filePath, backPath, parentFolderPath)
    local docTokens = tokenizeFile(filePath)

    local docName = fs.getName(filePath)
    local name = getCleanFileName(docName)

    local file = io.open(fs.combine(parentFolderPath,name..".md"),"w")

    if not file then
        warn("cannot generate docs for "..docName.." file handle won't open")
        return;
    end

    file:write("# "..name,"\n")

    if backPath then file:write("[back]("..backPath..")\n") end
    file:write("\n")

    local method
    for i=1,#docTokens do
        method = docTokens[i]

        if #method.inputs > 0 or #method.returns > 0 or #method.desc > 0 then
            file:write("## "..method.def,"\n\n")

            if #method.desc > 0 then
                file:write("### Description:\n")
                for j=1,#method.desc do
                    file:write(method.desc[j],"<br>\n")
                end
                file:write("\n")
            end


            if #method.inputs > 0 then
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
                file:write("\n")
            end

            if #method.returns > 0 then
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
                file:write("\n")
            end

            if #method.exampleLines > 0 then
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

                file:write("\n")
            end

            if i ~= #docTokens then file:write("\n") end
        end
    end

    file:close()
end

local function recursiveGenerating(path, parentFile, outputPath)
    local fileList = fs.list(path)
    for i=1,#fileList do
        if fs.isDir(fs.combine(path,fileList[i])) then
            recursiveGenerating(fs.combine(path ,fileList[i]), nil, fs.combine(outputPath,fileList[i]))
        else
            generateDocs(fs.combine(path ,fileList[i]), parentFile, outputPath)
        end
    end
end

fs.delete(outputFolderPath)

if fs.isDir(filePath) then
    recursiveGenerating(filePath, nil, outputFolderPath)
else--file
    generateDocs(filePath, nil, outputFolderPath)
end

term.setTextColor(colors.gray)
print("generated documentation in '"..outputFolderPath.."'")
term.setTextColor(colors.white)