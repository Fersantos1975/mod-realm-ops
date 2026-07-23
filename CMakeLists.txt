set(REALMOPS_MODULE_VERSION "0.3.0-dev1")
set(REALMOPS_RELEASE_CHANNEL "dev1")
set(REALMOPS_CAPABILITIES "BUILD_INFO,INSTANCE_SEARCH,INSTANCE_AUDIT,QUEST_SEARCH,QUEST_INFO,QUEST_GROUP_AUDIT,REPORT_EXPORT")
set(REALMOPS_PROTOCOL_VERSION "1")

function(realmops_git_revision directory output_hash output_dirty)
    execute_process(
        COMMAND git -C "${directory}" rev-parse --short=9 HEAD
        OUTPUT_VARIABLE revision
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE revision_result)
    if(NOT revision_result EQUAL 0 OR revision STREQUAL "")
        set(revision "unknown")
    endif()

    execute_process(
        COMMAND git -C "${directory}" status --porcelain
        OUTPUT_VARIABLE changes
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE status_result)
    if(status_result EQUAL 0 AND NOT changes STREQUAL "")
        set(dirty "yes")
    elseif(status_result EQUAL 0)
        set(dirty "no")
    else()
        set(dirty "unknown")
    endif()

    set(${output_hash} "${revision}" PARENT_SCOPE)
    set(${output_dirty} "${dirty}" PARENT_SCOPE)
endfunction()

realmops_git_revision("${CMAKE_CURRENT_LIST_DIR}" REALMOPS_MODULE_GIT_HASH REALMOPS_MODULE_GIT_DIRTY)
realmops_git_revision("${CMAKE_SOURCE_DIR}" REALMOPS_CORE_GIT_HASH REALMOPS_CORE_GIT_DIRTY)
realmops_git_revision("${CMAKE_SOURCE_DIR}/modules/mod-playerbots" REALMOPS_PLAYERBOTS_GIT_HASH REALMOPS_PLAYERBOTS_GIT_DIRTY)

configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/src/realmops_build_info.h.in"
    "${CMAKE_BINARY_DIR}/modules/mod-realm-ops/realmops_build_info.generated.h"
    @ONLY)

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src")
