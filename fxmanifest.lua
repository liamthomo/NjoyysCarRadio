fx_version 'cerulean'
game 'gta5'

author 'OpenAI'
description 'Standalone vehicle radio using YouTube embeds'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'
