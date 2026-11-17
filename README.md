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
---@return string of course there is a return type
---@return table|number even allows a second return value
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
**(string)** param1: this is a parameter description<br>
**(table|nil)** param2: this parameter has two possible types<br>
**(string|nil|number|table)** param3: this is also possible<br>

### Returns:
**(string)** of: course there is a return type<br>
**(table|number)** even: allows a second return value<br>

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
**[example](#)**: this links back to this file (currently disabled)<br>

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
---@return <tape> <name> <description>
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

## important

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