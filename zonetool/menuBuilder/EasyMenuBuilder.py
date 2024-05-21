dynamic_properties = ["exp_text", "exp_material", "visible_when", "disabled_when", "exp_rect_x", "exp_rect_y", "exp_rect_h", "exp_rect_w", "exp_forecolor_r", "exp_forecolor_g", "exp_forecolor_b", "exp_forecolor_a"]
item_actions = ["execKeyInt", "onOpen", "onClose", "onEsc", "onFocus", "mouseEnter", "mouseExit", "action"]
item_properties = ["name", "rect", "decoration", "autowrapped", "visible", "ownerdraw", "style", "type", "forecolor", "blurWorld", "border", "bordercolor", "background", "textfont", "textalign", "textscale", "textstyle", "text"] + dynamic_properties + item_actions


def generate_getter(property_name):
    def getter(self):
        return getattr(self, "_" + property_name)
    return getter

def generate_setter(property_name):
    def setter(self, value):
        setattr(self, "_" + property_name, value)
    return setter

class ItemDef:
    def __init__(self, item='itemDef', name=None, rect=(0, 0, 640, 480, 0, 0), decoration=True, visible=True, type=None, style=1, forecolor=(1, 1, 1, 1)):
        for p_name in item_properties:
            self.__add_property(p_name)
            setattr(self, p_name, None)

        if name is not None:
            self.name = f'"{name}"'

        self._item = item
        self.rect = rect
        self.decoration = decoration
        self.visible = visible
        self.style = style
        self.type = type
        self.forecolor = forecolor
        self.onFocus = SimpleItem('onFocus', 1)
        self.mouseEnter = SimpleItem('mouseEnter', 1)
        self.mouseExit = SimpleItem('mouseExit', 1)
        self.action = SimpleItem('action', 1)
        self._itemDefs = []
        self._execKeys = []

    def blink(self, condition):
        self.exp_forecolor_a = f'1 - ( ( {condition} ) * ( ( sin( localclientuimilliseconds( ) / 90 ) ) * 0.65 ) )'

    def dynamicForecolor(self, index):
        self.exp_forecolor_r = f'select(dvarInt("optionType{index}") < 2, 0, 1)'
        self.exp_forecolor_g = f'select(dvarInt("optionType{index}") < 4, 0, select(dvarInt("optionType{index}") < 6, 1, 0.4))'
        self.exp_forecolor_b = f'select(dvarInt("optionType{index}") == 4 || dvarInt("optionType{index}") == 5, 1, 0)'

    def addExecKeyInt(self, value):
        item = SimpleItem(f'execKeyInt {value}', 1)
        self._execKeys.append(item)
        return item

    def add(self, ItemDef):
       self._itemDefs.append(ItemDef)
            
    def __add_property(self, property_name):
        setattr(ItemDef, property_name, property(generate_getter(property_name), generate_setter(property_name)))

    def __str__(self):
        data = []
        
        for name in item_properties:
            value = getattr(self, name)

            if name == 'execKeyInt':
                for i in self._execKeys:
                    [data.append('    ' + j) for j in str(i).split('\n')]
                continue
                
            if value is None:
                continue

            if name in item_actions and not len(value.lines):
                continue

            if name in dynamic_properties:
                value = f'( {value} )'

            if name == 'textstyle' and value == 0:
                continue

            if name == 'decoration' or name == 'autowrapped':
                value = '' if value else None

            if name == 'visible':
                value = 1 if value else None

            if value is None:
                continue

            _type = type(value)
            name = ' '.join(name.split('_'))

            if _type is str or _type is int or _type is float:
                data.append(f'    {name} {value}')
            elif _type is tuple or _type is list:
                data.append(f'    {name} ' + ' '.join(str(i) for i in value))
            elif _type is ItemDef or _type is SimpleItem:
                [data.append('    ' + i) for i in str(value).split('\n')]

        for i in self._itemDefs:
            [data.append('    ' + j) for j in str(i).split('\n')]

        if self._item == "menuDef":
            item = '\nmenuDef\n{\n' + '\n'.join(data) + '\n}'
            return '/* Menu building tool by LastDemon99 */ \n/* https://github.com/LastDemon99/IW5_Mods/tree/main/EasyMenuBuilder */ \n\n{' + '\n'.join(["    " + i for i in item.split('\n')]) + '\n}'
        else:
            return '\n' + self._item + '\n{\n' + '\n'.join(data) + '\n}'

