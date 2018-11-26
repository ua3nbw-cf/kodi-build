#!/bin/bash
# Copyright (C) 2018-present Team ua3nbw (https://ua3nbw.ru)


#
# check for root priveleges
#
if [[ $EUID != 0 ]]; then
	echo "This tool requires root privileges. Try again with \"sudo \" please ..." >&2
	sleep 2
	exit 1
fi




#
# check for internet connection to install dependencies
#
echo -e "GET http://github.com HTTP/1.0\n\n" | nc github.com 80 > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
		read -n 1 -s -p "Warning. Configurator can't work properly without internet connection. \
		Press CTRL C to stop to stop or any key to ignore and continue."
fi




# collect info
main "$@"






#
# Main menu
#
while true
do
	LIST=()

	LIST+=( "all" "Update or clone, Build kodi" )
	LIST+=( "deps" "Update package cache" )
	LIST+=( "checkout" "Clone or update" )
	LIST+=( "build" "Build kodi" )
	LIST+=( "uninstall" "Uninstall" )
	LIST+=( "distclean" "Distclean" )
	LIST+=( "weston" "Run weston" )
	LIST+=( "Help" "Documentation, support, sources" )

	# count number of menu items to adjust window size
	LISTLENGHT="$((11+${#LIST[@]}/2))"
	BOXLENGHT=${#LIST[@]}
	MENUTITLE="Configure $DISTRO $DISTROID "
	[[ -n "${BOARD_NAME/ /}" ]] && MENUTITLE=$MENUTITLE" based \Z1Armbian\Z0 for the \Z1${BOARD_NAME}\Z0 "

	# main dialog routine
	DIALOG_CANCEL=1
	DIALOG_ESC=255
	TITLELENGHT=${#MENUTITLE}

	[[ "$TITLELENGHT" -lt 60 ]] && TITLELENGHT="60"

	exec 3>&1
	selection=$(dialog --colors --backtitle "$BACKTITLE" --title " build-kodi " --clear \
	--cancel-label "Cancel" --menu "\n$MENUTITLE \n \nSupport: \Z1https://ua3nbw.ru\Z0\n " \
	$LISTLENGHT ${TITLELENGHT} $BOXLENGHT "${LIST[@]}" 2>&1 1>&3)
	exit_status=$?
	exec 3>&-

	[[ $exit_status == $DIALOG_CANCEL || $exit_status == $DIALOG_ESC ]] && clear && exit

	dialog --backtitle "$BACKTITLE" --title "Please wait" --infobox \
	"\nLoading ${selection,,} submodule ... " 5 $((26+${#selection}))

	case $selection in

		"all" )
			./kodi_build.sh all
			exit 0
		;;

		"deps" )
			./kodi_build.sh deps
			exit 0
		;;

		"checkout" )
			./kodi_build.sh checkout
			exit 0
		;;

		"build" )
			./kodi_build.sh build
			exit 0
		;;

		"uninstall" )
			./kodi_build.sh uninstall
		;;

		"distclean" )
			./kodi_build.sh distclean
		;;
		"weston" )
			weston
		;;



		"Help" )
			t="This tool provides a straightforward way of configuring."
			t=$t"\n \nAlthough it can be run at any time, some of the"
			t=$t" options may have difficulties if you alter system settings manually.\n"
			t=$t"\n\Z1Documentation:\Z0     https://docs.armbian.com"
			t=$t"\n\n\Z1Support:\Z0           https://forum.armbian.com\n"
			t=$t"\n\Z1Sources:\Z0           https://github.com/armbian/config"
			show_box "Info" "$t" "18"
		;;
	esac
done	
