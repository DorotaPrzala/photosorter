# Author           : Dorota Przała ( dor.prz@wp.pl )
# Created On       : 04.05.2019
# Last Modified By : Dorota Przała ( dor.prz@wp.pl )
# Last Modified On : 15.05.2019
# Version          : 1.1
#
# Description      : This script lets you sort photo files by their dates of being taken, making a tree of folders with 
#				   : appropriate files in each folder.
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

#!/bin/bash

help(){
 zenity --info --title "Opcje" --text "-h	pomoc \n-v	wersja"
}

version(){
 zenity --info --title "Nr wersji" --text "1.1"
}

while getopts hv OPT 
    do
	case $OPT in
	    h) help
	       ;;
	    v) version
	       ;;
	    ?) zenity --info --text "Nieprawidłowa opcja, wpisz -h w celu \n uzyskania pomocy"
	       
	esac	
    done
if [ -z "$OPT" ]; then
	exit 0
fi

DIR="/home/dorota/dorota/fotki2/"
dateFlag="no"
line1=""
wasLine1=0
line2=""

zenity --info --title "Photo Sorter" --text "Witaj, użytkowniku. Zanim zaczniesz zrzuć zdjęcia do jednego folderu."
DIR=$(zenity --file-selection --directory --title "Wybierz folder ze zdjeciami")
while [ -z "$DIR" ]
do
	zenity --error --text "Musisz wybrać jakiś folder"
	DIR=$(zenity --file-selection --directory --title "Wybierz folder ze zdjeciami")
done
exiftool -DateTimeOriginal -S -s $DIR *.* > out.txt
zenity --question --title "Wybór daty" --text "Czy chcesz ograniczyć przedział czasu przy segregacji pliku? Np od 1 marca 2019 do 14 marca 2019?"
		ANS=$?
		if [ $ANS = 0 ]; then 
			dateFlag="yes"
			dateOne=$(zenity --calendar --text "Wybierz początkową datę" --title "Wybór daty" --date-format='%Y-%m-%d')
			dateTwo=$(zenity --calendar --text "Wybierz końcową datę" --title "Wybór daty" --date-format='%Y-%m-%d')
		else
			dateFlag="no"
		fi

while read line
do
	if [ $wasLine1 -eq 0 ]; then # jeżeli nie mamy przypisanej wartości do line1 to jej szkukamy
		line1=$(echo $line | grep $DIR)
		if [ -z "$line1" ]; then
			wasLine1=0
		else
			wasLine1=1
		fi
	else	#tu szukamy linii nr 2 po lini1
		line2=$(echo $line | grep [0-9][0-9]:[0-9][0-9]:[0-9][0-9])
		if [ -z "$line2" ]; then
			echo "ten plik nie posiada datetimeoriginal"
			line1=$(echo $line | grep $DIR)
				if [ -z "$line1" ]; then
					wasLine1=0
				else
					wasLine1=1
				fi
		else
			echo "$line1 $line2" >> final.txt
			wasLine1=0
		fi
	fi

done < out.txt
#rm out.txt

#utworzenie startDate i finishDate zdatnej do porównywania
if [ $dateFlag == "yes" ]; then
	startDate=$(date -d $dateOne +"%Y%m%d")
	finishDate=$(date -d $dateTwo +"%Y%m%d")
	
	if [ $startDate -ge $finishDate ]; then
		temp=$startDate
		startDate=$finishDate
		finishDate=$temp
	fi
fi

fileName=""
day=""
month=""
year=""
directory=""
while read line
do
	fileName=$(echo $line | cut -d " " -f 2 )
	day=$(echo $line | cut -d " " -f 3 | cut -d ":" -f 3)
	month=$(echo $line | cut -d " " -f 3 | cut -d ":" -f 2)
	year=$(echo $line | cut -d " " -f 3 | cut -d ":" -f 1)

	if [ $dateFlag == "yes" ]; then
		fileDate="$year-$month-$day"
		fileDate=$(date -d $fileDate +"%Y%m%d")

		if [ $fileDate -ge $startDate ]  && [ $fileDate -le $finishDate ]; then
			directory="$DIR/$year/$month/$day"
			mkdir -p $directory
			xd=$directory
			directory="$directory/"
			mv $fileName $directory
			fileName=$(echo $fileName | sed "s#.*/##")
			echo "$xd/$fileName" >> load.txt
			mkdir -p temporary
			cp $xd/$fileName temporary/$fileName
		fi
	else
		directory="$DIR/$year/$month/$day/"
		mkdir -p $directory
		xd=$directory
		directory="$directory/"
		mv $fileName $directory
		fileName=$(echo $fileName | sed "s#.*/##")
		echo "$xd$fileName" >>load.txt
		mkdir -p temporary
		cp $xd/$fileName temporary/$fileName
	fi

done < final.txt

zenity --info --title "Komunikat" --text "Sortowanie zakończone"
#rm /tmp/final$$.txt

zenity --question --title "tytuł" --text "Chcesz zapisać posortowane zdjęcia na dropboxie?"
ANS=$?
if [ $ANS = 0 ]; then 
			
	TOKEN=$(zenity --entry --title "Token authorization" --text "Podaj access token do swojej aplikacji na dropboxie" )
	if [ -z "$TOKEN" ]; then
		TOKEN="GUcOf_x11zAAAAAAAAAAGY1MouUph0anI3VqycxVkUFhB6lrE5771j2rZV7242si"
	fi
	# tu przesył zdjec
	#
	while read line
	do
		NAME=$(echo $line | sed "s#.*/##")
		curl -X POST https://content.dropboxapi.com/2/files/upload \
      --header "Authorization: Bearer $TOKEN" \
      --header "Dropbox-API-Arg: {\"path\": \"$line\"}" \
      --header "Content-Type: application/octet-stream" \
      --data-binary @temporary/$NAME

	done < load.txt	
	zenity --info --title "Komunikat" --text "Upload zdjęć zakończony"


else
			:
fi

rm -rf temporary
rm final.txt
rm out.txt
rm load.txt








