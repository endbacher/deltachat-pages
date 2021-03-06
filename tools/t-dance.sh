#!/bin/bash

# this script provides some tool needed to translate the homepage.

# before you can use this script the first time, you have to initialize Transifex in this folder:
# $ tx init --user=api --pass=<your api token>
# you may also need `txt2po`, get it by `sudo apt install translate-toolkit`

# after that, call `./t-dance create-po-sources` to rebuild all non-english markdown files
# from the translations provided by transifex users

# call `./t-dance push` pushes the english markdown files to transifex

# the hidden `.tx` folder was generated by the following command:
# $ tx set --auto-remote https://www.transifex.com/projects/p/delta-chat-pages/

# common information about the Transifex CLI client can be found at:
# https://docs.transifex.com/client/


sfiles=(blog contribute download gdpr help imprint index references verify_downloads)
tlangs=(ca de es fr it nb_NO pl pt ru sq uk)  # do not add `en` to this list


pull_po_translations_from_tx() {
	rm -r translations
	tx pull -a   # -a = fetch all translationss, -s = fetches source
	for sfile in ${sfiles[@]}; do
		for tlang in ${tlangs[@]}; do
			pofile="../${tlang:0:2}/${sfile}.po"
			cp "translations/delta-chat-pages.${sfile}po/${tlang}.po" $pofile
		done
	done
}


push_po_sources_to_tx() {
	tx push -s
}


create_po_sources() {
	for sfile in ${sfiles[@]}; do
		txt2po --progress=none "../en/${sfile}.md" "translations/delta-chat-pages.${sfile}po/en.po"
	done
}


create_markdown_files() {
	echo "Creating markdown files from the translated po-files ..."
	for sfile in ${sfiles[@]}; do
		for tlang in ${tlangs[@]}; do
			pofile="../${tlang:0:2}/${sfile}.po"
			mdfile="../${tlang:0:2}/${sfile}.md"
			po2txt --progress=none --template="../en/${sfile}.md" $pofile $mdfile
			sed -i "s/lang: \S*/lang: ${tlang:0:2}/" $mdfile # correct used layout
			sed -i "0,/^$/ s/^$/\n\n\n<!-- GENERATED FILE -- DO NOT EDIT -->\n\n\n/" $mdfile # add a comment in the first empty line (with `0,/^$/` you select all lines until the re matches)
		done
	done	
}


create_html_files() {
	# if you want to rebuild the html files when markdown is updated,
	# crete the file ./jekyll-build-local.prv.sh with the following content:
	# `cd ..; jekyll build --destination <html-folder>; echo "Options +MultiViews" > <html-folder>/.htaccess; cd tools`  
	if [ -f ./create-html.prv.sh ]; then
		echo "Creating html-files from the markdown files ..."
		./create-html.prv.sh
	fi
}


reset_markdown_files() {
	for tlang in ${tlangs[@]}; do
		git checkout "../${tlang:0:2}/"
	done
}


# normal usage
if [ $1 == "pull" ]; then
	pull_po_translations_from_tx
	create_markdown_files
	create_html_files
elif [ $1 == "push" ]; then
	create_po_sources
	push_po_sources_to_tx
# debug usage
elif [ $1 == "create-po-sources" ]; then
	create_po_sources
elif [ $1 == "create-md" ]; then
	create_markdown_files	
	create_html_files
elif [ $1 == "reset-md" ]; then
	reset_markdown_files
	create_html_files
else
	echo "pull translations: ./t-dance pull"
	echo "push sources:      ./t-dance push"
	echo "debug usage:       ./t-dance {create-po-sources|create-md|reset-md}"
	echo "to push a single language, copy the files to translations/delta-chat-pages.<file>po/<lang>.po and call: tx push -t -l <lang>"
fi

