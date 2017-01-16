#
# Copyright 2016-2017 Blockie AB
#
# This file is part of Space.
#
# Space is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation version 3 of the License.
#
# Space is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Space.  If not, see <http://www.gnu.org/licenses/>.
#

#
# spacedoc - Code documentation exporter for SpaceGal shell
#

_GENERATE_DOC()
{
    SPACE_DEP="_to_lower"
    SPACE_ENV="GENERATE_TOC GENERATE_VARIABLES"

    if [ "$#" -eq 0 ]; then
        PRINT "Expecting documentation name as parameter" "error"
        return 1
    fi

    if [ "$GENERATE_TOC" -eq 0 ]; then
        PRINT "Generating markdown documentation without TOC..."
    else
        PRINT "Generating markdown documentation with TOC..."
    fi

    local _doc_program_name=$1
    shift

    # Output file
    local _doc_save_path="./"
    local _doc_save_suffix="_doc.md"
    local _doc_save_name="${_doc_program_name}${_doc_save_suffix}"

    # Temporary file for TOC variables
    local _doc_tmp_toc_vars_suffix="_doc_toc_vars"
    local _doc_tmp_toc_vars_name="${_doc_program_name}$_doc_tmp_toc_vars_suffix"

    # Temporary file for TOC functions
    local _doc_tmp_toc_funs_suffix="_doc_toc_funs"
    local _doc_tmp_toc_funs_name="${_doc_program_name}$_doc_tmp_toc_funs_suffix"

    # Temporary file for funs
    local _doc_tmp_funs_suffix="_doc_funs"
    local _doc_tmp_funs_name="${_doc_program_name}$_doc_tmp_funs_suffix"

    # Temporary file for vars
    local _doc_tmp_vars_suffix="_doc_vars"
    local _doc_tmp_vars_name="${_doc_program_name}$_doc_tmp_vars_suffix"

    # Stores TOC counters for indexing
    local _toc_var_desc_counter=0
    local _toc_var_value_counter=0
    local _toc_fun_parameters_counter=0
    local _toc_fun_expects_counter=0
    local _toc_fun_returns_counter=0
    local _toc_fun_example_counter=0

    # Stores comments
    local _comments=''

    # Store variable names
    local _vars_lookup=''

    # Create main documentation file
    # Date/timestamp
    # EXTERNAL: date
    if [ "$GENERATE_VARIABLES" -ne 0 ]; then
        local _date_time_now=
        _date_time_now=$(date +"%Y-%m-%d %H:%M:%S (%Z)")
        printf "Documentation for \"%s\"\nAutomatically generated by spacedoc on %s\n\n\n" "${_doc_program_name}" "${_date_time_now}" > "${_doc_save_path}${_doc_save_name}"
    fi

    if [ "$GENERATE_TOC" -ne 0 ]; then
        # Create TOC vars file
        printf "## [Variables](#variables)\n" > "${_doc_save_path}${_doc_tmp_toc_vars_name}"

        # Create TOC funs file
        printf "## [Functions](#functions)\n" > "${_doc_save_path}${_doc_tmp_toc_funs_name}"
    fi

    # Create Variables file
    printf "# Variables \n\n" > "${_doc_save_path}${_doc_tmp_vars_name}"

    # Create Functions file
    printf "# Functions \n\n" >> "${_doc_save_path}${_doc_tmp_funs_name}"

    # Iterate over input file
    while read -r line; do
        # Found comment. Append it!
        if [[ "$line" == "#"* ]]; then
            _comments="$_comments$line
"
        else
            # Check if got any comments stored
            if [ -n "$line" ] && [ -n "$_comments" ]; then

                # Try to match a function first 
                # else try to match a global variable
                if [[ "$line" =~ ([_a-z,A-Z]+)([[:blank:]]*)\(\)(.*) ]]; then
                    local _curr_fun_name="${line//_/\\_}"
                    printf "## %s  \n" "$_curr_fun_name" >> "${_doc_save_path}${_doc_tmp_funs_name}"
                    if [ "$GENERATE_TOC" -ne 0 ]; then
                        local _curr_fun_name_no_parens="${_curr_fun_name/()/}"
                        _curr_fun_name_no_parens=$(_to_lower "${_curr_fun_name_no_parens//\\/}")
                        printf "  - [%s](#%s)\n" "$_curr_fun_name" "$_curr_fun_name_no_parens" >> "${_doc_save_path}${_doc_tmp_toc_funs_name}"
                    fi

                    local _trimmed_comments=${_comments//#}
                    _trimmed_comments=${_trimmed_comments/${BASH_REMATCH[1]}/}
                    _trimmed_comments=${_trimmed_comments//=}
                    _trimmed_comments=${_trimmed_comments//_/\\_}
                    local _is_list=0
                    local _is_example=0
                    while read comment; do
                        if [ "$comment" = "Parameters:" ] || [ "$comment" = "Returns:" ] || [ "$comment" = "Expects:" ]; then
                            printf "### %s  \n" "${comment}" >> "${_doc_save_path}${_doc_tmp_funs_name}"
                            if [ "$GENERATE_TOC" -ne 0 ]; then
                                local _curr_comment=
                                _curr_comment="$comment"
                                if [ "$comment" = "Parameters:" ]; then
                                    if [ "$_toc_fun_parameters_counter" -ne 0 ]; then
                                        _curr_comment="${_curr_comment}-${_toc_fun_parameters_counter}"
                                    fi
                                    _toc_fun_parameters_counter=$((_toc_fun_parameters_counter + 1))
                                elif [ "$comment" = "Returns:" ]; then
                                    if [ "$_toc_fun_returns_counter" -ne 0 ]; then
                                        _curr_comment="${_curr_comment}-${_toc_fun_returns_counter}"
                                    fi
                                    _toc_fun_returns_counter=$((_toc_fun_returns_counter + 1))
                                elif [ "$comment" = "Expects:" ]; then
                                    if [ "$_toc_fun_expects_counter" -ne 0 ]; then
                                        _curr_comment="${_curr_comment}-${_toc_fun_expects_counter}"
                                    fi
                                    _toc_fun_expects_counter=$((_toc_fun_expects_counter + 1))
                                fi
                                _curr_comment=$(_to_lower "$_curr_comment")
                                printf "    - [%s](#%s)\n" "${comment/:/}" "${_curr_comment/:/}" >> "${_doc_save_path}${_doc_tmp_toc_funs_name}"
                            fi
                            _is_list=1
                        elif [ "$comment" = "Example:" ]; then
                            printf "### %s  \n" "${comment}" >> "${_doc_save_path}${_doc_tmp_funs_name}"
                            if [ "$GENERATE_TOC" -ne 0 ]; then
                                local _curr_comment="$comment"
                                if [ "$_toc_fun_example_counter" -ne 0 ]; then
                                    _curr_comment="${_curr_comment}-${_toc_fun_example_counter}"
                                fi
                                _toc_fun_example_counter=$((_toc_fun_example_counter + 1 ))
                                _curr_comment=$(_to_lower "$_curr_comment")
                                printf "    - [%s](#%s)\n" "${comment/:/}" "${_curr_comment/:/}" >> "${_doc_save_path}${_doc_tmp_toc_funs_name}"
                            fi
                            _is_example=1
                        elif [ "$_is_list" -eq 1 ] && [ -n "$comment" ]; then
                            printf "%s  \n" "- ${comment//_/\\_}" >> "${_doc_save_path}${_doc_tmp_funs_name}"
                        elif [ "$_is_example" -eq 1 ] && [ -n "$comment" ]; then
                            printf "%s  \n" "\` ${comment//_/\\_} \`" >> "${_doc_save_path}${_doc_tmp_funs_name}"
                        else
                            printf "%s  \n" "${comment//_/\\_}" >> "${_doc_save_path}${_doc_tmp_funs_name}"
                        fi
                    done <<< "${_trimmed_comments}"
                elif [[ ! "$line" =~ (.*local.*) ]] && [[ "$line" =~ ([_A-Z0-9]+)=(.*) ]]; then
                    local _mark_as_duplicated=0
                    # Check if current match hasn't already been stored
                    # and mark it as duplicated
                    for var in $_vars_lookup; do
                        if [[ $var == "${BASH_REMATCH[1]}" ]]; then
                            _mark_as_duplicated=1
                            break
                        fi
                    done

                    # Only write down variable comment if it hasn't already been done before (check duplicated flag)
                    if [ $_mark_as_duplicated -eq 0 ]; then
                        _vars_lookup="$_vars_lookup ${BASH_REMATCH[1]}"
                        local _curr_var_name=${BASH_REMATCH[1]//_/\\_}
                        printf "## %s \n" "$_curr_var_name" >> "${_doc_save_path}${_doc_tmp_vars_name}"
                        if [ "$GENERATE_TOC" -ne 0 ]; then
                            local _curr_var_name_no_escape="${_curr_var_name//\\/}"
                            local _curr_var_name_lower=
                            _curr_var_name_lower=$(_to_lower "$_curr_var_name_no_escape")
                            printf "  - [%s](#%s)\n" "${_curr_var_name}" "$_curr_var_name_lower" >> "${_doc_save_path}${_doc_tmp_toc_vars_name}"
                        fi

                        local _trimmed_comments=${_comments//#}
                        _trimmed_comments=${_trimmed_comments//_/\\_}
                        _trimmed_comments=$(echo ${_trimmed_comments})
                        local _curr_value=${BASH_REMATCH[2]//_/\\_}
                        printf "### Description  \n %s  \n" "${_trimmed_comments}" >> "${_doc_save_path}${_doc_tmp_vars_name}"
                        printf "### Default value  \n _%s_  \n" "$_curr_value" >> "${_doc_save_path}${_doc_tmp_vars_name}"
                        if [ "$GENERATE_TOC" -ne 0 ]; then
                            local _curr_desc="description"
                            local _curr_value="default-value"
                            if [ "$_toc_var_desc_counter" -ne 0 ]; then
                                _curr_desc="description-${_toc_var_desc_counter}"
                            fi

                            if [ "$_toc_var_value_counter" -ne 0 ]; then
                                _curr_value="default-value-${_toc_var_value_counter}"
                            fi
 
                            _toc_var_desc_counter=$((_toc_var_desc_counter + 1 ))
                            _toc_var_value_counter=$((_toc_var_value_counter + 1 ))
                            printf "    - [Description](#%s)\n" "$_curr_desc" >> "${_doc_save_path}${_doc_tmp_toc_vars_name}"
                            printf "    - [Default value](#%s)\n" "$_curr_value" >> "${_doc_save_path}${_doc_tmp_toc_vars_name}"
                        fi

                    fi
                fi
            fi
            _comments=''
        fi
    done


    # Copy TOC to final doc file
    if [ "$GENERATE_TOC" -ne 0 ]; then
        # EXTERNAL: cat
        # TOC for variables 
        if [ "$GENERATE_VARIABLES" -ne 0 ]; then
            cat "${_doc_save_path}${_doc_tmp_toc_vars_name}" >> "${_doc_save_path}${_doc_save_name}"

            # Separator
            printf "\n" >> "${_doc_save_path}${_doc_save_name}"
        fi

        # TOC for functions
        cat "${_doc_save_path}${_doc_tmp_toc_funs_name}" >> "${_doc_save_path}${_doc_save_name}"

        # Separator
        printf "\n" >> "${_doc_save_path}${_doc_save_name}"
    fi

    # Copy Variables to final doc file
    # EXTERNAL: cat
    if [ "$GENERATE_VARIABLES" -ne 0 ]; then
        cat "${_doc_save_path}${_doc_tmp_vars_name}" >> "${_doc_save_path}${_doc_save_name}"
    fi

    # Copy Functions to final doc file
    # EXTERNAL: cat
    cat "${_doc_save_path}${_doc_tmp_funs_name}" >> "${_doc_save_path}${_doc_save_name}"

    # Cleanup
    if [ -f "${_doc_save_path}${_doc_tmp_toc_vars_name}" ]; then
        # EXTERNAL: rm
        rm "${_doc_save_path}${_doc_tmp_toc_vars_name}"
    fi

    if [ -f "${_doc_save_path}${_doc_tmp_toc_funs_name}" ]; then
        # EXTERNAL: rm
        rm "${_doc_save_path}${_doc_tmp_toc_funs_name}"
    fi

    if [ -f "${_doc_save_path}${_doc_tmp_vars_name}" ]; then
        # EXTERNAL: rm
        rm "${_doc_save_path}${_doc_tmp_vars_name}"
    fi

    if [ -f "${_doc_save_path}${_doc_tmp_funs_name}" ]; then
        # EXTERNAL: rm
        rm "${_doc_save_path}${_doc_tmp_funs_name}"
    fi

    PRINT "Documentation exported to \"${_doc_save_name}\""
}

_EXPORT_MARKDOWN()
{
    SPACE_DEP="PRINT _GENERATE_DOC"

    if [ "$#" -eq 0 ]; then
        PRINT "missing input file to generate documentation from" "error"
        return 1
    fi

    local _doc_program_name=
    _doc_program_name=$(basename "$@")

    # Check if file exists
    if [ ! -f "$@" ]; then
        PRINT "Failed to load $@" "error"
        return 1
    fi

    # EXTERNAL: cat
    cat -- "$@" | _GENERATE_DOC "${_doc_program_name}"

    if [ $? -ne 0 ]; then
        PRINT "Failed to generate documentation" "error"
        return 1
    fi
}


_EXPORT_HTML()
{
    SPACE_DEP="_EXPORT_MARKDOWN PRINT"

    if [ "$#" -eq 0 ]; then
        PRINT "missing input file to generate documentation from" "error"
        return 1
    fi

    if ! command -v Markdown.pl >/dev/null; then
        PRINT "failed to find Markdown.pl. Make sure it is present on current directory or set on PATH" "error"
        return 1
    fi

    # Check if file exists
    if [ ! -f "$@" ]; then
        PRINT "Failed to load $@" "error"
        return 1
    fi

    _EXPORT_MARKDOWN "$@"

    local _program_name=
    _program_name=$(basename "$@")
    PRINT "Generating HTML documentation..."
    Markdown.pl "${_program_name}_doc.md" > "${_program_name}_doc.html"

    if [ $? -ne 0 ]; then
        PRINT "Failed to generate HTML documentation" "error"
        return 1
    else
        PRINT "Documentation exported to \"${_program_name}_doc.html\""
    fi
}

_EXPORT_MODULE()
{
    SPACE_DEP="PRINT _GENERATE_DOC"

    if [ "$#" -eq 0 ]; then
        PRINT "missing input file to generate documentation from" "error"
        return 1
    fi

    local _doc_program_name=
    _doc_program_name=$(basename "$@")

    # Check if file exists
    if [ ! -f "$@" ]; then
        PRINT "Failed to load $@" "error"
        return 1
    fi

    # EXTERNAL: cat
    cat -- "$@" | _GENERATE_DOC "${_doc_program_name}"

    if [ $? -ne 0 ]; then
        PRINT "Failed to generate documentation" "error"
        return 1
    fi

    PRINT "Generating composed output..."
    local _line_counter=0
    local _current_dir_name="$(basename $PWD)"
    local _build_status_badge="[![build status](https://gitlab.com/space-sh/"${_current_dir_name}"/badges/master/build.svg)](https://gitlab.com/space-sh/"${_current_dir_name}"/commits/master)"
    local _spacefile_extension=".${_doc_program_name##*.}"

    printf "# " > "${_doc_program_name}_README" 2>&1

    while read -r _line
    do
        if [[ "$_line" =~ (\+\ )(.*) ]]; then
            printf "\n## " >> "${_doc_program_name}_README" 2>&1
            space -f "${_doc_program_name/${_spacefile_extension}/.yaml}" "/${BASH_REMATCH[2]}/" -h >> "${_doc_program_name}_README" 2>&1
        else
            if [ "$_line_counter" -ne 0 ]; then
                if [ "$_line_counter" -eq 1 ]; then
                    printf "%s | %s\n" "${_line}" "$_build_status_badge" >> "${_doc_program_name}_README"
                    _line_counter=2
                else
                    printf "%s\n" "${_line}" >> "${_doc_program_name}_README"
                fi
            else
                _line_counter=1
            fi
        fi
    done < <(space -f "${_doc_program_name/${_spacefile_extension}/.yaml}" / -h 2>&1)

    printf "\n" >> "${_doc_program_name}_README"
    cat "${_doc_program_name}_doc.md" >> "${_doc_program_name}_README"

    PRINT "Removing intermediate file \"${_doc_program_name}_doc.md\""
    rm "./${_doc_program_name}_doc.md"

    PRINT "Module documentation exported to \"${_doc_program_name}_README\""
}

