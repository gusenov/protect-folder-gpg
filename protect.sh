#!/usr/bin/env bash

# set -x  # echo on

# Usage:
#  ./protect.sh -u="8FBFE1F9" -e="~/Profiles"
#  ./protect.sh -d="~/Profiles.tar.gpg"

function convert_directory_to_file()
{
	local directory="$1"
	local file="$directory.tar"

	local parent_of_dir="$(dirname $directory)"
	local dir_name="$(basename $directory)"

	# tar does not compress by default, just don't add a compression option.
	tar --create --file="$file" --directory="$parent_of_dir" "$dir_name"
}

function turn_tarball_back_into_directory()
{
	local file="$1"

	local parent_of_dir="$(dirname $file)"

	tar --extract --file="$file" --directory="$parent_of_dir"
}

function encrypt()
{
	local file="$1"
	local user_id_name="$2"

	gpg --encrypt --recipient "$user_id_name" --output "$file.gpg" "$file"
}

function decrypt()
{
	local file="$1"
	local decrypted="${file%.*}"

	gpg --decrypt --output "$decrypted" "$file"
}

function convert_directory_to_file_and_encrypt()
{
	local folder="$1"
	eval folder=$folder

	local user_id_name="$2"

	convert_directory_to_file "$folder"

	encrypt "$folder.tar" "$user_id_name"

	rm -f "$folder.tar"
	rm -rf "$folder"
}

function decrypt_and_turn_tarball_back_into_directory()
{
	local encrypted_file="$1"
	eval encrypted_file=$encrypted_file
	decrypt "$encrypted_file"

	local tarball="${encrypted_file%.*}"
	turn_tarball_back_into_directory "$tarball"

	rm -f "$tarball"
	rm -f "$encrypted_file"
}

function default_convert_directory_to_file_and_encrypt()
{
	local inputdata="$1"

	while IFS=, read -r folderpath user_id
	do
		convert_directory_to_file_and_encrypt "$folderpath" "$user_id"
	done < "$inputdata"
}

function default_decrypt_and_turn_tarball_back_into_directory()
{
	local inputdata="$1"

	while IFS=, read -r folderpath user_id
	do
		decrypt_and_turn_tarball_back_into_directory "$folderpath.tar.gpg"
	done < "$inputdata"
}

for i in "$@"; do
  case $i in

	-u=*|--user=*)
		username="${i#*=}"
	shift # past argument=value
	;;

	-e=*|--encrypt=*)
		convert_directory_to_file_and_encrypt "${i#*=}" "$username"
	shift # past argument=value
	;;

	-d=*|--decrypt=*)
		decrypt_and_turn_tarball_back_into_directory "${i#*=}"
	shift # past argument=value
	;;

	--default_encrypt)
		default_convert_directory_to_file_and_encrypt "my-folders.csv"
	shift # past argument with no value
	;;

	--default_decrypt)
		default_decrypt_and_turn_tarball_back_into_directory "my-folders.csv"
	shift # past argument with no value
	;;

  esac
done



