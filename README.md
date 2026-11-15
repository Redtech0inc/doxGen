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
---@see example example this links back to this file
function someMethod(param1, param2, param3)
    --just imagine there is some code here that makes it work
    return aString, tableOrNumber
end
```

and get out:

-------------------------------------------

# example

## someMethod(param1, param2, param3)

### Description:
 this is a description<br>
     even preserves formatting<br>

### Parameters:
<b>(string)</b> param1: this is a parameter description<br>
<b>(table|nil)</b> param2: this parameter has two possible types<br>
<b>(string|nil|number|table)</b> param3: this is also possible<br>

### Returns:
<b>(string)</b> of: course there is a return type<br>
<b>(table|number)</b> even: allows a second return value<br>

### Example:
```lua
print("examples")
print("go here")
```
#### Explanation:
prints:<br>
examples<br>
go here<br>

### See Also:
[example](example): this links back to this file

-------------------------------------------

## Annotations

### List of them

<li> just '---' is a description and the start of any instruction
<li> '@param' adds an input parameter
<li> '@return' adds an output value
<li> '@example' adds an example line
<li> '@explanation' adds an explanation below the example
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
---@return string|nil state this is the state of the matirale at that temp
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

## important

local functions will not be documented as they are lua's private methods <br>
also definitions via don't work
```lua
vairable = function() end
```
what does work is
```lua
local table = {}

function table.method()
end
```