class MenuDef(ItemDef):
    def __init__(self, **kwargs):
        super().__init__(item='menuDef', **kwargs)   
        
        self.decoration = None
        self.visible = None
        self.style = None
        self.onOpen = SimpleItem('onOpen', 1)
        self.onClose = SimpleItem('onClose', 1)
        self.onEsc = SimpleItem('onEsc', 1)

    def addImage(self, **kwargs):
        item = Image(**kwargs)
        self.add(item)
        return item

    def addText(self, **kwargs):
        item = Text(**kwargs)
        self.add(item)
        return item

    def addItem(self, **kwargs):
        item = ItemDef(**kwargs)
        self.add(item)
        return item

    def addDynamicsOption(self, rect, offset, _range, start_index=0):
        return [self.addDynamicOption(rect, i, offset) for i in range(start_index, _range)]

    def addDynamicOption(self, rect, index, offset, start_index=0, decoration=0):
        _rect = list(rect)
        _rect[1] = (offset * (index - start_index)) + _rect[1]
        
        if not decoration:
            option, onClick = self.addOption(_rect, index, dvarString(f'menu_option{index}'), 1, decoration)
        else:
            option = self.addOption(_rect, index, dvarString(f'menu_option{index}'), 1, decoration)

        option.textalign = 10
        option.dynamicForecolor(index)
        option.visible_when = f'dvarstring("menu_option{index}") != "@" && dvarstring("menu_option{index}") != "@-" && dvarInt("menu_options_range") > {index}'

        if not decoration:
            onClick.action = SimpleItem('action', 1)
            onClick.action.If(option.visible_when + f' &&  dvarInt("optionType{index}") != 0 && dvarInt("optionType{index}") != 1', scriptmenuresponse(localVarInt('ui_index')), play('mouse_click'), setLocalVarInt('ui_index', index))
            return option, onClick        
        return option

    def addOptions(self, start, offset, amount, texts, exp=0, decoration=0):
        options = []        
        pos = start[1]
        for i in range(amount):
            _rect = list(start)
            _rect[1] = pos
            options.append(self.addOption(_rect, texts[i], exp, decoration))
            pos += offset
        return options

    def addOption(self, rect, index, text, exp=0, decoration=0):
        option = self.addText(rect=rect, text=text, exp=exp)
        option.blink(f'localVarInt("ui_index") == {index}')
        option.visible_when = f'{text} != ""'

        if not decoration:
            onClick = self.addItem(rect=rect, decoration=0, forecolor=None, style=None, type=1)
            onClick.action.If(option.visible_when, scriptmenuresponse(localVarInt('ui_index')), play('mouse_click'), setLocalVarInt('ui_index', index))
            onClick.mouseEnter.set = setLocalVarInt('ui_index', index), play('mouse_click')
            onClick.mouseExit.set = setLocalVarInt('ui_index', -1), play('mouse_click')
            return option, onClick
        
        return option

class Image(ItemDef):
    def __init__(self, image=None, material=0, ownerdraw=None, **kwargs):
        super().__init__(**kwargs)

        if ownerdraw is None:
            self.style = 3

            if image is None:
                image = 'white'

            if material:
                self.exp_material = image
            else:
                self.background = f'"{image}"'
        else:
            self.ownerdraw = ownerdraw
            self.decoration = None
            self.style = None
            self.background = f'"{image}"'

class Text(ItemDef):
    def __init__(self, textfont=3, textalign=8, textscale=0.375, textstyle=0, text=None, exp=0, ownerdraw=None, **kwargs):
        super().__init__(**kwargs)

        self.textfont = textfont
        self.textalign = textalign
        self.textscale = textscale
        self.textstyle = textstyle

        if ownerdraw is not None:
            self.ownerdraw = ownerdraw
            self.style = None

        if text is None:
            return

        if exp:
            self.exp_text = text
        else:
            self.text = f'"{text}"'

class SimpleItem():
    def __init__(self, header='itemDef', jumpLine=0, lines=None):
        self.header = header
        self.jumpLine = jumpLine
        self.lines = lines if lines else []

    def If(self, condition, *lines):
        self.appendItem(f'if ( {condition} )', *lines)

    def Else_If(self, condition, *lines):
        self.appendItem(f'else if ( {condition} )', *lines)

    def Else(self, *lines):
        self.appendItem(f'else', *lines)

    def appendItem(self, header, *lines):
        if isinstance(lines, str):
            lines = (lines,)
        self.set = SimpleItem(header, 0, lines)

    @property
    def values(self, index):
        return self.lines[index]

    @values.setter
    def set(self, value):
        _type = type(value)

        if _type is str:
            self.lines.append(value)
        elif _type is tuple:
            self.lines += [i for i in value]
        elif _type is SimpleItem:
            self.lines += [i for i in str(value).split('\n')]

    def __str__(self):
        if self.jumpLine:
            return '\n' + self.header + '\n{\n    ' + '\n    '.join(self.lines) + '\n}'
        else:
            return self.header + '\n{\n    ' + '\n    '.join(self.lines) + '\n}'

def exec(val):
    return f'exec "{val}";'

def play(val):
    return f'play "{val}";'

def setDvar(var, val):
    return f'setdvar {var} {val};'

def setLocalVarInt(var, val):
    return f'setLocalVarInt {var} {val};'
    
def setLocalVarString(var, val):
    return f'setLocalVarString {var} {val};'

def localVarInt(var):
    return f'localVarInt( "{var}" )' if ' + ' not in var else f'localVarInt( {var} )'

def localVarString(var):
    return f'localVarString( "{var}" )' if ' + ' not in var else f'localVarString( {var} )'

def dvarInt(var):
    return f'dvarInt( "{var}" )' if ' + ' not in var else f'dvarInt( {var} )'
    
def dvarString(var):
    return f'dvarString( "{var}" )' if ' + ' not in var else f'dvarString( {var} )'
    
def scriptmenuresponse(val):
    return f'scriptmenuresponse {val};'

def setfocus(val):
    return f'setfocus "{val}";'

def close(val):
    return f'close {val};'

def simulateKeyPress(key):
    return f'uiScript simulateKeyPress {key};'