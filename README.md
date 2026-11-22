# Dox Gen

this is a simple documentation generator

## Usage

just put documentation above your code like:

example.lua:
```lua
--- this is a description
---     even preserves formatting
---@param param1 string this is a parameter description
---@param param2 table|nil this parameter has two possible types
---@param param3 string|nil|number|table this is also possible
---@return string return1 of course there is a return type
---@return table|number return2 even allows a second return value
---@example print("examples")
---@example print("go here")
---@explanation prints:
---@explanation examples
---@explanation go here
---@warn just testing warnings
---@see example # this links back to this file (currently disabled)
function someMethod(param1, param2, param3)
    --just imagine there is some code here that makes it work
    return aString, tableOrNumber
end
```

and get out:

---

# example

## someMethod(param1, param2, param3)

### Description:
 this is a description<br>
     even preserves formatting<br>

### Parameters:
- **(string)** param1: this is a parameter description<br>
- **(table|nil)** param2: this parameter has two possible types<br>
- **(string|nil|number|table)** param3: this is also possible<br>

### Returns:
- **(string)** return1: of course there is a return type<br>
- **(table|number)** return2: even allows a second return value<br>

### Example:
```lua
print("examples")
print("go here")
```
#### Explanation:
prints:<br>
examples<br>
go here<br>

<p style=color:red;>
    <b>WARNINGS:</b><br>
    just testing warnings<br>
</p>

