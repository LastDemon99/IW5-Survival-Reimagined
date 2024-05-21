from EasyMenuBuilder import *

shopMenu = MenuDef(name='shop_menu')

shopMenu.onOpen.set = exec('closemenu survival_hud'), setLocalVarInt('ui_index', -1)
shopMenu.onClose.set = exec('openmenu survival_hud')
shopMenu.onEsc.set = scriptmenuresponse('back')

shopMenu.addImage(rect=(-1280, -480, 2560, 960, 2, 2), forecolor=(0, 0, 0, 0.8))
shopMenu.addImage(rect=(-175, -170, 350, 20, 2, 2), forecolor=(0.1569, 0.1725, 0.1608, 1))
shopMenu.addImage(rect=(-175, -150, 350, 65, 2, 2), forecolor=(0.3098, 0.349, 0.2745, 1))
shopMenu.addImage(rect=(-175, -150, 350, 3, 2, 2), image='black')
shopMenu.addText(rect=(-170, -170, 350, 20, 2, 2), textfont=9, textscale=0.4, text=dvarString('menu_title'), exp=1)

itemImage = shopMenu.addImage(rect=(60, -145, 110, 60, 2, 2), material=1)
itemImage.exp_material = 'tablelookupbyrow(dvarString("menu_table"), (localVarInt("ui_index") + dvarInt("menu_options_start")), 4)'
itemImage.visible_when = 'tablelookupbyrow(dvarString("menu_table"), (localVarInt("ui_index") + dvarInt("menu_options_start")), 4) != ""'

itemImage = shopMenu.addImage(rect=(100, -145, 60, 60, 2, 2), material=1)
itemImage.exp_material = 'tablelookupbyrow(dvarString("menu_table"), (localVarInt("ui_index") + dvarInt("menu_options_start")), 5)'
itemImage.visible_when = 'tablelookupbyrow(dvarString("menu_table"), (localVarInt("ui_index") + dvarInt("menu_options_start")), 5) != ""'

desc = shopMenu.addText(rect=(-170, -145, 260, 60, 2, 2), textalign=4, exp=1, text='"@" + ( tablelookupbyrow(dvarString("menu_table"), (localVarInt("ui_index") + dvarInt("menu_options_start")), 6) )')
desc.autowrapped = 1
desc.type = 21

pos = -85
for index in range(10):
    shopMenu.addImage(rect=(-175, pos, 350, 20, 2, 2), forecolor=(0.1569, 0.1725, 0.1608, 1) if index % 2 == 0 else (0.2118, 0.2314, 0.22, 1))
    pos += 20

navBar = shopMenu.addImage(rect=(-175, 0, 350, 20, 2, 2), forecolor=(0.55, 0.55, 0.55, 1), image='gradient_fadein')
navBar.exp_rect_y = '20 * localvarint("ui_index") - 85'
navBar.visible_when = 'localVarInt("ui_index") >= 0 && dvarString("menu_option" + localVarInt("ui_index")) != "@" && dvarString("menu_option" + localVarInt("ui_index")) != "@-" && dvarInt("menu_options_range") > localVarInt("ui_index")'

navBarShadow = shopMenu.addImage(rect=(-175, -85, 350, 2, 2, 2), image='black')
navBarShadow.exp_rect_y = '20 * localvarint("ui_index") - 65'
navBarShadow.visible_when = 'localVarInt("ui_index") >= 0 && dvarString("menu_option" + localVarInt("ui_index")) != "@" && dvarString("menu_option" + localVarInt("ui_index")) != "@-" && dvarInt("menu_options_range") > localVarInt("ui_index")'

for i in range(10):
    option, onClick = shopMenu.addDynamicOption((-165, -85, 350, 20, 2, 2), i, 20)
    option.textalign = 4

    offset = i + 10
    price = shopMenu.addDynamicOption((0, -85, 160, 20, 2, 2), i + 10, 20, 10, 1)
    price.exp_text = f'select(dvarInt("optionType{offset}") == 6, "Owned", select(dvarInt("optionType{offset}") == 7, "> Upgrade", "$ " + dvarstring( "menu_option{offset}" )))'
    price.visible_when = f'dvarstring("menu_option{offset}") != "" && dvarInt("menu_options_range") > {i}'
    price.blink(f'localVarInt("ui_index") == {i}')

shopMenu.addImage(rect=(-175, 115, 350, 2, 2, 2), image='black')
shopMenu.addImage(rect=(-175, 117, 350, 22, 2, 2), forecolor=(0.1569, 0.1725, 0.1608, 1))
shopMenu.addImage(rect=(-175, 137, 350, 3, 2, 2), forecolor=(0.3098, 0.349, 0.2745, 1))
shopMenu.addText(rect=(-160, 117, 350, 20, 2, 2), forecolor=(0.55, 0.71, 0, 1), text='"$ " + dvarInt("ui_money")', exp=1)
shopMenu.addImage(rect=(105, 117, 67, 20, 2, 2)).exp_forecolor_a = 'localvarint("onBack") * 0.65'

backEsc = shopMenu.addText(rect=(0, 117, 165, 20, 2, 2), textalign=10, text='Back ^2ESC')
backEsc.exp_forecolor_a = '1 - ( localvarint("onBack") * ( ( sin( localclientuimilliseconds( ) / 90 ) ) * 0.65 ) )'
backEsc.mouseEnter.set = setLocalVarInt('onBack', 1), play('mouse_over')
backEsc.mouseExit.set = setLocalVarInt('onBack', 0), play('mouse_over')

backEscAction = shopMenu.addItem(rect=(105, 117, 67, 20, 2, 2), decoration=0, forecolor=None)
backEscAction.action.set = scriptmenuresponse('back')

print(shopMenu)