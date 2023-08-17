from EasyMenuBuilder import *

optionsMenu = MenuDef(name='custom_options')
optionsMenu.blurWorld = 4.8
optionsMenu.visible_when = '!(localVarInt("ui_hideBack"))'

optionsMenu.onOpen.set = exec('closemenu survival_hud'), setLocalVarInt('ui_index', -1)
optionsMenu.onEsc.set = scriptmenuresponse('"back"')

optionsMenu.addImage(rect=(-64, -36, 301.5, 480, 1, 1), forecolor=(0, 0, 0, 0.4))
optionsMenu.addImage(rect=(237.5, -236, 13, 680, 1, 1), forecolor=(1, 1, 1, 0.75), image='navbar_edge')

navBar = optionsMenu.addImage(rect=(-88, 34.667, 325.333, 17.333, 1, 1), image='navbar_selection_bar')
navBar.exp_rect_y = '20 * localVarInt("ui_index") + 34.667'
navBar.visible_when = 'localVarInt("ui_index") >= 0 && dvarString("menu_option" + localVarInt("ui_index")) != "@" && dvarString("menu_option" + localVarInt("ui_index")) != "@-" && dvarInt("menu_options_range") > localVarInt("ui_index")'

navBarShadow = optionsMenu.addImage(rect=(-88, 52, 325.333, 8.666, 1, 1), image='navbar_selection_bar_shadow')
navBarShadow.exp_rect_y = '20 * localVarInt("ui_index") + 52'
navBarShadow.visible_when = navBar.visible_when

optionsMenu.addText(rect=(-64, 3, 276.667, 24.233, 1, 1), text=dvarString('menu_title'), textfont=9, textalign=10, textscale=0.5, exp=1)
optionsMenu.addImage(rect=(-64, 30, 301.5, 5.333, 1, 1), image='navbar_tick')

for i in range(20):
    optionsMenu.addDynamicOption((-64, 33.334, 276.667, 19.567, 1, 1), i, 20)
    optionsMenu.addImage(rect=(-64, (20 * i) + 30, 301.5, 5.333, 1, 1), image='navbar_tick').visible_when = f'dvarInt("optionType{i}") % 2'

print(optionsMenu)