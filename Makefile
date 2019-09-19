
sync-local:
	rm -rf i3 && cp -r ~/.config/i3/ .
	rm -rf rofi && cp -r ~/.config/rofi .
	rm -rf polybar && cp -r ~/.config/polybar . 
	rm -rf feh && cp -r ~/.config/feh . 

	
deploy-remote:
	rm -rf ~/.config/i3 && cp -r i3/ ~/.config/
	rm -rf ~/.config/rofi && cp -r rofi/ ~/.config/
	rm -rf ~/.config/polybar && cp -r polybar/ ~/.config/
	rm -rf ~/.config/feh && cp -r feh/ ~/.config/
	