### See Also:
- **[example](#)**: this links back to this file (currently disabled)<br>

---

## Annotations

### List of them

<li> just '---' is a description and the start of any instruction
<li> '@param' adds an input parameter
<li> '@return' adds an output value
<li> '@example' adds an example line
<li> '@explanation' adds an explanation below the example
<li> '@warn' adds a warning line in red
<li> '@see' adds a link to a file

### @param
put
```lua
---@param <name> <type> <description>
```

let's put it in practice<br>
e.g:

```lua
---@param fileName string this is the file this functions scans
```
or
```lua
---@param tags table|nil a table of tags you would like to add can also be nil
```

### @return
put
```lua
---@return <type> <name> <description>
```

again in practice<br>
e.g:
```lua
---@return number temp this is the temperature calculated
```
and they can also have multiple types and even multiple variables that are returned by stacking:
```lua
---@return number temp this is the temperature calculated
---@return string|nil state this is the state of the materiel at that temp
```

### @example
this is used by writing direct lua

```lua
---@example <lua line>
```
e.g:
```lua
--@example --use methods like this
--@example local value = myFunc(io.read())
```

#### @explanation
this is kind of a sup chapter of example cause it only works with it

```lua
---@explanation <some text explaining the code chunk above>
```
e.g
```lua
---@explanation in the example we get a value from the user and process it in myFunc
```

### @warn
with this you can warn people of certain behaviour of a method
```lua
---@warn <warning>
```
e.g:
```lua
---@warn returns a direct reference of all objects SO DO NOT MUTATE
```
and even
```lua
---@warn first warning
---@warn second warning
```

### @see
with this you can link the dev to another file

```lua
---@see <destination> <label> <description>
```

e.g:
```lua
---@see example example this is a link to example.md
```
or
```lua
---@see ../random random this is a link to random.md which is in the previous directory
```

## Settings

settings are a way to change the behaviour of the Documentation Generator without modifying the source code<br>
(i don't know why i even describe this to you, you should know what settings are)<br>

### flags
#### docLocals
if `true` will document method definitions that are like `local function blaBlaBla()` as well<br>
<br>

type: `boolean`<br>
default: `false`

#### allowAdvancedHtml
if `false` will avoid tags as much as possible in the documentation. Can be useful for less modern markdown renderers. **It however does not change user given documentation**<br>
<br>

type: `boolean`<br>
default: `true`

### misc
#### warnParagraph
this is the styling for the paragraph block for warnings<br>
will only be used if allowAdvancedHtml is `true`<br>
<br>

type: `string`<br>
default: `style=color:red;`

#### typeSep
this is the separator between type names<br>
<br>

type: `string`<br>
default: `|`

#### pathDiv
this is what will be shown in between path names<br>
<br>

type: `string`<br>
default: `/`

#### maxPathLen
this is the maximum number of characters a displayed path (inside of a docs file) can be before the generator abbreviates it<br>
<br>

type: `number`<br>
default: `44`

### logging
#### bufferSize
this is how many lines the logger can have in its buffer before writing them to the log (will become 1 if 0 or negative)<br>
<br>

type: `number`<br>
default: `20`

### formatting
formatting is done a bit like python's formatting system except that `{}` must point back to what input variable they refer to<br>
**if a formatting notation is not provided or empty it will be replaced with an empty string**

#### documents
---

#### inputs
this formatting string is used to define how parameters are listed in the documentation<br>
<br>

type: `string`<br>
default: `- **({types})** {name}: {desc}`<br>
<br>

**provided input values:**<br>
- `{types}`: the already formatted string of all types that can be provided
- `{name}`: the name of the parameter
- `{desc}`: the description of the parameter

#### returns
this formatting string is used to define how returns are listed in the documentation<br>
<br>

type: `string`<br>
default: `- **({types})** {name}: {desc}`<br>
<br>

**provided input values:**<br>
- `{types}`: the already formatted string of all types that can be returned
- `{name}`: the name/label of the return
- `{desc}`: the description of the return

#### seeAlso
this is the formatting string used to define how links to other files are listed in the documentation<br>
<br>

type: `string`<br>
default: `- **[{label}]({file})**: {desc}`<br>
<br>

**provided input values:**
- `{label}`: the label/display name of the link
- `{file}`: the file it links to
- `{desc}`: the description of the link

#### indices
---

#### packages
this is the formatting string used in package indices for the `Sub-Packages` list<br>
<br>

type: `string`<br>
default: `- **[{label}]({file})**`<br>
<br>

**provided input values:**
- `{label}` the label/display name of the link
- `{file}` the file it links to

#### files
this is the formatting string used in package indices for the `Files` list<br>
<br>

type: `string`<br>
default: `- **[{label}]({file})**`<br>
<br>

**provided input values:**
- `{label}` the label/display name of the link
- `{file}` the file it links to

## Injection
This system allows for the addition of custom behaviour without modifying the source code

### How to Create an Injection
We first have to create an entry point for the documentation generator. We do this by making a json in the `injections/json` directory (the injections folder is in the same place as the doxGen file)

#### Json
this is what the json file should look like:
```json
{
    "code": "codeFile.lua",
    "instructions": [
        {
            "id": "someId",
            "capture": "someFuncInCodeFile",
            "format": "- **{someTag}**",
        }
    ]
}
```
let's go over the keys one by one
- `"code"`: this key tells the generator what file (containing the lua code for the capture) it has to use (this path is relative to the `injections/code` directory)
- `"instructions"` this is a list consisting of all instructions injected
    - `"id"`: this key ios the name under which this instruction will be usable so `"test"` would mean you use it via `"@test"`
    - `"capture"` this is the name of the function in the provided code file which turns the given raw instruction data into usable data. more on that later (this method has to be public and cannot be local)
    - `"format"`: this is the formatting of the data provided by the capture function (can also be a method but more on that later)
    - `"isLineExpr"`: this is a boolean that if `true` will make it so that the capture method gets a raw string that is the line parsed in instead of tokens (optional & `false` by default)
    - `"index"`: the position of the generated text in the documentation (is 0 at minimum),(currently not very accurate if lots of injections try to have the same index since it utilizes `table.insert`)

example:
```json
{
    "code": "test.lua",
    "instructions": [
        {
            "id": "test",
            "capture": "testCapture",
            "format": "- **{test}** & *{token}*"
        }
    ]
}
```
here all the code is located in `injections/code/test.lua` with the method that captures the incoming data called testCapture and the resulting data being parsed into the formatting method with the template of `- **{test}** & *{token}*`

#### Code
this is the code provided to the json
so this is the general content if `"isLineExpr"` is `false` in the json:
```lua
function captureInstruction(tokens)
    return {someTag=tokens[2]}
end
```
`tokens` is a table containing the words from the instruction line. `tokens[1]` is the instruction keyword (in out example: `@test`), and each subsequent token contains the text between spaces.<br>

the return is a table where `someTag` is assigned data
this means that if i now have `{someTag}` in the format section of the json it is replaced with the corresponding data. so each key in the table is a tag usable in the formatting

**Note:** This does not have to return a table when using a custom serializer, since the serializer receives the captured data directly.
<br>
<br>
<br>

if `"isLineExpr"` is `true` then this could be the content:
```lua
function captureInstruction(line)
    return {someTag=string.sub(line, 1, math.floor(#line/2))}
end
```
here `line` is the direct line taken from the lua file that is currently being scanned

example (this corresponds to the example json above):
```lua
function testCapture(tokens)
    return {test=tokens[2],token=tokens[1]}
end
```
here i take the tokens delivered by the usage of `@test` and turn them into usable data so if someone for example did
`---@test word` it would return `{test="word",token="@test"}` which after formatting turns into `- **word** & *@test*`

### Custom Serializers
this is a bit more advanced & dangerous since you get direct references

so lets first look at the changes to the json file:
```json
{
    "code": "codeFile.lua",
    "instructions": [
        {
            "id": "someId",
            "capture": "someFuncInCodeFile",
            "format": "someOtherFuncInCodeFile"
        }
    ]
}
```
here `format` also references a method in `injections/code/codeFile.lua` named: `someOtherFuncInCodeFile`

so lets give it what it demands (this is in direct reference to the json provided above):
```lua
function someOtherFuncInCodeFile(file, methodTbl)
    file:write("### Head of this section")
    for i=1,#methodTbl.someId do
        file:write(methodTbl.someId[1].test,"<br>\n")
    end
end
```
`file` here is the **direct file handle** so **closing it will cause issues**<br>
`methodTbl` is a table consisting of all data gathered for the method that is currently being documented (**clearing it will destroy the entire documentation chain** so **DO NOT CHANGE ANY DATA IN methodTbl**). Here we get the table of data that corresponding to our id (`someId`) as defined in the json file above and iterate over all the entries (each entry is a return of the capture method) since our example capture method produces a table like `{test="word",token="@test"}` we get the value of key `test` and write it in the file<br>
<br>

doxGen's string formatting method is added into the globals for custom serializers, you can find it under `formatString(format, valueTbl)`

- `format` is the usual format strings you have seen before (e.g:`- **{test}** & *{token}*`)

- `valueTbl` is a table where each formatting tag's e.g: `{test="word",token="@test"}` inserted into `- **{test}** & *{token}*` => `- **word** & *@test*`

## For further Questions
Just talk to me in my [Discord Server](https://discord.gg/XxRtg5dAzd) if you have any questions, or open a [GitHub issue](https://github.com/Redtech0inc/doxGen/issues) if something is clearly broken.

## Important

local functions will not be documented as they are lua's private methods <br>
also definitions via don't work
```lua
variable = function() end
```
what does work is
```lua
local table = {}

function table.method()
end
```